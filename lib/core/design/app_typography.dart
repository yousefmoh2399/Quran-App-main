import 'package:flutter/material.dart';

/// Design system typography using Cairo for UI and Amiri for decorative/spiritual titles.
class AppTypography {
  static const String uiFont = 'Cairo';
  static const String decorativeFont = 'Amiri';
  static const String quranFont = 'uthman';
  static const String surahNameFont = 'SurahName';

  /// Generates a TextTheme respecting system textScaler while maintaining hierarchy.
  static TextTheme createTextTheme(Color textColor, Color textMutedColor) {
    return TextTheme(
      // Display: large decorative numbers or headers
      displayLarge: const TextStyle(
        fontFamily: decorativeFont,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        height: 1.25,
      ).copyWith(color: textColor),
      displayMedium: const TextStyle(
        fontFamily: decorativeFont,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ).copyWith(color: textColor),
      displaySmall: const TextStyle(
        fontFamily: decorativeFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ).copyWith(color: textColor),

      // Headline: page titles and major sections
      headlineLarge: const TextStyle(
        fontFamily: decorativeFont,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.35,
      ).copyWith(color: textColor),
      headlineMedium: const TextStyle(
        fontFamily: decorativeFont,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ).copyWith(color: textColor),
      headlineSmall: const TextStyle(
        fontFamily: uiFont,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ).copyWith(color: textColor),

      // Title: card titles, app bar titles
      titleLarge: const TextStyle(
        fontFamily: uiFont,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ).copyWith(color: textColor),
      titleMedium: const TextStyle(
        fontFamily: uiFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ).copyWith(color: textColor),
      titleSmall: const TextStyle(
        fontFamily: uiFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ).copyWith(color: textColor),

      // Body: content reading, paragraphs, details
      bodyLarge: const TextStyle(
        fontFamily: uiFont,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.5,
      ).copyWith(color: textColor),
      bodyMedium: const TextStyle(
        fontFamily: uiFont,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
      ).copyWith(color: textColor),
      bodySmall: const TextStyle(
        fontFamily: uiFont,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.5,
      ).copyWith(color: textMutedColor),

      // Label: buttons, tags, captions
      labelLarge: const TextStyle(
        fontFamily: uiFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ).copyWith(color: textColor),
      labelMedium: const TextStyle(
        fontFamily: uiFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ).copyWith(color: textMutedColor),
      labelSmall: const TextStyle(
        fontFamily: uiFont,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.3,
      ).copyWith(color: textMutedColor),
    );
  }
}
