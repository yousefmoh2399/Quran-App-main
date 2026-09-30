import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Central theme provider generating Material 3 themes matching the design system.
class AppTheme {
  /// Light ThemeData
  static ThemeData get light {
    const colors = AppColorsExtension.light;
    final textTheme = AppTypography.createTextTheme(colors.text, colors.textMuted);

    final colorScheme = ColorScheme.light(
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.accent,
      onSecondary: Colors.white,
      surface: colors.surface,
      onSurface: colors.text,
      error: colors.error,
      onError: Colors.white,
      outline: colors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.uiFont,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,
      textTheme: textTheme,
      extensions: const [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.text,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.text),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: Color(0xFFE6DFCC), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE6DFCC),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.radiusXl),
        ),
      ),
    );
  }

  /// Dark ThemeData
  static ThemeData get dark {
    const colors = AppColorsExtension.dark;
    final textTheme = AppTypography.createTextTheme(colors.text, colors.textMuted);

    final colorScheme = ColorScheme.dark(
      primary: colors.primary,
      onPrimary: Colors.black,
      secondary: colors.accent,
      onSecondary: Colors.black,
      surface: colors.surface,
      onSurface: colors.text,
      error: colors.error,
      onError: Colors.black,
      outline: colors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.uiFont,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,
      textTheme: textTheme,
      extensions: const [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.text,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.text),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: Color(0xFF24332D), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF24332D),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF16211D),
        modalBackgroundColor: Color(0xFF16211D),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.radiusXl),
        ),
      ),
    );
  }
}
