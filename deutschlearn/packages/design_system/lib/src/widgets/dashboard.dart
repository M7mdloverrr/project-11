import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Pastel background that stays readable in dark mode.
Color dlTint(BuildContext context, Color color) =>
    Theme.of(context).brightness == Brightness.dark ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.10);

/// Navy→blue header with a Brandenburg Gate silhouette, as in the mockups.
class DLHeroHeader extends StatelessWidget {
  const DLHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.height = 150,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      constraints: BoxConstraints(minHeight: height + top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E3A5C), Color(0xFF2B6E9E), Color(0xFF8FC1E3)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(DLRadius.lg)),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: IgnorePointer(
              child: CustomPaint(size: const Size(190, 90), painter: _GatePainter()),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(DLSpacing.sm, DLSpacing.md + top, DLSpacing.sm, DLSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?leading,
                    const SizedBox(width: DLSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            key: const Key('hero-title'),
                            style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                          Text(subtitle, style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
                if (bottom != null) ...[const SizedBox(height: DLSpacing.md), bottom!],
                SizedBox(height: _OverlapScope.of(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stone = Paint()..color = const Color(0xFFF2E3C6).withValues(alpha: 0.85);
    final shade = Paint()..color = const Color(0xFFC9B28A).withValues(alpha: 0.85);
    final base = h * 0.98;
    // Attic + entablature.
    canvas.drawRect(Rect.fromLTRB(w * 0.08, h * 0.30, w * 0.92, h * 0.42), stone);
    canvas.drawRect(Rect.fromLTRB(w * 0.30, h * 0.18, w * 0.70, h * 0.30), stone);
    canvas.drawRect(Rect.fromLTRB(w * 0.06, h * 0.42, w * 0.94, h * 0.47), shade);
    // Columns.
    for (var i = 0; i < 6; i++) {
      final x = w * 0.10 + i * w * 0.152;
      canvas.drawRect(Rect.fromLTRB(x, h * 0.47, x + w * 0.05, base), stone);
    }
    canvas.drawRect(Rect.fromLTRB(w * 0.04, base - 3, w * 0.96, base + 2), shade);
    // Quadriga.
    final q = Path()
      ..moveTo(w * 0.40, h * 0.18)
      ..lineTo(w * 0.42, h * 0.08)
      ..lineTo(w * 0.47, h * 0.05)
      ..lineTo(w * 0.50, h * 0.0)
      ..lineTo(w * 0.53, h * 0.05)
      ..lineTo(w * 0.58, h * 0.08)
      ..lineTo(w * 0.60, h * 0.18)
      ..close();
    canvas.drawPath(q, Paint()..color = const Color(0xFF3F6B5A).withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Round icon button on the hero header with an optional red count badge.
class DLHeaderIcon extends StatelessWidget {
  const DLHeaderIcon({super.key, required this.icon, this.onPressed, this.badge = 0, this.tooltip});

  final IconData icon;
  final VoidCallback? onPressed;
  final int badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Badge(
      isLabelVisible: badge > 0,
      label: Text('$badge'),
      child: Icon(icon, color: Colors.white, size: 28),
    ),
  );
}

/// One stage of the roadmap (e.g. "A1" with the caption "Alphabet").
typedef DLRoadStage = ({String label, String? caption});

/// "Dein Lernweg" card: Alphabet → A1 → A2 → B1 with the current stage in yellow.
class DLRoadmapCard extends StatelessWidget {
  const DLRoadmapCard({
    super.key,
    required this.titleAr,
    required this.titleDe,
    required this.stages,
    required this.current,
    this.badge,
    this.onStage,
  });

  final String titleAr;
  final String titleDe;
  final List<DLRoadStage> stages;
  final int current;
  final String? badge;
  final ValueChanged<int>? onStage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nodes = <Widget>[];
    for (var i = 0; i < stages.length; i++) {
      final active = i == current;
      final done = i < current;
      final size = active ? 64.0 : 46.0;
      nodes.add(
        InkResponse(
          key: Key('road-$i'),
          onTap: onStage == null ? null : () => onStage!(i),
          radius: size / 2 + 6,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: active
                  ? const LinearGradient(colors: [Color(0xFFFFE08A), DLColors.yellow])
                  : LinearGradient(colors: [dlTint(context, DLColors.blue), dlTint(context, DLColors.teal)]),
              border: Border.all(
                color: active ? const Color(0xFFE0A526) : DLColors.blue.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: DLColors.yellow.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stages[i].label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: active ? DLColors.navy : (done ? DLColors.teal : scheme.onSurface),
                  ),
                ),
                if (stages[i].caption != null)
                  Text(
                    stages[i].caption!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: active ? DLColors.navy : scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      if (i < stages.length - 1) {
        nodes.add(
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i < current ? DLColors.teal : DLColors.blue.withValues(alpha: 0.25),
              ),
            ),
          ),
        );
      }
    }
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _Bilingual(ar: titleAr, de: titleDe, big: true),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DLSpacing.md, vertical: DLSpacing.xs + 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [DLColors.teal, Color(0xFF0B6F66)]),
                    borderRadius: BorderRadius.circular(DLRadius.sm),
                  ),
                  child: Text(
                    badge!,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DLSpacing.lg),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: nodes),
          ),
        ],
      ),
    );
  }
}

/// Three tilted letter blocks (A, B, C) used as the lesson illustration.
class DLAbcBlocks extends StatelessWidget {
  const DLAbcBlocks({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final b = size * 0.46;
    Widget block(String l, List<Color> c, double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: b,
        height: b,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c),
          borderRadius: BorderRadius.circular(b * 0.18),
          boxShadow: [BoxShadow(color: c.last.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(2, 3))],
        ),
        child: Text(
          l,
          style: TextStyle(fontSize: b * 0.62, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
        ),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(top: 0, left: size * 0.30, child: block('A', const [Color(0xFF6FD3A8), Color(0xFF1F9E73)], -0.08)),
          Positioned(bottom: 0, left: 0, child: block('B', const [Color(0xFFFFD36B), Color(0xFFF0A020)], 0.10)),
          Positioned(
            bottom: size * 0.04,
            right: 0,
            child: block('C', const [Color(0xFF6BB8F2), Color(0xFF2370C8)], -0.05),
          ),
        ],
      ),
    );
  }
}

/// "Lektion fortsetzen" card: illustration, lesson title, progress ring and a yellow CTA.
class DLResumeCard extends StatelessWidget {
  const DLResumeCard({
    super.key,
    required this.titleAr,
    required this.titleDe,
    required this.lessonLabel,
    required this.progress,
    required this.buttonAr,
    required this.buttonDe,
    this.onPressed,
    this.illustration,
  });

  final String titleAr;
  final String titleDe;
  final String lessonLabel;
  final double progress;
  final String buttonAr;
  final String buttonDe;
  final VoidCallback? onPressed;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Surface(
      child: Row(
        children: [
          Container(
            width: 104,
            height: 116,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dlTint(context, DLColors.blue),
              borderRadius: BorderRadius.circular(DLRadius.md),
            ),
            child: illustration ?? const DLAbcBlocks(size: 84),
          ),
          const SizedBox(width: DLSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Bilingual(ar: titleAr, de: titleDe, big: true),
                    ),
                    _Ring(value: progress),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  lessonLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: DLSpacing.sm),
                Material(
                  color: DLColors.yellow,
                  borderRadius: BorderRadius.circular(DLRadius.sm),
                  child: InkWell(
                    key: const Key('resume-button'),
                    onTap: onPressed,
                    borderRadius: BorderRadius.circular(DLRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: DLSpacing.sm, horizontal: DLSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                buttonAr,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: DLColors.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(buttonDe, style: theme.textTheme.labelSmall?.copyWith(color: DLColors.navy)),
                            ],
                          ),
                          const SizedBox(width: DLSpacing.sm),
                          const Icon(Icons.play_arrow_rounded, color: Color(0xFF8A3B12), size: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: value.clamp(0, 1),
            strokeWidth: 5,
            color: DLColors.success,
            backgroundColor: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          '${(value * 100).round()}%',
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

/// Pastel feature tile of the home grid: icon, Arabic title, German subtitle, optional red count.
class DLPastelTile extends StatelessWidget {
  const DLPastelTile({
    super.key,
    required this.icon,
    required this.color,
    required this.titleAr,
    required this.titleDe,
    this.badge = 0,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String titleAr;
  final String titleDe;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Color.alphaBlend(dlTint(context, color), scheme.surface),
      borderRadius: DLRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: DLRadius.card,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: DLSpacing.md, vertical: DLSpacing.md),
          decoration: BoxDecoration(
            borderRadius: DLRadius.card,
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(color.withValues(alpha: 0.16), scheme.surface),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: DLSpacing.sm),
              Expanded(
                child: _Bilingual(ar: titleAr, de: titleDe),
              ),
              if (badge > 0)
                Container(
                  key: const Key('tile-badge'),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: DLColors.error, shape: BoxShape.circle),
                  child: Text(
                    '$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive grid of [DLPastelTile]s: 2 columns on phones, 3–4 on tablets.
class DLTileGrid extends StatelessWidget {
  const DLTileGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 600 ? 3 : 2);
      final w = (c.maxWidth - (cols - 1) * DLSpacing.md) / cols;
      return Wrap(
        spacing: DLSpacing.md,
        runSpacing: DLSpacing.md,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}

/// "Dein Fortschritt" strip with a bar icon, the level label and a green bar.
class DLOverallProgressCard extends StatelessWidget {
  const DLOverallProgressCard({super.key, required this.label, required this.value, this.onTap});

  final String label;
  final double value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Surface(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dlTint(context, DLColors.success),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: DLColors.success, size: 30),
          ),
          const SizedBox(width: DLSpacing.sm),
          const Expanded(
            flex: 4,
            child: _Bilingual(ar: 'تقدّمك العام', de: 'Dein Fortschritt'),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$label (${(value * 100).round()}%)',
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: DLSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value.clamp(0, 1),
                    minHeight: 10,
                    color: DLColors.success,
                    backgroundColor: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One destination of [DLBottomNav].
typedef DLNavItem = ({IconData icon, String ar, String de});

/// Bottom navigation with Arabic + German labels and a teal pill on the selected item.
class DLBottomNav extends StatelessWidget {
  const DLBottomNav({super.key, required this.items, required this.index, required this.onTap});

  final List<DLNavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 12,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    key: Key('nav-$i'),
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46,
                          height: 32,
                          decoration: BoxDecoration(
                            color: i == index ? DLColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(items[i].icon, color: i == index ? Colors.white : scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].ar,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: i == index ? FontWeight.w800 : FontWeight.w500,
                            color: i == index ? scheme.onSurface : scheme.onSurfaceVariant,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          items[i].de,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: i == index ? DLColors.teal : scheme.onSurfaceVariant,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bilingual heading: bold Arabic over the German line.
class _Bilingual extends StatelessWidget {
  const _Bilingual({required this.ar, required this.de, this.big = false});

  final String ar;
  final String de;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ar,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (big ? t.titleMedium : t.titleSmall)?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            height: 1.2,
          ),
        ),
        Text(
          de,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: (big ? t.bodyMedium : t.bodySmall)?.copyWith(color: scheme.onSurfaceVariant, height: 1.2),
        ),
      ],
    );
  }
}

/// White rounded surface with a soft shadow (same look as DLCard, tighter padding).
class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: DLRadius.card,
        border: Border.all(color: scheme.outline.withValues(alpha: dark ? 1 : 0.5)),
        boxShadow: dark
            ? null
            : [BoxShadow(color: DLColors.navy.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: DLRadius.card,
          child: Padding(padding: const EdgeInsets.all(DLSpacing.lg), child: child),
        ),
      ),
    );
  }
}

/// Keeps content readable on tablets by capping its width.
class DLMaxWidth extends StatelessWidget {
  const DLMaxWidth({super.key, required this.child, this.maxWidth = 820});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// A hero header whose lower part is covered by the first content card. The header
/// grows with its text and reserves [overlap] extra space, so nothing is hidden.
class DLHeaderOverlap extends StatelessWidget {
  const DLHeaderOverlap({super.key, required this.header, required this.child, this.overlap = 56});

  final Widget header;
  final Widget child;
  final double overlap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _OverlapScope(space: overlap, child: header),
      Transform.translate(offset: Offset(0, -overlap), child: child),
    ],
  );
}

class _OverlapScope extends InheritedWidget {
  const _OverlapScope({required this.space, required super.child});

  final double space;

  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_OverlapScope>()?.space ?? 0;

  @override
  bool updateShouldNotify(_OverlapScope old) => old.space != space;
}
