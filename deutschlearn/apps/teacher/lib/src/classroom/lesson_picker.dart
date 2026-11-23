import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'classroom_providers.dart';

/// Every module of every level (Alphabet → B1) with its lessons; nothing is locked.
class CurriculumBrowser extends ConsumerStatefulWidget {
  const CurriculumBrowser({super.key, required this.onLesson, this.scroll, this.trailing});

  final ValueChanged<Lesson> onLesson;
  final ScrollController? scroll;
  final Widget Function(Lesson)? trailing;

  @override
  ConsumerState<CurriculumBrowser> createState() => _CurriculumBrowserState();
}

class _CurriculumBrowserState extends ConsumerState<CurriculumBrowser> {
  CefrLevel? _level;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(teacherModulesProvider);
    final lessons = ref.watch(teacherAllLessonsProvider);
    final theme = Theme.of(context);
    if (modules.error ?? lessons.error case final e?) {
      return Padding(
        padding: const EdgeInsets.all(DLSpacing.lg),
        child: DLBanner(tone: DLStatusTone.error, message: e is AppFailure ? e.message : '$e'),
      );
    }
    if (!modules.hasValue || !lessons.hasValue) return const Center(child: CircularProgressIndicator());
    final ms = [...modules.value!]
      ..sort(
        (a, b) =>
            a.level.index != b.level.index ? a.level.index.compareTo(b.level.index) : a.position.compareTo(b.position),
      );
    final q = _query.trim().toLowerCase();
    final ls =
        lessons.value!.where((l) => q.isEmpty || l.titleDe.toLowerCase().contains(q) || l.titleAr.contains(q)).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    final levels = CefrLevel.values.where((lv) => ms.any((m) => m.level == lv)).toList();
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.all(DLSpacing.lg),
      children: [
        TextField(
          key: const Key('lesson-search'),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'بحث • Suchen'),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: DLSpacing.md),
        Wrap(
          spacing: DLSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('الكل • Alle'),
              selected: _level == null,
              onSelected: (_) => setState(() => _level = null),
            ),
            for (final lv in levels)
              ChoiceChip(
                key: Key('level-${lv.code}'),
                label: Text(lv.code),
                selected: _level == lv,
                onSelected: (_) => setState(() => _level = lv),
              ),
          ],
        ),
        const SizedBox(height: DLSpacing.md),
        for (final m in ms.where((m) => _level == null || m.level == _level))
          if (ls.where((l) => l.moduleId == m.id).toList() case final mls when mls.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: DLSpacing.sm),
              child: ExpansionTile(
                key: Key('module-${m.id}'),
                initiallyExpanded: q.isNotEmpty,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    m.slug.startsWith('alphabet') ? 'ABC' : m.level.code,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(m.titleAr.isEmpty ? m.titleDe : m.titleAr, style: theme.textTheme.titleSmall),
                subtitle: Text('${m.titleDe} • ${mls.length}', textDirection: TextDirection.ltr),
                children: [
                  for (final l in mls)
                    ListTile(
                      key: Key('pick-${l.id}'),
                      leading: Icon(switch (l.kind) {
                        LessonKind.lesson => Icons.menu_book_rounded,
                        LessonKind.test => Icons.quiz_rounded,
                        LessonKind.exam => Icons.school_rounded,
                        LessonKind.placement => Icons.track_changes_rounded,
                      }, color: theme.colorScheme.primary),
                      title: Text(l.titleDe, textDirection: TextDirection.ltr),
                      subtitle: l.titleAr.isEmpty ? null : Text(l.titleAr),
                      trailing: widget.trailing?.call(l),
                      onTap: () => widget.onLesson(l),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Bottom sheet to choose any lesson of any level.
Future<Lesson?> pickLesson(BuildContext context) => showModalBottomSheet<Lesson>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (ctx) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    builder: (ctx, scroll) => CurriculumBrowser(scroll: scroll, onLesson: (l) => Navigator.of(ctx).pop(l)),
  ),
);
