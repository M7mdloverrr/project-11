import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson.dart';
import 'lesson_repository.dart';
import 'supabase_errors.dart';

class SupabaseLessonRepository implements LessonRepository {
  SupabaseLessonRepository(this._client);

  final SupabaseClient _client;

  static const _lessonColumns = 'id, cefr_level, position, title_de, title_ar, description_ar, published';
  static const _itemColumns = 'id, position, kind, german, arabic, example_de, example_ar, options, answer';
  static const _assignmentColumns = 'id, teacher_id, student_id, lesson_id, note, due_on, created_at';
  static const _progressColumns = 'student_id, lesson_id, best_score, max_score, attempts, completed_at';

  @override
  Future<List<Lesson>> listLessons() => guardSupabase(() async {
    final rows = await _client
        .from('lessons')
        .select('$_lessonColumns, item_count:lesson_items(count)')
        .order('cefr_level')
        .order('position');
    return rows.map(Lesson.fromJson).toList();
  });

  @override
  Future<Lesson> fetchLesson(String lessonId) => guardSupabase(() async {
    final row = await _client
        .from('lessons')
        .select('$_lessonColumns, lesson_items($_itemColumns)')
        .eq('id', lessonId)
        .single();
    return Lesson.fromJson(row);
  });

  @override
  Future<List<LessonProgress>> fetchProgress({String? studentId}) => guardSupabase(() async {
    final id = studentId ?? _client.auth.currentUser?.id;
    if (id == null) return const <LessonProgress>[];
    final rows = await _client.from('lesson_progress').select(_progressColumns).eq('student_id', id);
    return rows.map(LessonProgress.fromJson).toList();
  });

  @override
  Future<LessonProgress> completeLesson(String lessonId, {required int score, required int maxScore}) =>
      guardSupabase(() async {
        final row = await _client.rpc<Map<String, dynamic>>(
          'complete_lesson',
          params: {'p_lesson_id': lessonId, 'p_score': score, 'p_max': maxScore},
        );
        return LessonProgress.fromJson(row);
      });

  @override
  Future<Lesson> saveLesson(Lesson l) => guardSupabase(() async {
    final values = {
      'cefr_level': l.level.code,
      'position': l.position,
      'title_de': l.titleDe.trim(),
      'title_ar': l.titleAr.trim(),
      'description_ar': l.descriptionAr.trim(),
      'published': l.published,
    };
    final row = l.id.isEmpty
        ? await _client.from('lessons').insert(values).select(_lessonColumns).single()
        : await _client.from('lessons').update(values).eq('id', l.id).select(_lessonColumns).single();
    return Lesson.fromJson(row);
  });

  @override
  Future<void> deleteLesson(String lessonId) =>
      guardSupabase(() => _client.from('lessons').delete().eq('id', lessonId));

  /// Replaces all items of a lesson (simple and atomic enough for authoring).
  @override
  Future<void> saveItems(String lessonId, List<LessonItem> items) => guardSupabase(() async {
    await _client.from('lesson_items').delete().eq('lesson_id', lessonId);
    if (items.isEmpty) return;
    await _client.from('lesson_items').insert([
      for (final (i, item) in items.indexed) {...item.toJson(), 'lesson_id': lessonId, 'position': i + 1},
    ]);
  });

  @override
  Future<List<LessonAssignment>> fetchAssignments({String? studentId}) => guardSupabase(() async {
    final id = studentId ?? _client.auth.currentUser?.id;
    if (id == null) return const <LessonAssignment>[];
    final rows = await _client
        .from('lesson_assignments')
        .select(_assignmentColumns)
        .eq('student_id', id)
        .order('created_at', ascending: false);
    return rows.map(LessonAssignment.fromJson).toList();
  });

  @override
  Future<LessonAssignment> assignLesson({required String studentId, required String lessonId, String note = ''}) =>
      guardSupabase(() async {
        final row = await _client
            .from('lesson_assignments')
            .insert({
              'teacher_id': _client.auth.currentUser?.id,
              'student_id': studentId,
              'lesson_id': lessonId,
              'note': note.trim(),
            })
            .select(_assignmentColumns)
            .single();
        return LessonAssignment.fromJson(row);
      });

  @override
  Future<void> removeAssignment(String assignmentId) =>
      guardSupabase(() => _client.from('lesson_assignments').delete().eq('id', assignmentId));
}
