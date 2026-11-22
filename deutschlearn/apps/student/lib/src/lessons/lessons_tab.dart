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

IconData moduleIcon(String name) => switch (name) {
  'abc' => Icons.abc_rounded,
  'hand' => Icons.waving_hand_rounded,
  'home' => Icons.home_rounded,
  'grammar' => Icons.account_tree_rounded,
  'read' => Icons.chrome_reader_mode_rounded,
  'listen' => Icons.headphones_rounded,
  'chat' => Icons.forum_rounded,
  'city' => Icons.location_city_rounded,
  'write' => Icons.edit_note_rounded,
  'work' => Icons.work_rounded,
  'exam' => Icons.workspace_premium_rounded,
  'repeat' => Icons.replay_rounded,
  _ => Icons.menu_book_rounded,
};

/// The curriculum roadmap: levels → modules, unlocked in order.
class LessonsTab extends ConsumerWidget {
  const LessonsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculum = ref.watch(curriculumProvider);
    void retry() => ref
      ..invalidate(modulesProvider)
      ..invalidate(lessonsProvider)
      ..invalidate(myProgressProvider)
      ..invalidate(myAssignmentsProvider);
    return RefreshIndicator(
      onRefresh: () async => retry(),
      child: ListView(
        padding: const EdgeInsets.all(DLSpacing.lg),
        children: [
          const DLBilingualTitle(arabic: 'المنهج الدراسي', german: 'Lernpfad A1 – B1'),
          const SizedBox(height: DLSpacing.lg),
          asyncBody<Curriculum>(curriculum, retry, (c) => CurriculumRoadmap(curriculum: c)),
        ],
      ),
    );
  }
}

class CurriculumRoadmap extends ConsumerWidget {
  const CurriculumRoadmap({super.key, required this.curriculum});

  final Curriculum curriculum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = curriculum;
    final t = Theme.of(context).textTheme;
    if (c.path.isEmpty) {
      return const DLEmptyState(icon: Icons.menu_book_outlined, message: 'لا توجد دروس بعد • Noch keine Lektionen');
    }
    final overall = c.overall;
    final next = c.next;
    final placement = c.placement;
    final loose = c.path.where((l) => !c.modules.any((m) => m.id == l.moduleId)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DLCard(
          key: const Key('roadmap-summary'),
          child: Row(
            children: [
              DLProgressRing(value: overall.total == 0 ? 0 : overall.done / overall.total),
              const SizedBox(width: DLSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مستواك الحالي • Dein Niveau: ${c.level.code}', style: t.titleMedium),
                    Text('${overall.done} / ${overall.total} دروس منجزة • Lektionen geschafft', style: t.bodyMedium),
                    if (next != null) ...[
                      const SizedBox(height: DLSpacing.sm),
                      FilledButton.icon(
                        key: const Key('roadmap-continue'),
                        onPressed: () => context.push(StudentRoutes.lesson(next.id)),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          'تابع: ${next.titleAr.isEmpty ? next.titleDe : next.titleAr}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (placement != null && c.progress[placement.id] == null) ...[
          const SizedBox(height: DLSpacing.md),
          DLCard(
            key: const Key('placement-card'),
            color: DLColors.yellow.withValues(alpha: 0.18),
            onTap: () => context.push(StudentRoutes.lesson(placement.id)),
            child: Row(
              children: [
                const DLIconBadge(icon: Icons.quiz_rounded, color: DLColors.navy),
                const SizedBox(width: DLSpacing.md),
                Expanded(
                  child: Text(
                    'تعرف بعض الألمانية؟ اختبار تحديد المستوى يحدد لك نقطة البداية • Einstufungstest',
                    style: t.titleSmall,
                  ),
                ),
                const Icon(Icons.chevron_left),
              ],
            ),
          ),
        ],
        const SizedBox(height: DLSpacing.lg),
        for (final level in CefrLevel.values.where((l) => c.modules.any((m) => m.level == l))) ...[
          DLSectionHeader(arabic: 'المستوى ${level.code}', german: 'Niveau ${level.code}'),
          const SizedBox(height: DLSpacing.md),
          for (final m in c.modules.where((m) => m.level == level)) ...[
            ModuleCard(module: m, curriculum: c),
            const SizedBox(height: DLSpacing.md),
          ],
          const SizedBox(height: DLSpacing.md),
        ],
        if (loose.isNotEmpty) ...[
          const DLSectionHeader(arabic: 'دروس إضافية', german: 'Weitere Lektionen'),
          const SizedBox(height: DLSpacing.md),
          for (final l in loose) ...[
            LessonCard(lesson: l, progress: c.progress[l.id]),
            const SizedBox(height: DLSpacing.md),
          ],
        ],
      ],
    );
  }
}

class ModuleCard extends StatelessWidget {
  const ModuleCard({super.key, required this.module, required this.curriculum});

  final CurriculumModule module;
  final Curriculum curriculum;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = curriculum.moduleProgress(module);
    final open = curriculum.isModuleUnlocked(module);
    final done = p.total > 0 && p.done == p.total;
    return Opacity(
      opacity: open ? 1 : 0.55,
      child: DLCard(
        key: Key('module-${module.id}'),
        onTap: () => context.push(StudentRoutes.module(module.id)),
        child: Row(
          children: [
            DLIconBadge(
              icon: !open ? Icons.lock_rounded : (done ? Icons.check_rounded : moduleIcon(module.icon)),
              color: !open ? Colors.grey : (done ? DLColors.success : DLColors.teal),
            ),
            const SizedBox(width: DLSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(module.titleAr.isEmpty ? module.titleDe : module.titleAr, style: t.titleMedium),
                  Text(module.titleDe, textDirection: TextDirection.ltr, style: t.bodyMedium),
                  const SizedBox(height: DLSpacing.sm),
                  DLProgressBar(value: p.total == 0 ? 0 : p.done / p.total, height: 6),
                  const SizedBox(height: DLSpacing.xs),
                  Text('${p.done} / ${p.total}', style: t.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_left),
          ],
        ),
      ),
    );
  }
}

class LessonCard extends StatelessWidget {
  const LessonCard({super.key, required this.lesson, this.progress, this.assigned = false, this.locked = false});

  final Lesson lesson;
  final LessonProgress? progress;
  final bool assigned;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = progress;
    final passed = lesson.passedWith(p);
    final isTest = lesson.kind != LessonKind.lesson;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: DLCard(
        key: Key('lesson-${lesson.id}'),
        color: isTest && !locked ? DLColors.yellow.withValues(alpha: 0.15) : null,
        onTap: locked
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('أنهِ الدرس السابق بنسبة 70٪ أولاً • Erst die vorige Lektion bestehen')),
              )
            : () => context.push(StudentRoutes.lesson(lesson.id)),
        child: Row(
          children: [
            DLIconBadge(
              icon: locked
                  ? Icons.lock_rounded
                  : passed
                  ? Icons.check_rounded
                  : isTest
                  ? Icons.workspace_premium_rounded
                  : Icons.menu_book_rounded,
              color: locked ? Colors.grey : (passed ? DLColors.success : (isTest ? DLColors.navy : DLColors.blue)),
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
                        ? (isTest ? 'اختبار • Test' : '${lesson.itemCount} عنصر • ${lesson.itemCount} Elemente')
                        : passed
                        ? 'ناجح • ${p.bestScore}/${p.maxScore}'
                        : 'لم تنجح بعد (${lesson.passPercent}٪ مطلوب) • ${p.bestScore}/${p.maxScore}',
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
      ),
    );
  }
}
