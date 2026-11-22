import 'package:flutter/widgets.dart';

/// Brand color tokens.
abstract final class DLColors {
  static const navy = Color(0xFF102A43);
  static const teal = Color(0xFF0E9488);
  static const blue = Color(0xFF2387D1);
  static const mint = Color(0xFFE8F8F3);
  static const yellow = Color(0xFFFFC857);
  static const success = Color(0xFF28A745);
  static const error = Color(0xFFEA5353);
  static const background = Color(0xFFF6F9FC);

  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = navy;
  static const textSecondary = Color(0xFF5A6B7D);
  static const border = Color(0xFFE3EAF2);

  // Dark theme counterparts.
  static const darkBackground = Color(0xFF0B1B2B);
  static const darkSurface = Color(0xFF132A40);
  static const darkSurfaceHigh = Color(0xFF1B3753);
  static const darkTextPrimary = Color(0xFFEAF1F8);
  static const darkTextSecondary = Color(0xFFA9BACB);
  static const darkBorder = Color(0xFF24435F);

  // Soft tints used behind icons, matching the pastel tiles of the reference.
  static const tintTeal = Color(0xFFE0F4F1);
  static const tintBlue = Color(0xFFE4F1FB);
  static const tintYellow = Color(0xFFFFF4DB);
  static const tintRed = Color(0xFFFDE8E8);
  static const tintPurple = Color(0xFFEFE9FB);
}

abstract final class DLSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class DLRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const pill = 999.0;

  static const card = BorderRadius.all(Radius.circular(lg));
  static const control = BorderRadius.all(Radius.circular(md));
}
