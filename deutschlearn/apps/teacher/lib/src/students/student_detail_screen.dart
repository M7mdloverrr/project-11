import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../router.dart';

import '../classroom/classroom_providers.dart';
import 'student_providers.dart';

/// A linked student's lesson progress; the teacher assigns lessons as homework here.
class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId, this.student});

  final String studentId;
  final LinkParty? student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final summary = ref.watch(studentProgressProvider(studentId));
    final assignments = ref.watch(studentAssignmentsProvider(studentId));
    void retry() => ref
      ..invalidate(teacherLessonsProvider)
      ..invalidate(homeworkTargetsProvider)
      ..invalidate(studentProgressProvider(studentId))
      ..invalidate(studentAssignmentsProvider(studentId));

    Future<void> toggle(Lesson l) async {
      try {
        await ref.read(studentAssignmentsProvider(studentId).notifier).toggle(l);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(backgroundColor: DLColors.error, content: Text(e is AppFailure ? e.message : '$e')));
        }
      }
    }

    final error = summary.error ?? assignments.error;
    return Scaffold(
      appBar: AppBar(
        title: Text(student?.displayName ?? 'الطالب • Schüler'),
        actions: [
          IconButton(
            key: const Key('open-chat'),
            tooltip: 'محادثة • Chat',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push(TeacherRoutes.chat(studentId), extra: student),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => retry(),
          child: ListView(
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [
              if (error != null)
                DLBanner(
                  tone: DLStatusTone.error,
                  message: error is AppFailure ? error.message : '$error',
                  action: TextButton(onPressed: retry, child: const Text('إعادة • Erneut')),
                )
              else if (summary.value case final s? when assignments.hasValue) ...[
                DLCard(
                  child: Row(
                    children: [
                      DLProgressRing(value: s.ratio, size: 80),
                      const SizedBox(width: DLSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.completed} / ${s.total}',
                              key: const Key('student-progress-count'),
                              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text('دروس مكتملة • Lektionen geschafft', style: t.bodyMedium),
                            Text('متوسط النتيجة • Ø Ergebnis: ${(s.averageScore * 100).round()}%', style: t.bodySmall),
                            Text('واجبات • Hausaufgaben: ${assignments.value!.length}', style: t.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DLSpacing.xl),
                const DLSectionHeader(arabic: 'الدروس والواجبات', german: 'Lektionen & Hausaufgaben'),
                const SizedBox(height: DLSpacing.md),
                for (final l in s.lessons) ...[
                  _LessonRow(
                    lesson: l,
                    progress: s.progress[l.id],
                    assigned: assignments.value!.any((a) => a.lessonId == l.id),
                    onToggle: () => toggle(l),
                  ),
                  const SizedBox(height: DLSpacing.sm),
                ],
              ] else
                const Center(
                  child: Padding(padding: EdgeInsets.all(DLSpacing.xxl), child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.progress, required this.assigned, required this.onToggle});

  final Lesson lesson;
  final LessonProgress? progress;
  final bool assigned;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    return DLCard(
      key: Key('row-${lesson.id}'),
      padding: const EdgeInsets.symmetric(horizontal: DLSpacing.lg, vertical: DLSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${lesson.level.code} · ${lesson.titleDe}',
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (lesson.titleAr.isNotEmpty) Text(lesson.titleAr),
                const SizedBox(height: DLSpacing.xs),
                Wrap(
                  spacing: DLSpacing.sm,
                  runSpacing: DLSpacing.xs,
                  children: [
                    DLStatusChip(
                      label: p == null ? 'لم يبدأ • Offen' : '${p.bestScore}/${p.maxScore} • ${p.attempts}×',
                      tone: p == null ? DLStatusTone.neutral : DLStatusTone.success,
                    ),
                    if (assigned) const DLStatusChip(label: 'واجب • Hausaufgabe', tone: DLStatusTone.warning),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('assign-${lesson.id}'),
            tooltip: assigned ? 'إلغاء الواجب • Hausaufgabe entfernen' : 'تعيين كواجب • Als Hausaufgabe',
            icon: Icon(
              assigned ? Icons.assignment_turned_in : Icons.assignment_add,
              color: assigned ? DLColors.success : DLColors.blue,
            ),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}
