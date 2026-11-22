import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lessonsProvider = FutureProvider<List<Lesson>>((ref) => ref.watch(lessonRepositoryProvider).listLessons());

final myProgressProvider = FutureProvider<List<LessonProgress>>(
  (ref) => ref.watch(lessonRepositoryProvider).fetchProgress(),
);

final progressSummaryProvider = FutureProvider<ProgressSummary>((ref) async {
  final lessons = await ref.watch(lessonsProvider.future);
  final progress = await ref.watch(myProgressProvider.future);
  return ProgressSummary(lessons: lessons, progress: {for (final p in progress) p.lessonId: p});
});

final lessonDetailProvider = FutureProvider.autoDispose.family<Lesson, String>(
  (ref, id) => ref.watch(lessonRepositoryProvider).fetchLesson(id),
);

final myAssignmentsProvider = FutureProvider<List<LessonAssignment>>(
  (ref) => ref.watch(lessonRepositoryProvider).fetchAssignments(),
);

typedef Homework = ({Lesson lesson, LessonAssignment assignment, LessonProgress? progress});

/// Assigned lessons, open ones first.
final homeworkProvider = FutureProvider<List<Homework>>((ref) async {
  final summary = await ref.watch(progressSummaryProvider.future);
  final assignments = await ref.watch(myAssignmentsProvider.future);
  final byId = {for (final l in summary.lessons) l.id: l};
  final list = [
    for (final a in assignments)
      if (byId[a.lessonId] case final l?) (lesson: l, assignment: a, progress: summary.progress[l.id]),
  ];
  list.sort((a, b) => (a.progress == null ? 0 : 1).compareTo(b.progress == null ? 0 : 1));
  return list;
});
