import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../router.dart';
import 'lesson_providers.dart';
import 'lessons_tab.dart';

class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    void retry() => ref
      ..invalidate(lessonsProvider)
      ..invalidate(myProgressProvider);
    return RefreshIndicator(
      onRefresh: () async => retry(),
      child: ListView(
        padding: const EdgeInsets.all(DLSpacing.lg),
        children: [
          const DLBilingualTitle(arabic: 'التقدّم', german: 'Fortschritt'),
          const SizedBox(height: DLSpacing.lg),
          asyncBody<ProgressSummary>(ref.watch(progressSummaryProvider), retry, (s) {
            final next = s.next;
            final levels = CefrLevel.values.where((l) => s.forLevel(l).total > 0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DLCard(
                  child: Row(
                    children: [
                      DLProgressRing(value: s.ratio, size: 88),
                      const SizedBox(width: DLSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.completed} / ${s.total}',
                              key: const Key('progress-count'),
                              style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text('دروس مكتملة • Lektionen geschafft', style: t.bodyMedium),
                            const SizedBox(height: DLSpacing.sm),
                            Text('متوسط النتيجة • Ø Ergebnis: ${(s.averageScore * 100).round()}%', style: t.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DLSpacing.xl),
                for (final level in levels) ...[
                  Text('المستوى ${level.code} • Niveau ${level.code}', style: t.titleMedium),
                  const SizedBox(height: DLSpacing.sm),
                  DLProgressBar(
                    value: s.forLevel(level).total == 0 ? 0 : s.forLevel(level).done / s.forLevel(level).total,
                    showLabel: true,
                  ),
                  const SizedBox(height: DLSpacing.lg),
                ],
                if (next != null) ...[
                  const DLSectionHeader(arabic: 'الدرس التالي', german: 'Nächste Lektion'),
                  const SizedBox(height: DLSpacing.md),
                  NextLessonCard(lesson: next),
                ] else if (s.total > 0)
                  const DLBanner(
                    tone: DLStatusTone.success,
                    message: 'أنهيت كل الدروس المتاحة! • Alle Lektionen geschafft!',
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class NextLessonCard extends StatelessWidget {
  const NextLessonCard({super.key, required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) => DLFeatureTile(
    key: const Key('next-lesson'),
    icon: Icons.play_arrow_rounded,
    color: DLColors.teal,
    title: lesson.titleAr.isEmpty ? lesson.titleDe : '${lesson.titleAr} • ${lesson.titleDe}',
    subtitle: 'ابدأ الآن • Jetzt starten',
    onTap: () => context.push(StudentRoutes.lesson(lesson.id)),
  );
}
