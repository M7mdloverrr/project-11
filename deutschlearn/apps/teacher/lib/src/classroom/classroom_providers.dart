import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/teacher_controllers.dart';

final teacherHomeworkProvider = StreamProvider<List<Homework>>(
  (ref) => ref.watch(classroomRepositoryProvider).watchHomework(),
);

final teacherSubmissionsProvider = StreamProvider<List<HomeworkSubmission>>(
  (ref) => ref.watch(classroomRepositoryProvider).watchSubmissions(),
);

/// Students targeted by each homework; refetched whenever the homework list changes.
final homeworkTargetsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  await ref.watch(teacherHomeworkProvider.future);
  return ref.read(classroomRepositoryProvider).fetchTargets();
});

final classesProvider = FutureProvider<List<SchoolClass>>(
  (ref) => ref.watch(classroomRepositoryProvider).listClasses(),
);

final teacherModulesProvider = FutureProvider<List<CurriculumModule>>(
  (ref) => ref.watch(lessonRepositoryProvider).listModules(),
);

final teacherAllLessonsProvider = FutureProvider<List<Lesson>>(
  (ref) => ref.watch(lessonRepositoryProvider).listLessons(),
);

final teacherLessonDetailProvider = FutureProvider.autoDispose.family<Lesson, String>(
  (ref, id) => ref.watch(lessonRepositoryProvider).fetchLesson(id),
);

final teacherLiveSessionsProvider = StreamProvider<List<LiveSession>>(
  (ref) => ref.watch(classroomRepositoryProvider).watchLiveSessions(),
);

final activeTeacherLiveProvider = Provider<LiveSession?>(
  (ref) => ref.watch(teacherLiveSessionsProvider).value?.where((s) => s.live).firstOrNull,
);

final teacherLiveResponsesProvider = StreamProvider.autoDispose.family<List<LiveResponse>, String>(
  (ref, id) => ref.watch(classroomRepositoryProvider).watchLiveResponses(id),
);

final teacherLiveParticipantsProvider = StreamProvider.autoDispose.family<List<LiveParticipant>, String>(
  (ref, id) => ref.watch(classroomRepositoryProvider).watchLiveParticipants(id),
);

/// Linked student id → display name.
final studentNamesProvider = Provider<Map<String, String>>(
  (ref) => {
    for (final l in ref.watch(linkedStudentsProvider).value ?? const <TeacherStudentLink>[])
      l.studentId: l.student?.displayName ?? '—',
  },
);

/// Submitted work waiting for the teacher's review.
final toReviewCountProvider = Provider<int>(
  (ref) =>
      ref.watch(teacherSubmissionsProvider).value?.where((s) => s.status == SubmissionStatus.submitted).length ?? 0,
);

typedef TargetStatus = ({String studentId, HomeworkSubmission? submission});

extension TargetStatusX on TargetStatus {
  SubmissionStatus get status => submission?.status ?? SubmissionStatus.notStarted;
}

/// Per student status of one homework.
final homeworkStatusProvider = Provider.autoDispose.family<List<TargetStatus>, String>((ref, homeworkId) {
  final targets = ref.watch(homeworkTargetsProvider).value?[homeworkId] ?? const <String>[];
  final subs = ref.watch(teacherSubmissionsProvider).value ?? const <HomeworkSubmission>[];
  return [
    for (final t in targets)
      (studentId: t, submission: subs.where((s) => s.homeworkId == homeworkId && s.studentId == t).firstOrNull),
  ];
});

String lessonLabel(Lesson l) => '${l.level.code} · ${l.titleDe}${l.titleAr.isEmpty ? '' : ' — ${l.titleAr}'}';
