import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/data/models/mushaf_models.dart';
import 'package:quran_app_android/features/mushaf/presentation/models/mushaf_theme_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';
import 'package:quran_app_android/features/mushaf/presentation/widgets/mushaf_line_widget.dart';
import 'package:quran_app_android/features/mushaf/presentation/widgets/mushaf_page_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mushaf Theme & Models Tests', () {
    test('MushafThemeMode fromString parses correctly', () {
      expect(MushafThemeMode.fromString('light'), MushafThemeMode.light);
      expect(MushafThemeMode.fromString('dark'), MushafThemeMode.dark);
      expect(MushafThemeMode.fromString('readingNight'), MushafThemeMode.readingNight);
      expect(MushafThemeMode.fromString('unknown'), MushafThemeMode.light);
      expect(MushafThemeMode.fromString(null), MushafThemeMode.light);
    });

    test('MushafThemeConfig provides distinct palettes for all three themes', () {
      final light = MushafThemeConfig.of(MushafThemeMode.light);
      final dark = MushafThemeConfig.of(MushafThemeMode.dark);
      final night = MushafThemeConfig.of(MushafThemeMode.readingNight);

      expect(light.pageBg, const Color(0xFFFAF6EC));
      expect(dark.pageBg, const Color(0xFF0E1512));
      expect(night.pageBg, const Color(0xFF14110D));

      expect(light.textColor, isNot(equals(dark.textColor)));
      expect(night.textColor, isNot(equals(dark.textColor)));
    });
  });

  group('Mushaf Utilities Tests', () {
    test('toArabicDigits converts integers to Eastern Arabic numerals accurately', () {
      expect(toArabicDigits(1), '١');
      expect(toArabicDigits(15), '١٥');
      expect(toArabicDigits(604), '٦٠٤');
      expect(toArabicDigits(0), '٠');
    });

    test('calculateHizbNumber computes 1..60 correctly across pages', () {
      expect(calculateHizbNumber(1, 1), 1);
      expect(calculateHizbNumber(10, 1), 1);
      expect(calculateHizbNumber(11, 1), 2);
      expect(calculateHizbNumber(21, 2), 3);
      expect(calculateHizbNumber(604, 30), 60);
    });

    test('getJuzNameArabic returns traditional Arabic names', () {
      expect(getJuzNameArabic(1), 'الأول');
      expect(getJuzNameArabic(30), 'الثلاثون');
    });
  });

  group('Mushaf Line & Page Widget Tests', () {
    final theme = MushafThemeConfig.light;

    testWidgets('MushafLineWidget renders Surah Header line with title', (tester) async {
      const line = MushafLine(
        id: 1,
        pageNumber: 1,
        lineNumber: 1,
        lineType: MushafLineType.surahHeader,
        surahNumber: 1,
        text: 'سورة الفاتحة',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafLineWidget(
              line: line,
              pageNumber: 1,
              theme: theme,
            ),
          ),
        ),
      );

      expect(find.textContaining('الفاتحة'), findsOneWidget);
    });

    testWidgets('MushafLineWidget renders Basmalah line centered', (tester) async {
      const line = MushafLine(
        id: 2,
        pageNumber: 1,
        lineNumber: 2,
        lineType: MushafLineType.basmalah,
        text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafLineWidget(
              line: line,
              pageNumber: 1,
              theme: theme,
            ),
          ),
        ),
      );

      expect(find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'), findsOneWidget);
    });

    testWidgets('MushafLineWidget triggers onAyahTapped on word tap', (tester) async {
      int? tappedSurah;
      int? tappedAyah;

      const word = MushafWord(
        pageNumber: 3,
        lineNumber: 2,
        wordIndex: 1,
        surahNumber: 2,
        ayahNumber: 6,
        location: '2:6:1',
        textUthmani: 'إِنَّ',
        glyphCode: 'ﭑ',
      );

      const line = MushafLine(
        id: 3,
        pageNumber: 3,
        lineNumber: 2,
        lineType: MushafLineType.ayah,
        words: [word],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafLineWidget(
              line: line,
              pageNumber: 3,
              theme: theme,
              onAyahTapped: (s, a) {
                tappedSurah = s;
                tappedAyah = a;
              },
            ),
          ),
        ),
      );

      expect(find.text('ﭑ'), findsOneWidget);
      await tester.tap(find.text('ﭑ'));
      await tester.pump();

      expect(tappedSurah, 2);
      expect(tappedAyah, 6);
    });

    testWidgets('MushafPageWidget renders header, footer and lines', (tester) async {
      final lines = List.generate(
        15,
        (i) => MushafLine(
          id: i + 1,
          pageNumber: 3,
          lineNumber: i + 1,
          lineType: MushafLineType.ayah,
          text: 'خط سطر $i',
          words: [
            MushafWord(
              pageNumber: 3,
              lineNumber: i + 1,
              wordIndex: 1,
              surahNumber: 2,
              ayahNumber: i + 1,
              location: '2:${i + 1}:1',
              textUthmani: 'كلمة',
              glyphCode: 'ﭑ',
            ),
          ],
        ),
      );

      final page = MushafPage(
        pageNumber: 3,
        lines: lines,
        surahNumber: 2,
        surahNameAr: 'البقرة',
        juzNumber: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPageWidget(
              page: page,
              theme: theme,
            ),
          ),
        ),
      );

      // Verify Surah name in header
      expect(find.textContaining('البقرة'), findsOneWidget);
      // Verify Footer contains Arabic page number (٣)
      expect(find.textContaining('٣'), findsOneWidget);
    });
  });
}
