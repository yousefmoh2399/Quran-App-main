import 'package:flutter/material.dart';

/// Supported reading themes for the authentic Mushaf view.
enum MushafThemeMode {
  light,
  dark,
  readingNight,
  sepia;

  static MushafThemeMode fromString(String? val) {
    switch (val) {
      case 'dark':
        return MushafThemeMode.dark;
      case 'readingNight':
        return MushafThemeMode.readingNight;
      case 'sepia':
        return MushafThemeMode.sepia;
      case 'light':
      default:
        return MushafThemeMode.light;
    }
  }

  String toPrefString() => name;
}

/// Visual styling tokens for the Mushaf page corresponding to a [MushafThemeMode].
class MushafThemeConfig {
  final MushafThemeMode mode;
  final Color pageBg;
  final Color frameBorderOuter;
  final Color frameBorderInner;
  final Color cornerAccent;
  final Color textColor;
  final Color headerFooterColor;
  final Color ayahHighlight;
  final Color surahHeaderBg;
  final Color surahHeaderBorder;
  final Color surahHeaderTextColor;
  final Color spineShadow;

  const MushafThemeConfig({
    required this.mode,
    required this.pageBg,
    required this.frameBorderOuter,
    required this.frameBorderInner,
    required this.cornerAccent,
    required this.textColor,
    required this.headerFooterColor,
    required this.ayahHighlight,
    required this.surahHeaderBg,
    required this.surahHeaderBorder,
    required this.surahHeaderTextColor,
    required this.spineShadow,
  });

  bool get isDark => mode == MushafThemeMode.dark || mode == MushafThemeMode.readingNight;

  /// Authentic Light Parchment Theme
  static const light = MushafThemeConfig(
    mode: MushafThemeMode.light,
    pageBg: Color(0xFFFAF6EC), // Warm parchment paper
    frameBorderOuter: Color(0xFFB8892B), // Brass / gold
    frameBorderInner: Color(0xFF0F5C4A), // Islamic emerald
    cornerAccent: Color(0xFFB8892B),
    textColor: Color(0xFF1E2A26), // Crisp dark ink
    headerFooterColor: Color(0xFF5F6B66),
    ayahHighlight: Color(0x38B8892B), // Translucent warm amber
    surahHeaderBg: Color(0xFFF1EAD8),
    surahHeaderBorder: Color(0xFFB8892B),
    surahHeaderTextColor: Color(0xFF0F5C4A),
    spineShadow: Color(0x33000000),
  );

  /// Modern Dark Theme
  static const dark = MushafThemeConfig(
    mode: MushafThemeMode.dark,
    pageBg: Color(0xFF0E1512),
    frameBorderOuter: Color(0xFF24332D),
    frameBorderInner: Color(0xFF3FB597),
    cornerAccent: Color(0xFFD9B25A),
    textColor: Color(0xFFE7EEEA),
    headerFooterColor: Color(0xFF9AA8A2),
    ayahHighlight: Color(0x403FB597),
    surahHeaderBg: Color(0xFF16211D),
    surahHeaderBorder: Color(0xFF3FB597),
    surahHeaderTextColor: Color(0xFFD9B25A),
    spineShadow: Color(0x66000000),
  );

  /// Warm Reading Night Theme (Low blue light dark mode)
  static const readingNight = MushafThemeConfig(
    mode: MushafThemeMode.readingNight,
    pageBg: Color(0xFF14110D),
    frameBorderOuter: Color(0xFF2A241D),
    frameBorderInner: Color(0xFFB8892B),
    cornerAccent: Color(0xFFD9B25A),
    textColor: Color(0xFFE8DCC2),
    headerFooterColor: Color(0xFFA69C88),
    ayahHighlight: Color(0x40D9B25A),
    surahHeaderBg: Color(0xFF1C1813),
    surahHeaderBorder: Color(0xFFB8892B),
    surahHeaderTextColor: Color(0xFFE8DCC2),
    spineShadow: Color(0x77000000),
  );

  /// Authentic Warm Paper / Sepia Theme (Ancient manuscript warmth, easy on eyes)
  static const sepia = MushafThemeConfig(
    mode: MushafThemeMode.sepia,
    pageBg: Color(0xFFF4ECD8),
    frameBorderOuter: Color(0xFFA67C2A),
    frameBorderInner: Color(0xFF205243),
    cornerAccent: Color(0xFFA67C2A),
    textColor: Color(0xFF2A2118),
    headerFooterColor: Color(0xFF6B5847),
    ayahHighlight: Color(0x38C59A45),
    surahHeaderBg: Color(0xFFEADBBE),
    surahHeaderBorder: Color(0xFFA67C2A),
    surahHeaderTextColor: Color(0xFF205243),
    spineShadow: Color(0x38000000),
  );

  static MushafThemeConfig of(MushafThemeMode mode) {
    switch (mode) {
      case MushafThemeMode.light:
        return light;
      case MushafThemeMode.dark:
        return dark;
      case MushafThemeMode.readingNight:
        return readingNight;
      case MushafThemeMode.sepia:
        return sepia;
    }
  }
}
