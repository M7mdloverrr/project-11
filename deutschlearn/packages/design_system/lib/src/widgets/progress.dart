import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Rounded linear progress bar with optional percentage label.
class DLProgressBar extends StatelessWidget {
  const DLProgressBar({super.key, required this.value, this.color = DLColors.teal, this.height = 10, this.showLabel = false});

  final double value;
  final Color color;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: v,
        minHeight: height,
        color: color,
        backgroundColor: color.withValues(alpha: 0.14),
      ),
    );
    if (!showLabel) return bar;
    return Row(
      children: [
        Expanded(child: bar),
        const SizedBox(width: DLSpacing.sm),
        Text('${(v * 100).round()}%', style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

/// Circular progress ring with the percentage in the middle.
class DLProgressRing extends StatelessWidget {
  const DLProgressRing({super.key, required this.value, this.size = 64, this.color = DLColors.teal, this.stroke = 7});

  final double value;
  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(v, color, stroke),
        child: Center(
          child: Text(
            '${(v * 100).round()}%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: size * 0.22),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.stroke);

  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, 2 * math.pi, false, track);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color;
}

/// CEFR learning path (A1 → A2 → B1 ...) with the current stage highlighted.
/// Always laid out left-to-right because level names are Latin.
class DLStagePath extends StatelessWidget {
  const DLStagePath({super.key, required this.stages, required this.current});

  final List<String> stages;
  final String current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = stages.indexOf(current);
    final children = <Widget>[];
    for (var i = 0; i < stages.length; i++) {
      final done = i < currentIndex;
      final active = i == currentIndex;
      final color = active || done ? DLColors.teal : theme.colorScheme.outline;
      children.add(
        Semantics(
          label: active ? '${stages[i]} (current)' : stages[i],
          child: Container(
            width: active ? 48 : 38,
            height: active ? 48 : 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? DLColors.yellow : (done ? DLColors.mint : theme.colorScheme.surface),
              border: Border.all(color: color, width: active ? 0 : 1.5),
            ),
            child: Text(
              stages[i],
              style: theme.textTheme.labelLarge?.copyWith(
                color: active ? DLColors.navy : (done ? DLColors.teal : theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      );
      if (i < stages.length - 1) {
        children.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: DLSpacing.xs),
              color: i < currentIndex ? DLColors.teal : theme.colorScheme.outline,
            ),
          ),
        );
      }
    }
    return Directionality(textDirection: TextDirection.ltr, child: Row(children: children));
  }
}
