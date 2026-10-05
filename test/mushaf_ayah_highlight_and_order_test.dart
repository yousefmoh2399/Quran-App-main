import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/core/data/app_database.dart';
import 'package:quran_app_android/core/data/models/mushaf_models.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/mushaf_repository.dart';
import 'package:quran_app_android/features/mushaf/presentation/models/mushaf_theme_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/widgets/mushaf_line_widget.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Ayah Selection & Line Words Ordering Tests', () {
    late Database db;
    late MushafRepository mushafRepo;

    setUp(() async {
      final dbPath = File('assets/db/app_data.db').absolute.path;
      db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      AppDatabase.customDatabaseForTesting = db;
      mushafRepo = MushafRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.customDatabaseForTesting = null;
    });

    test('getPage: words on multi-ayah lines are strictly ordered in Quranic reading sequence', () async {
      final page2 = await mushafRepo.getPage(2);
      // Line 4 contains the end of Ayah 2 (للمتقين ٢) followed by the start of Ayah 3 (الذين يؤمنون بالغيب...)
      final line4 = page2.lines.firstWhere((l) => l.lineNumber == 4);
      expect(line4.words, isNotEmpty);

      // The first word on Line 4 MUST be from Ayah 2 (للمتقين ٢)
      final firstWord = line4.words.first;
      expect(firstWord.surahNumber, 2);
      expect(firstWord.ayahNumber, 2);
      expect(firstWord.textUthmani, contains('لِّلْمُتَّقِينَ'));

      // The subsequent words on Line 4 MUST be from Ayah 3 (الذين...)
      final secondWord = line4.words[1];
      expect(secondWord.surahNumber, 2);
      expect(secondWord.ayahNumber, 3);
      expect(secondWord.textUthmani, contains('ٱلَّذِينَ'));

      final lastWord = line4.words.last;
      expect(lastWord.surahNumber, 2);
      expect(lastWord.ayahNumber, 3);
      expect(lastWord.textUthmani, contains('ٱلصَّلَوٰةَ'));
    });

    test('getPage: short surahs on Page 604 preserve flawless word order on shared lines', () async {
      final page604 = await mushafRepo.getPage(604);
      // Line 3 of Page 604 has Ayah 1 (قل هو الله أحد ١) and Ayah 2 (الله الصمد ٢) and Ayah 3 (لم يلد)
      final line3 = page604.lines.firstWhere((l) => l.lineNumber == 3);
      expect(line3.words.first.surahNumber, 112);
      expect(line3.words.first.ayahNumber, 1);
      expect(line3.words.first.textUthmani, 'قُلْ');

      // Check monotonically non-decreasing ayah numbers along the line
      for (int i = 0; i < line3.words.length - 1; i++) {
        final current = line3.words[i];
        final next = line3.words[i + 1];
        if (current.surahNumber == next.surahNumber) {
          expect(current.ayahNumber <= next.ayahNumber, isTrue,
              reason: 'Ayah numbers must never decrease on a line: ${current.textUthmani} vs ${next.textUthmani}');
        }
      }
    });
  });

  group('MushafLineWidget Ayah Highlighting & Color Accuracy Widget Tests', () {
    final theme = MushafThemeConfig.of(MushafThemeMode.light);

    // Create a mock line with 2 ayahs: Ayah 2 (2 words) and Ayah 3 (3 words)
    final mockLine = MushafLine(
      id: 1,
      pageNumber: 2,
      lineNumber: 4,
      lineType: MushafLineType.ayah,
      words: const [
        MushafWord(
          pageNumber: 2,
          lineNumber: 4,
          wordIndex: 7,
          surahNumber: 2,
          ayahNumber: 2,
          location: '2:2:7',
          textUthmani: 'لِّلْمُتَّقِينَ ٢',
          glyphCode: 'ﱋ',
        ),
        MushafWord(
          pageNumber: 2,
          lineNumber: 4,
          wordIndex: 1,
          surahNumber: 2,
          ayahNumber: 3,
          location: '2:3:1',
          textUthmani: 'ٱلَّذِينَ',
          glyphCode: 'ﱍ',
        ),
        MushafWord(
          pageNumber: 2,
          lineNumber: 4,
          wordIndex: 2,
          surahNumber: 2,
          ayahNumber: 3,
          location: '2:3:2',
          textUthmani: 'يُؤْمِنُونَ',
          glyphCode: 'ﱎ',
        ),
        MushafWord(
          pageNumber: 2,
          lineNumber: 4,
          wordIndex: 3,
          surahNumber: 2,
          ayahNumber: 3,
          location: '2:3:3',
          textUthmani: 'بِٱلْغَيْبِ',
          glyphCode: 'ﱏ',
        ),
      ],
    );

    testWidgets('accurately highlights ONLY the selected ayah words and applies ruby color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafLineWidget(
              line: mockLine,
              pageNumber: 2,
              theme: theme,
              selectedSurah: 2,
              selectedAyah: 3,
              selectedAyahColor: BookmarkColor.ruby,
            ),
          ),
        ),
      );

      // Verify that words of Ayah 3 have ruby-tinted background, while Ayah 2 has transparent background
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();

      // Find containers with decoration
      final styledContainers = containers.where((c) => c.decoration is BoxDecoration).toList();
      expect(styledContainers.length, 4);

      // Container 0 (Ayah 2 word): transparent background
      final ayah2Box = styledContainers[0].decoration as BoxDecoration;
      expect(ayah2Box.color, Colors.transparent);

      // Containers 1, 2, 3 (Ayah 3 words): ruby background with opacity
      final rubyColor = BookmarkColor.ruby.color;
      final ayah3Word1Box = styledContainers[1].decoration as BoxDecoration;
      expect(ayah3Word1Box.color, rubyColor.withOpacity(0.30));

      final ayah3Word2Box = styledContainers[2].decoration as BoxDecoration;
      expect(ayah3Word2Box.color, rubyColor.withOpacity(0.30));

      final ayah3Word3Box = styledContainers[3].decoration as BoxDecoration;
      expect(ayah3Word3Box.color, rubyColor.withOpacity(0.30));

      // Check contiguous borders:
      // Word 1 (first of Ayah 3 in line -> right end in RTL): has right border and topRight/bottomRight radius
      final r1 = ayah3Word1Box.borderRadius as BorderRadius?;
      expect(r1?.topRight, const Radius.circular(4.0));
      expect(r1?.topLeft, Radius.zero);

      // Word 2 (middle of Ayah 3): flat on both sides
      final r2 = ayah3Word2Box.borderRadius as BorderRadius?;
      expect(r2, BorderRadius.zero);

      // Word 3 (last of Ayah 3 in line -> left end in RTL): has left border and topLeft/bottomLeft radius
      final r3 = ayah3Word3Box.borderRadius as BorderRadius?;
      expect(r3?.topLeft, const Radius.circular(4.0));
      expect(r3?.topRight, Radius.zero);
    });

    testWidgets('applies saved bookmark color when ayah is bookmarked in blue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafLineWidget(
              line: mockLine,
              pageNumber: 2,
              theme: theme,
              bookmarkedAyahs: const {
                '2:2': BookmarkColor.blue,
              },
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final styledContainers = containers.where((c) => c.decoration is BoxDecoration).toList();

      // Ayah 2 word should be styled with blue bookmark color
      final ayah2Box = styledContainers[0].decoration as BoxDecoration;
      expect(ayah2Box.color, BookmarkColor.blue.color.withOpacity(0.22));

      // Ayah 3 words should be transparent
      final ayah3Word1Box = styledContainers[1].decoration as BoxDecoration;
      expect(ayah3Word1Box.color, Colors.transparent);
    });
  });
}
