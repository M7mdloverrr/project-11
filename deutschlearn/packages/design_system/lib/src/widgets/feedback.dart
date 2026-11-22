import 'package:material_ui/material_ui.dart';

import '../tokens.dart';
import 'cards.dart';

enum DLStatusTone { success, error, warning, info, neutral }

Color _toneColor(DLStatusTone tone) => switch (tone) {
  DLStatusTone.success => DLColors.success,
  DLStatusTone.error => DLColors.error,
  DLStatusTone.warning => const Color(0xFFB7791F),
  DLStatusTone.info => DLColors.blue,
  DLStatusTone.neutral => DLColors.textSecondary,
};

IconData _toneIcon(DLStatusTone tone) => switch (tone) {
  DLStatusTone.success => Icons.check_circle_rounded,
  DLStatusTone.error => Icons.cancel_rounded,
  DLStatusTone.warning => Icons.warning_amber_rounded,
  DLStatusTone.info => Icons.info_rounded,
  DLStatusTone.neutral => Icons.circle_outlined,
};

/// Pill-shaped status label (Richtig / Falsch / Ausstehend ...).
class DLStatusChip extends StatelessWidget {
  const DLStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final DLStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final c = _toneColor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DLSpacing.sm + 2, vertical: DLSpacing.xs),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DLRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_toneIcon(tone), size: 16, color: c),
          const SizedBox(width: DLSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Inline message box for errors, warnings and info.
class DLBanner extends StatelessWidget {
  const DLBanner({super.key, required this.message, this.tone = DLStatusTone.info, this.title, this.action});

  final String message;
  final String? title;
  final DLStatusTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = _toneColor(tone);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(DLSpacing.md),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: DLRadius.control,
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_toneIcon(tone), color: c),
          const SizedBox(width: DLSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: theme.textTheme.titleSmall?.copyWith(color: c)),
                Text(message, style: theme.textTheme.bodyMedium),
                if (action != null) Padding(padding: const EdgeInsets.only(top: DLSpacing.sm), child: action),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Honest placeholder for features that are not built yet.
class DLComingSoon extends StatelessWidget {
  const DLComingSoon({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.subtitle,
    this.badge = 'قريباً • Demnächst',
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String message;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DLSpacing.xl),
        child: DLCard(
          padding: const EdgeInsets.all(DLSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DLIconBadge(icon: icon, color: DLColors.blue, size: 72),
              const SizedBox(height: DLSpacing.lg),
              Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: DLSpacing.md),
              DLStatusChip(label: badge, tone: DLStatusTone.info),
              const SizedBox(height: DLSpacing.md),
              Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered empty-state message for lists.
class DLEmptyState extends StatelessWidget {
  const DLEmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(DLSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: DLSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
