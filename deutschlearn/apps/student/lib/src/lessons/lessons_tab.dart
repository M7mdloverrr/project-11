import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../router.dart';
import 'lesson_providers.dart';

/// Shows [value], a spinner, or the error with a retry button (bilingual).
Widget asyncBody<T>(AsyncValue<T> value, VoidCallback retry, Widget Function(T) data) => switch (value) {
  AsyncData(:final value) => data(value),
  AsyncError(:final error) => Padding(
    padding: const EdgeInsets.all(DLSpacing.lg),
    child: DLBanner(
      tone: DLStatusTone.error,
      message: error is AppFailure ? error.message : '$error',
      action: TextButton(onPressed: retry, child: Text(bilingualLabel('إعادة المحاولة', 'Erneut'))),
    ),
  ),
  _ => const Center(
    child: Padding(padding: EdgeInsets.all(DLSpacing.xxl), child: CircularProgressIndicator()),
  ),
};

class LessonsTab extends ConsumerWidget {
  const LessonsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);
    final assigned = {...?ref.watch(myAssignmentsProvider).value?.map((a) => a.lessonId)};
    void retry() => ref
      ..invalidate(lessonsProvider)
      ..invalidate(myProgressProvider)
      ..invalidate(myAssignmentsProvider);
    return RefreshIndicator(
      onRefresh: () async => retry(),
      child: ListView(
        padding: const EdgeInsets.all(DLSpacing.lg),
        children: [
          const DLBilingualTitle(arabic: 'الدروس', german: 'Lektionen'),
          const SizedBox(height: DLSpacing.lg),
          asyncBody<ProgressSummary>(summary, retry, (s) {
            if (s.lessons.isEmpty) {
              return const DLEmptyState(
                icon: Icons.menu_book_outlined,
                message: 'لا توجد دروس بعد • Noch keine Lektionen',
              );
            }
            final levels = CefrLevel.values.where((l) => s.lessons.any((x) => x.level == l));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final level in levels) ...[
                  DLSectionHeader(
                    arabic: 'المستوى ${level.code}',
                    german: 'Niveau ${level.code} • ${s.forLevel(level).done}/${s.forLevel(level).total}',
                  ),
                  const SizedBox(height: DLSpacing.md),
                  for (final l in s.lessons.where((x) => x.level == level)) ...[
                    LessonCard(lesson: l, progress: s.progress[l.id], assigned: assigned.contains(l.id)),
                    const SizedBox(height: DLSpacing.md),
                  ],
                  const SizedBox(height: DLSpacing.md),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.lesson, this.progress, this.assigned = false});

  final Lesson lesson;
  final LessonProgress? progress;
  final bool assigned;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = progress;
    return DLCard(
      key: Key('lesson-${lesson.id}'),
      onTap: () => context.push(StudentRoutes.lesson(lesson.id)),
      child: Row(
        children: [
          DLIconBadge(
            icon: p == null ? Icons.menu_book_rounded : Icons.check_rounded,
            color: p == null ? DLColors.blue : DLColors.success,
          ),
          const SizedBox(width: DLSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.titleAr.isEmpty ? lesson.titleDe : lesson.titleAr, style: t.titleMedium),
                Text(lesson.titleDe, textDirection: TextDirection.ltr, style: t.bodyMedium),
                const SizedBox(height: DLSpacing.xs),
                Text(
                  p == null
                      ? '${lesson.itemCount} عنصر • ${lesson.itemCount} Elemente'
                      : 'مكتمل • ${p.bestScore}/${p.maxScore}',
                  style: t.bodySmall,
                ),
                if (assigned) ...[
                  const SizedBox(height: DLSpacing.xs),
                  const DLStatusChip(label: 'واجب • Hausaufgabe', tone: DLStatusTone.warning),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_left),
        ],
      ),
    );
  }
}
