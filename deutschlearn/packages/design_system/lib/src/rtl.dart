import 'package:flutter/widgets.dart';

/// Locales whose script runs right-to-left.
const rtlLanguageCodes = {'ar', 'fa', 'he', 'ur'};

bool isRtlLocale(Locale locale) => rtlLanguageCodes.contains(locale.languageCode);

TextDirection textDirectionFor(Locale locale) => isRtlLocale(locale) ? TextDirection.rtl : TextDirection.ltr;

extension DLDirectionContext on BuildContext {
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

/// Forces left-to-right layout for embedded German/Latin content (example
/// sentences, emails, codes) inside an Arabic screen, and vice versa.
class ForceDirection extends StatelessWidget {
  const ForceDirection.ltr({super.key, required this.child}) : direction = TextDirection.ltr;
  const ForceDirection.rtl({super.key, required this.child}) : direction = TextDirection.rtl;

  final TextDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(textDirection: direction, child: child);
}

/// Mirrors a directional icon (arrows, chevrons) in RTL layouts.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final widget = Icon(icon, size: size, color: color);
    if (!context.isRtl) return widget;
    return Transform.flip(flipX: true, child: widget);
  }
}
