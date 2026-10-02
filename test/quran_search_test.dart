import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/features/quran/presentation/views/quran_search_view.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Quran Search Engine Unit Tests', () {
    late Database db;
    late QuranRepository quranRepo;

    setUp(() async {
      final dbPath = File('assets/db/app_data.db').absolute.path;
      db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      AppDatabase.customDatabaseForTesting = db;
      quranRepo = QuranRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.customDatabaseForTesting = null;
    });

    test('searchAyahs finds matches across 6236 ayahs (with dagger-alef variants)', () async {
      final results = await quranRepo.searchAyahs('الصابرين');
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.textAr, isNotEmpty);
        expect(r.pageNumber, isNotNull);
        expect(r.surahId, inInclusiveRange(1, 114));
      }
    });

    test('searchAyahs with surahId limits search to that specific surah', () async {
      // Search 'الرحمن' in Al-Fatihah (surah_id = 1)
      final resultsFatihah = await quranRepo.searchAyahs('الرحمن', surahId: 1);
      expect(resultsFatihah, isNotEmpty);
      for (final r in resultsFatihah) {
        expect(r.surahId, 1);
      }

      // Search 'الرحمن' in Al-Ikhlas (surah_id = 112, should be empty)
      final resultsIkhlas = await quranRepo.searchAyahs('الرحمن', surahId: 112);
      expect(resultsIkhlas, isEmpty);
    });

    test('searchAyahs respects limit parameter', () async {
      final results = await quranRepo.searchAyahs('الله', limit: 10);
      expect(results.length, 10);
    });

    test('searchAyahs returns empty on empty query', () async {
      final results = await quranRepo.searchAyahs('   ');
      expect(results, isEmpty);
    });
  });

  group('QuranSearchView Widget Tests', () {
    late Database db;

    setUp(() async {
      final dbPath = File('assets/db/app_data.db').absolute.path;
      db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      AppDatabase.customDatabaseForTesting = db;
    });

    tearDown(() async {
      await db.close();
      AppDatabase.customDatabaseForTesting = null;
    });

    testWidgets('renders search input, filter chips and initial suggestions', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const QuranSearchView(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify search input is present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ابحث بالكلمة أو الآية في المصحف...'), findsOneWidget);

      // Verify filter chip is present
      expect(find.text('كل السور (114)'), findsOneWidget);

      // Verify quick suggestions are displayed
      expect(find.text('البحث في القرآن الكريم'), findsOneWidget);
      expect(find.text('إن الله مع الصابرين'), findsOneWidget);
    });

    testWidgets('tapping a suggestion populates input and triggers search', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const QuranSearchView(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap suggestion chip
      await tester.tap(find.text('إن الله مع الصابرين'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // Check results or text field populated
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'إن الله مع الصابرين');

      // Flush sqflite internal 10-second lock monitor timer
      await tester.pump(const Duration(seconds: 11));
    });
  });
}
