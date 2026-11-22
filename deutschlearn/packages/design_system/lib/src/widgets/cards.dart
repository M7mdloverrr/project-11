import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Rounded white card with a soft shadow, the base surface of every screen.
class DLCard extends StatelessWidget {
  const DLCard({super.key, required this.child, this.padding, this.onTap, this.color, this.gradient});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? scheme.surface) : null,
        gradient: gradient,
        borderRadius: DLRadius.card,
        border: Border.all(color: scheme.outline.withValues(alpha: dark ? 1 : 0.6)),
        boxShadow: dark
            ? null
            : [BoxShadow(color: DLColors.navy.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: DLRadius.card,
          child: Padding(padding: padding ?? const EdgeInsets.all(DLSpacing.lg), child: child),
        ),
      ),
    );
  }
}

/// Pastel rounded square holding an icon, like the feature tiles in the mockups.
class DLIconBadge extends StatelessWidget {
  const DLIconBadge({super.key, required this.icon, this.color = DLColors.teal, this.size = 48});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// Card row with icon badge, bilingual title and optional trailing widget.
class DLFeatureTile extends StatelessWidget {
  const DLFeatureTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = DLColors.teal,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DLCard(
      onTap: onTap,
      padding: const EdgeInsets.all(DLSpacing.md),
      child: Row(
        children: [
          DLIconBadge(icon: icon, color: color),
          const SizedBox(width: DLSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
