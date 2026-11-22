import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Light and dark themes built on the brand tokens and the bundled Cairo font
/// (covers Arabic and Latin, so German text renders in the same family).
abstract final class DLTheme {
  static const fontFamily = 'Cairo';
  static const fontPackage = 'design_system';

  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: DLColors.teal,
      onPrimary: Colors.white,
      primaryContainer: DLColors.mint,
      onPrimaryContainer: DLColors.navy,
      secondary: DLColors.blue,
      onSecondary: Colors.white,
      secondaryContainer: DLColors.tintBlue,
      onSecondaryContainer: DLColors.navy,
      tertiary: DLColors.yellow,
      onTertiary: DLColors.navy,
      error: DLColors.error,
      onError: Colors.white,
      surface: DLColors.surface,
      onSurface: DLColors.textPrimary,
      onSurfaceVariant: DLColors.textSecondary,
      surfaceContainerHighest: DLColors.background,
      outline: DLColors.border,
      outlineVariant: DLColors.border,
    ),
    background: DLColors.background,
    navBar: DLColors.navy,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF2BB8AA),
      onPrimary: DLColors.navy,
      primaryContainer: Color(0xFF12403C),
      onPrimaryContainer: DLColors.mint,
      secondary: Color(0xFF5AAEE8),
      onSecondary: DLColors.navy,
      secondaryContainer: Color(0xFF173E5E),
      onSecondaryContainer: DLColors.darkTextPrimary,
      tertiary: DLColors.yellow,
      onTertiary: DLColors.navy,
      error: Color(0xFFF27C7C),
      onError: DLColors.navy,
      surface: DLColors.darkSurface,
      onSurface: DLColors.darkTextPrimary,
      onSurfaceVariant: DLColors.darkTextSecondary,
      surfaceContainerHighest: DLColors.darkSurfaceHigh,
      outline: DLColors.darkBorder,
      outlineVariant: DLColors.darkBorder,
    ),
    background: DLColors.darkBackground,
    navBar: DLColors.darkSurface,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required Color navBar,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'packages/$fontPackage/$fontFamily',
      scaffoldBackgroundColor: background,
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return base.copyWith(
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: DLRadius.card,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: DLSpacing.lg, vertical: DLSpacing.md),
        border: OutlineInputBorder(borderRadius: DLRadius.control, borderSide: BorderSide(color: scheme.outline)),
        enabledBorder: OutlineInputBorder(
          borderRadius: DLRadius.control,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DLRadius.control,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DLRadius.control,
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: DLRadius.control),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: DLRadius.control),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navBar,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: DLRadius.control),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
    );
  }
}
