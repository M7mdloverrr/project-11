import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Arabic headline with its German counterpart underneath, as used across the
/// reference designs ("مسار تعلم الألمانية" / "Dein Lernweg").
class DLBilingualTitle extends StatelessWidget {
  const DLBilingualTitle({super.key, required this.arabic, required this.german, this.style, this.align});

  final String arabic;
  final String german;
  final TextStyle? style;
  final CrossAxisAlignment? align;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: align ?? CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(arabic, style: style ?? theme.textTheme.titleMedium, textDirection: TextDirection.rtl),
        Text(
          german,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Section header with optional trailing action.
class DLSectionHeader extends StatelessWidget {
  const DLSectionHeader({super.key, required this.arabic, required this.german, this.trailing});

  final String arabic;
  final String german;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DLSpacing.lg, bottom: DLSpacing.sm),
      child: Row(
        children: [
          Expanded(child: DLBilingualTitle(arabic: arabic, german: german)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Text field label in the form "البريد الإلكتروني • E-Mail".
String bilingualLabel(String arabic, String german) => '$arabic • $german';

