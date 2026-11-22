import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teacherLessonsProvider = FutureProvider<List<Lesson>>((ref) => ref.watch(lessonRepositoryProvider).listLessons());

final studentProgressProvider = FutureProvider.autoDispose.family<ProgressSummary, String>((ref, studentId) async {
  final lessons = await ref.watch(teacherLessonsProvider.future);
  final progress = await ref.watch(lessonRepositoryProvider).fetchProgress(studentId: studentId);
  return ProgressSummary(lessons: lessons, progress: {for (final p in progress) p.lessonId: p});
});

final studentAssignmentsProvider = AsyncNotifierProvider.autoDispose
    .family<StudentAssignmentsController, List<LessonAssignment>, String>(StudentAssignmentsController.new);

class StudentAssignmentsController extends AsyncNotifier<List<LessonAssignment>> {
  StudentAssignmentsController(this.studentId);

  final String studentId;

  @override
  Future<List<LessonAssignment>> build() => ref.watch(lessonRepositoryProvider).fetchAssignments(studentId: studentId);

  /// Assigns [lessonId] as homework, or removes it when it is already assigned.
  Future<void> toggle(String lessonId) async {
    final repo = ref.read(lessonRepositoryProvider);
    final current = state.value ?? const <LessonAssignment>[];
    final existing = current.where((a) => a.lessonId == lessonId).firstOrNull;
    if (existing != null) {
      await repo.removeAssignment(existing.id);
      state = AsyncData([...current.where((a) => a.id != existing.id)]);
    } else {
      final a = await repo.assignLesson(studentId: studentId, lessonId: lessonId);
      state = AsyncData([a, ...current]);
    }
  }
}
