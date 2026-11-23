import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../classroom/classroom_providers.dart';

final teacherLessonsProvider = FutureProvider<List<Lesson>>((ref) => ref.watch(lessonRepositoryProvider).listLessons());

final studentProgressProvider = FutureProvider.autoDispose.family<ProgressSummary, String>((ref, studentId) async {
  final lessons = await ref.watch(teacherLessonsProvider.future);
  final progress = await ref.watch(lessonRepositoryProvider).fetchProgress(studentId: studentId);
  return ProgressSummary(lessons: lessons, progress: {for (final p in progress) p.lessonId: p});
});

/// Whole-lesson homework given to one student (toggled from the student's page).
final studentAssignmentsProvider = AsyncNotifierProvider.autoDispose
    .family<StudentAssignmentsController, List<Homework>, String>(StudentAssignmentsController.new);

class StudentAssignmentsController extends AsyncNotifier<List<Homework>> {
  StudentAssignmentsController(this.studentId);

  final String studentId;

  @override
  Future<List<Homework>> build() async {
    final hw = await ref.watch(teacherHomeworkProvider.future);
    final targets = await ref.watch(homeworkTargetsProvider.future);
    return hw.where((h) => h.lessonId != null && (targets[h.id]?.contains(studentId) ?? false)).toList();
  }

  /// Assigns [lesson] as homework, or removes it when it is already assigned.
  Future<void> toggle(Lesson lesson) async {
    final repo = ref.read(classroomRepositoryProvider);
    final current = state.value ?? const <Homework>[];
    final existing = current.where((h) => h.lessonId == lesson.id).firstOrNull;
    if (existing != null) {
      await repo.deleteHomework(existing.id);
    } else {
      await repo.createHomework(
        Homework(id: '', teacherId: '', kind: HomeworkKind.lesson, title: lesson.titleDe, lessonId: lesson.id),
        studentIds: [studentId],
      );
    }
    ref.invalidate(homeworkTargetsProvider);
  }
}
