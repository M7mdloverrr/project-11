import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Renders a lesson explanation written in a tiny markdown subset:
/// `## heading`, `- bullet`, `| table | row |`, `> example` (German, LTR) and paragraphs.
class RichExplanation extends StatelessWidget {
  const RichExplanation(this.source, {super.key});

  final String source;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final children = <Widget>[];
    final table = <List<String>>[];

    void flushTable() {
      if (table.isEmpty) return;
      final rows = table.where((r) => !r.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))).toList();
      final cols = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: DLSpacing.sm),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(
                color: DLColors.teal.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              children: [
                for (final (i, r) in rows.indexed)
                  TableRow(
                    decoration: i == 0 ? BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer) : null,
                    children: [
                      for (var c = 0; c < cols; c++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text(c < r.length ? r[c] : '', style: i == 0 ? t.titleSmall : t.bodyMedium),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
      table.clear();
    }

    for (final raw in source.split('\n')) {
      final line = raw.trim();
      if (line.startsWith('|')) {
        table.add(
          line
              .substring(1, line.endsWith('|') ? line.length - 1 : line.length)
              .split('|')
              .map((c) => c.trim())
              .toList(),
        );
        continue;
      }
      flushTable();
      if (line.isEmpty) {
        children.add(const SizedBox(height: DLSpacing.sm));
      } else if (line.startsWith('## ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: DLSpacing.md, bottom: DLSpacing.xs),
            child: Text(
              line.substring(3),
              style: t.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•  ',
                  style: TextStyle(color: DLColors.teal, fontWeight: FontWeight.w900),
                ),
                Expanded(child: Text(line.substring(2), style: t.bodyLarge)),
              ],
            ),
          ),
        );
      } else if (line.startsWith('> ')) {
        children.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: DLSpacing.md, vertical: DLSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              line.substring(2),
              textDirection: TextDirection.ltr,
              style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
      } else {
        children.add(Text(line, style: t.bodyLarge));
      }
    }
    flushTable();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
