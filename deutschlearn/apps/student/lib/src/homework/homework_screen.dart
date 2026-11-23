import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../router.dart';
import 'homework_providers.dart';

String formatDue(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

DLStatusTone statusTone(SubmissionStatus s, {bool overdue = false}) => switch (s) {
  SubmissionStatus.graded => DLStatusTone.success,
  SubmissionStatus.submitted => DLStatusTone.info,
  SubmissionStatus.returned => DLStatusTone.warning,
  _ => overdue ? DLStatusTone.error : DLStatusTone.neutral,
};

IconData homeworkIcon(HomeworkKind k) => switch (k) {
  HomeworkKind.lesson => Icons.menu_book_rounded,
  HomeworkKind.exercises => Icons.fact_check_rounded,
  HomeworkKind.custom => Icons.edit_note_rounded,
  HomeworkKind.study => Icons.psychology_alt_rounded,
};

/// All homework: open work first (with deadlines), then submitted and graded work.
class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(homeworkProvider);
    return Scaffold(
      appBar: AppBar(
        title: const DLBilingualTitle(arabic: 'الواجبات المنزلية', german: 'Hausaufgaben'),
      ),
      body: DLMaxWidth(
        child: switch (entries) {
          AsyncError(:final error) => Padding(
            padding: const EdgeInsets.all(DLSpacing.lg),
            child: DLBanner(tone: DLStatusTone.error, message: error is AppFailure ? error.message : '$error'),
          ),
          AsyncData(value: final list) when list.isEmpty => const DLEmptyState(
            icon: Icons.assignment_turned_in_outlined,
            message: 'لا توجد واجبات حالياً • Keine Hausaufgaben',
          ),
          AsyncData(value: final list) => ListView(
            padding: const EdgeInsets.all(DLSpacing.lg),
            children: [
              for (final (i, e) in list.indexed) ...[
                if (i == 0 || list[i - 1].isOpen != e.isOpen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DLSpacing.sm, top: DLSpacing.sm),
                    child: e.isOpen
                        ? const DLSectionHeader(arabic: 'مطلوب منك', german: 'Offen')
                        : const DLSectionHeader(arabic: 'السابقة', german: 'Abgegeben & bewertet'),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: DLSpacing.md),
                  child: HomeworkTile(entry: e, onTap: () => context.push(StudentRoutes.homeworkDetail(e.homework.id))),
                ),
              ],
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class HomeworkTile extends StatelessWidget {
  const HomeworkTile({super.key, required this.entry, this.onTap});

  final HomeworkEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final h = entry.homework;
    final theme = Theme.of(context);
    final overdue = entry.isOpen && h.isOverdue();
    return DLCard(
      key: Key('homework-${h.id}'),
      onTap: onTap,
      child: Row(
        children: [
          DLIconBadge(icon: homeworkIcon(h.kind), color: const Color(0xFFE58A1F)),
          const SizedBox(width: DLSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.title.isEmpty ? 'واجب • Aufgabe' : h.title, style: theme.textTheme.titleMedium),
                if (h.dueAt != null)
                  Text(
                    'آخر موعد • Frist: ${formatDue(h.dueAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: DLSpacing.xs),
                Wrap(
                  spacing: DLSpacing.sm,
                  children: [
                    DLStatusChip(
                      label: overdue ? 'متأخر • Überfällig' : '${entry.status.ar} • ${entry.status.de}',
                      tone: statusTone(entry.status, overdue: overdue),
                    ),
                    if (entry.submission?.grade != null)
                      DLStatusChip(label: '${entry.submission!.grade} / 100', tone: DLStatusTone.success),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
