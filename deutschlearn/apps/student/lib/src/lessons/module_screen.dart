import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'lesson_providers.dart';
import 'lessons_tab.dart';

class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curriculum = ref.watch(curriculumProvider);
    final assigned = {...?ref.watch(myAssignmentsProvider).value?.map((a) => a.lessonId)};
    final module = curriculum.value?.modules.where((m) => m.id == moduleId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(module?.titleAr ?? 'الوحدة • Modul')),
      body: SafeArea(
        child: asyncBody<Curriculum>(curriculum, () => ref.invalidate(curriculumProvider), (c) {
          final m = module;
          if (m == null) {
            return const DLEmptyState(icon: Icons.search_off, message: 'الوحدة غير موجودة • Modul nicht gefunden');
          }
          final t = Theme.of(context).textTheme;
          final p = c.moduleProgress(m);
          return ListView(
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [
              DLBilingualTitle(arabic: m.titleAr, german: '${m.level.code} • ${m.titleDe}'),
              if (m.descriptionAr.isNotEmpty) ...[
                const SizedBox(height: DLSpacing.sm),
                Text(m.descriptionAr, style: t.bodyLarge),
              ],
              const SizedBox(height: DLSpacing.md),
              DLProgressBar(value: p.total == 0 ? 0 : p.done / p.total, showLabel: true),
              const SizedBox(height: DLSpacing.lg),
              for (final (i, l) in c.lessonsOf(m).indexed) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}', style: t.titleMedium, textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: DLSpacing.sm),
                    Expanded(
                      child: LessonCard(lesson: l, progress: c.progress[l.id], assigned: assigned.contains(l.id)),
                    ),
                  ],
                ),
                const SizedBox(height: DLSpacing.md),
              ],
            ],
          );
        }),
      ),
    );
  }
}
