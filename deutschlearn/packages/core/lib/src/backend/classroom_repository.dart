import 'package:supabase_flutter/supabase_flutter.dart';

import '../failure.dart';
import '../models/homework.dart';
import '../models/live.dart';
import 'supabase_errors.dart';

/// Classes, homework (assign → save → submit → grade) and live lessons.
abstract interface class ClassroomRepository {
  Stream<List<Homework>> watchHomework();
  Stream<List<HomeworkSubmission>> watchSubmissions();
  Future<Map<String, List<String>>> fetchTargets();
  Future<Homework> createHomework(Homework draft, {required List<String> studentIds});
  Future<void> deleteHomework(String homeworkId);
  Future<HomeworkSubmission> saveSubmission(
    String homeworkId, {
    required Map<String, String> answers,
    required bool submit,
    required int autoScore,
    required int maxScore,
  });
  Future<HomeworkSubmission> gradeSubmission(
    String submissionId, {
    required int grade,
    required String feedback,
    Map<String, String> corrections,
    bool returnForRevision,
  });

  Future<List<SchoolClass>> listClasses();
  Future<SchoolClass> saveClass({String? id, required String name, required List<String> memberIds});
  Future<void> deleteClass(String classId);

  Stream<List<LiveSession>> watchLiveSessions();
  Stream<List<LiveResponse>> watchLiveResponses(String sessionId);
  Stream<List<LiveParticipant>> watchLiveParticipants(String sessionId);
  Future<LiveSession> startLive({required String title, String? lessonId, String? classId});
  Future<void> updateLive(String sessionId, Map<String, dynamic> changes);
  Future<void> endLive(String sessionId);
  Future<void> joinLive(String sessionId);
  Future<void> answerLive(String sessionId, {required int itemIndex, required String answer, bool? correct});
  Future<void> markLive(String sessionId, {required String studentId, required int itemIndex, required String mark});
}

class SupabaseClassroomRepository implements ClassroomRepository {
  SupabaseClassroomRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser?.id ?? '';

  @override
  Stream<List<Homework>> watchHomework() => _client
      .from('homework')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) => rows.map(Homework.fromJson).toList().reversed.toList());

  @override
  Stream<List<HomeworkSubmission>> watchSubmissions() => _client
      .from('homework_submissions')
      .stream(primaryKey: ['id'])
      .map((r) => r.map(HomeworkSubmission.fromJson).toList());

  @override
  Future<Map<String, List<String>>> fetchTargets() => guardSupabase(() async {
    final rows = await _client.from('homework_targets').select('homework_id, student_id');
    final out = <String, List<String>>{};
    for (final r in rows) {
      (out[r['homework_id'] as String] ??= []).add(r['student_id'] as String);
    }
    return out;
  });

  @override
  Future<Homework> createHomework(Homework draft, {required List<String> studentIds}) => guardSupabase(() async {
    if (studentIds.isEmpty) {
      throw const AppFailure(FailureKind.unknown, 'اختر طالباً واحداً على الأقل • Mindestens einen Schüler wählen');
    }
    final row = await _client.from('homework').insert({...draft.toInsert(), 'teacher_id': _uid}).select().single();
    final hw = Homework.fromJson(row);
    await _client.from('homework_targets').insert([
      for (final s in studentIds.toSet()) {'homework_id': hw.id, 'student_id': s},
    ]);
    return hw;
  });

  @override
  Future<void> deleteHomework(String homeworkId) =>
      guardSupabase(() => _client.from('homework').delete().eq('id', homeworkId));

  @override
  Future<HomeworkSubmission> saveSubmission(
    String homeworkId, {
    required Map<String, String> answers,
    required bool submit,
    required int autoScore,
    required int maxScore,
  }) => guardSupabase(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'save_homework',
      params: {
        'p_homework_id': homeworkId,
        'p_answers': answers,
        'p_submit': submit,
        'p_auto_score': autoScore,
        'p_max_score': maxScore,
      },
    );
    return HomeworkSubmission.fromJson(row);
  });

  @override
  Future<HomeworkSubmission> gradeSubmission(
    String submissionId, {
    required int grade,
    required String feedback,
    Map<String, String> corrections = const {},
    bool returnForRevision = false,
  }) => guardSupabase(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'grade_homework',
      params: {
        'p_submission_id': submissionId,
        'p_grade': grade.clamp(0, 100),
        'p_feedback': feedback.trim(),
        'p_corrections': corrections,
        'p_return': returnForRevision,
      },
    );
    return HomeworkSubmission.fromJson(row);
  });

  @override
  Future<List<SchoolClass>> listClasses() => guardSupabase(() async {
    final rows = await _client.from('classes').select('id, teacher_id, name, class_members(student_id)').order('name');
    return rows.map(SchoolClass.fromJson).toList();
  });

  @override
  Future<SchoolClass> saveClass({String? id, required String name, required List<String> memberIds}) =>
      guardSupabase(() async {
        final row = id == null
            ? await _client.from('classes').insert({'teacher_id': _uid, 'name': name.trim()}).select('id').single()
            : await _client.from('classes').update({'name': name.trim()}).eq('id', id).select('id').single();
        final classId = row['id'] as String;
        await _client.from('class_members').delete().eq('class_id', classId);
        if (memberIds.isNotEmpty) {
          await _client.from('class_members').insert([
            for (final m in memberIds.toSet()) {'class_id': classId, 'student_id': m},
          ]);
        }
        return SchoolClass(id: classId, teacherId: _uid, name: name.trim(), memberIds: memberIds);
      });

  @override
  Future<void> deleteClass(String classId) => guardSupabase(() => _client.from('classes').delete().eq('id', classId));

  @override
  Stream<List<LiveSession>> watchLiveSessions() => _client
      .from('live_sessions')
      .stream(primaryKey: ['id'])
      .order('started_at')
      .map((rows) => rows.map(LiveSession.fromJson).toList().reversed.toList());

  @override
  Stream<List<LiveResponse>> watchLiveResponses(String sessionId) => _client
      .from('live_responses')
      .stream(primaryKey: ['session_id', 'student_id', 'item_index'])
      .eq('session_id', sessionId)
      .map((r) => r.map(LiveResponse.fromJson).toList());

  @override
  Stream<List<LiveParticipant>> watchLiveParticipants(String sessionId) => _client
      .from('live_participants')
      .stream(primaryKey: ['session_id', 'student_id'])
      .eq('session_id', sessionId)
      .map((r) => r.map(LiveParticipant.fromJson).toList());

  @override
  Future<LiveSession> startLive({required String title, String? lessonId, String? classId}) => guardSupabase(() async {
    await _client
        .from('live_sessions')
        .update({'status': 'ended', 'ended_at': DateTime.now().toUtc().toIso8601String()})
        .eq('teacher_id', _uid)
        .eq('status', 'live');
    final row = await _client
        .from('live_sessions')
        .insert({'teacher_id': _uid, 'title': title.trim(), 'lesson_id': lessonId, 'class_id': classId})
        .select()
        .single();
    return LiveSession.fromJson(row);
  });

  @override
  Future<void> updateLive(String sessionId, Map<String, dynamic> changes) =>
      guardSupabase(() => _client.from('live_sessions').update(changes).eq('id', sessionId));

  @override
  Future<void> endLive(String sessionId) =>
      updateLive(sessionId, {'status': 'ended', 'ended_at': DateTime.now().toUtc().toIso8601String()});

  @override
  Future<void> joinLive(String sessionId) =>
      guardSupabase(() => _client.rpc<void>('live_join', params: {'p_session_id': sessionId}));

  @override
  Future<void> answerLive(String sessionId, {required int itemIndex, required String answer, bool? correct}) =>
      guardSupabase(
        () => _client.rpc<void>(
          'live_answer',
          params: {'p_session_id': sessionId, 'p_item_index': itemIndex, 'p_answer': answer, 'p_correct': correct},
        ),
      );

  @override
  Future<void> markLive(String sessionId, {required String studentId, required int itemIndex, required String mark}) =>
      guardSupabase(
        () => _client
            .from('live_responses')
            .update({'teacher_mark': mark})
            .eq('session_id', sessionId)
            .eq('student_id', studentId)
            .eq('item_index', itemIndex),
      );
}
