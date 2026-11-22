import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// App logo mark (graduation cap on a navy rounded square) and wordmark.
class DLLogo extends StatelessWidget {
  const DLLogo({super.key, this.size = 72, this.showWordmark = true, this.subtitle});

  final double size;
  final bool showWordmark;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DLColors.navy, Color(0xFF1D4E7A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(color: DLColors.navy.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.55),
        ),
        if (showWordmark) ...[
          const SizedBox(height: DLSpacing.md),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Deutsch',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const TextSpan(text: 'Learn', style: TextStyle(color: DLColors.teal)),
                ],
              ),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
        ],
      ],
    );
  }
}
