import 'package:flutter/material.dart';

/// ThemeExtension that provides custom design system colors for the app.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color bg;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color text;
  final Color textMuted;
  final Color divider;
  final Color error;

  const AppColorsExtension({
    required this.bg,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.divider,
    required this.error,
  });

  /// Light theme palette
  static const light = AppColorsExtension(
    bg: Color(0xFFFAF6EC),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF0F5C4A),
    accent: Color(0xFFB8892B),
    text: Color(0xFF1E2A26),
    textMuted: Color(0xFF5F6B66),
    divider: Color(0xFFE6DFCC),
    error: Color(0xFFB3261E),
  );

  /// Dark theme palette
  static const dark = AppColorsExtension(
    bg: Color(0xFF0E1512),
    surface: Color(0xFF16211D),
    primary: Color(0xFF3FB597),
    accent: Color(0xFFD9B25A),
    text: Color(0xFFE7EEEA),
    textMuted: Color(0xFF9AA8A2),
    divider: Color(0xFF24332D),
    error: Color(0xFFF2B8B5),
  );

  /// Reading night theme palette (for comfortable night reading of Quran/Azkar)
  static const readingNight = AppColorsExtension(
    bg: Color(0xFF14110D),
    surface: Color(0xFF1C1813),
    primary: Color(0xFFD9B25A),
    accent: Color(0xFFE8DCC2),
    text: Color(0xFFE8DCC2),
    textMuted: Color(0xFFA69C88),
    divider: Color(0xFF2A241D),
    error: Color(0xFFF2B8B5),
  );

  @override
  AppColorsExtension copyWith({
    Color? bg,
    Color? surface,
    Color? primary,
    Color? accent,
    Color? text,
    Color? textMuted,
    Color? divider,
    Color? error,
  }) {
    return AppColorsExtension(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      error: error ?? this.error,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      text: Color.lerp(text, other.text, t) ?? text,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      error: Color.lerp(error, other.error, t) ?? error,
    );
  }
}

/// Extension on BuildContext for quick access to design colors.
extension AppColorsBuildContextExtension on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
