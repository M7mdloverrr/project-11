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
