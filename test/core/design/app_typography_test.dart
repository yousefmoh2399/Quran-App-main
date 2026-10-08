import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/core/design/app_typography.dart';

void main() {
  group('AppTypography & AppTheme Fallback Fonts Tests', () {
    test('AppTypography.fallbackFonts contains Islamic and UI font fallback chains', () {
      expect(AppTypography.fallbackFonts, contains('Amiri'));
      expect(AppTypography.fallbackFonts, contains('Cairo'));
    });

    test('All text styles in createTextTheme have fontFamilyFallback configured', () {
      final theme = AppTypography.createTextTheme(Colors.black, Colors.grey);

      final styles = [
        theme.displayLarge,
        theme.displayMedium,
        theme.displaySmall,
        theme.headlineLarge,
        theme.headlineMedium,
        theme.headlineSmall,
        theme.titleLarge,
        theme.titleMedium,
        theme.titleSmall,
        theme.bodyLarge,
        theme.bodyMedium,
        theme.bodySmall,
        theme.labelLarge,
        theme.labelMedium,
        theme.labelSmall,
      ];

      for (final style in styles) {
        expect(style, isNotNull);
        expect(
          style!.fontFamilyFallback,
          equals(AppTypography.fallbackFonts),
          reason: 'Style $style must have fallbackFonts to avoid "?" on iOS/Android for emojis and ligatures',
        );
      }
    });

    test('AppTheme light and dark textThemes include fontFamilyFallback', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;

      expect(light.textTheme.bodyMedium?.fontFamilyFallback, equals(AppTypography.fallbackFonts));
      expect(dark.textTheme.bodyMedium?.fontFamilyFallback, equals(AppTypography.fallbackFonts));

      expect(light.textTheme.titleMedium?.fontFamilyFallback, equals(AppTypography.fallbackFonts));
      expect(dark.textTheme.titleMedium?.fontFamilyFallback, equals(AppTypography.fallbackFonts));
    });

    test('uiStyle and decorativeStyle static helpers have fallbackFonts', () {
      expect(AppTypography.uiStyle.fontFamilyFallback, equals(AppTypography.fallbackFonts));
      expect(AppTypography.decorativeStyle.fontFamilyFallback, equals(AppTypography.fallbackFonts));
    });

    testWidgets('Renders emojis and Islamic ligatures under AppTheme without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              children: [
                Text('مساء الخير والسكينة 🌙', style: AppTypography.uiStyle),
                Text('طابت أوقاتكم بذكر الله 🌤️', style: AppTypography.uiStyle),
                Text('صباح الخير والبركة ☀️', style: AppTypography.uiStyle),
                Text('قال رسول الله ﷺ', style: AppTypography.uiStyle),
                Text('الله جل جلاله ﷻ', style: AppTypography.uiStyle),
                Text('🕌 📿 🕋 🤲', style: AppTypography.uiStyle),
              ],
            ),
          ),
        ),
      );

      expect(find.text('مساء الخير والسكينة 🌙'), findsOneWidget);
      expect(find.text('طابت أوقاتكم بذكر الله 🌤️'), findsOneWidget);
      expect(find.text('صباح الخير والبركة ☀️'), findsOneWidget);
      expect(find.text('قال رسول الله ﷺ'), findsOneWidget);
      expect(find.text('الله جل جلاله ﷻ'), findsOneWidget);
      expect(find.text('🕌 📿 🕋 🤲'), findsOneWidget);
    });
  });
}
