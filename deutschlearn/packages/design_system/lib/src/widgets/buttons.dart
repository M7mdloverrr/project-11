import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Full-width primary action. Shows a spinner and ignores taps while [loading].
class DLPrimaryButton extends StatelessWidget {
  const DLPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
        : _Label(label: label, icon: icon);
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: color == null ? null : FilledButton.styleFrom(backgroundColor: color),
      child: child,
    );
  }
}

/// Full-width outlined secondary action.
class DLSecondaryButton extends StatelessWidget {
  const DLSecondaryButton({super.key, required this.label, required this.onPressed, this.icon, this.color});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: color == null
          ? null
          : OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color!),
            ),
      child: _Label(label: label, icon: icon),
    );
  }
}

/// Small rounded icon action with a caption underneath (copy / share / ...).
class DLIconAction extends StatelessWidget {
  const DLIconAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = DLColors.teal,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final c = enabled ? color : Theme.of(context).disabledColor;
    return InkWell(
      onTap: onPressed,
      borderRadius: DLRadius.control,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DLSpacing.sm, horizontal: DLSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: DLRadius.control),
              child: Icon(icon, color: c),
            ),
            const SizedBox(height: DLSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: DLSpacing.sm),
        Flexible(child: Text(label)),
      ],
    );
  }
}
