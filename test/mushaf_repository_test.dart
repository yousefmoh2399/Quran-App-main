import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/core/data/data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MushafRepository Unit Tests', () {
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

    test('getPage: returns 15 lines for standard pages (e.g. page 3, page 77)', () async {
      final page3 = await mushafRepo.getPage(3);
      expect(page3.pageNumber, 3);
      expect(page3.lines.length, 15);
      expect(page3.surahNameAr, contains('البقرة'));
      expect(page3.juzNumber, 1);
      // All lines have valid words or content
      expect(page3.lines.first.words, isNotEmpty);
      expect(page3.lines.first.words.first.glyphCode, isNotEmpty);

      final page77 = await mushafRepo.getPage(77);
      expect(page77.pageNumber, 77);
      expect(page77.lines.length, 15);
      expect(page77.surahNameAr, contains('النساء'));
      expect(page77.juzNumber, 4);
      // First line of page 77 is Basmalah
      expect(page77.lines.first.lineType, MushafLineType.basmalah);
    });

    test('getPage: returns lines for page 1 and page 2', () async {
      final page1 = await mushafRepo.getPage(1);
      expect(page1.pageNumber, 1);
      expect(page1.surahNameAr, contains('الفاتحة'));
      expect(page1.lines.first.lineType, MushafLineType.surahHeader);

      final page2 = await mushafRepo.getPage(2);
      expect(page2.pageNumber, 2);
      expect(page2.surahNameAr, contains('البقرة'));
      expect(page2.lines.first.lineType, MushafLineType.surahHeader);
      expect(page2.lines[1].lineType, MushafLineType.basmalah);
    });

    test('getPageOfAyah: correctly locates pages across surahs', () async {
      // Al-Fatihah v1 is on page 1
      expect(await mushafRepo.getPageOfAyah(1, 1), 1);
      // Al-Baqarah v1 is on page 2
      expect(await mushafRepo.getPageOfAyah(2, 1), 2);
      // Al-Baqarah v286 is on page 49
      expect(await mushafRepo.getPageOfAyah(2, 286), 49);
      // An-Nisa v1 is on page 77
      expect(await mushafRepo.getPageOfAyah(4, 1), 77);
      // An-Nas v6 is on page 604
      expect(await mushafRepo.getPageOfAyah(114, 6), 604);
    });

    test('getSurahStart: returns exact starting page for surahs', () async {
      expect(await mushafRepo.getSurahStart(1), 1);
      expect(await mushafRepo.getSurahStart(2), 2);
      expect(await mushafRepo.getSurahStart(3), 50);
      expect(await mushafRepo.getSurahStart(4), 77);
      expect(await mushafRepo.getSurahStart(114), 604);
    });

    test('getJuzStart: returns exact starting page for all 30 ajza', () async {
      final ajza = await mushafRepo.getAjza();
      expect(ajza.length, 30);
      expect(ajza.first.startPage, 1);
      expect(ajza[1].startPage, 22);
      expect(ajza.last.startPage, 582);

      expect(await mushafRepo.getJuzStart(1), 1);
      expect(await mushafRepo.getJuzStart(2), 22);
      expect(await mushafRepo.getJuzStart(30), 582);
    });

    test('getSajdahs: returns exactly 15 sajdahs', () async {
      final sajdahs = await mushafRepo.getSajdahs();
      expect(sajdahs.length, 15);
      expect(sajdahs.first.surahNumber, 7);
      expect(sajdahs.first.ayahNumber, 206);
      expect(sajdahs.last.surahNumber, 96);
      expect(sajdahs.last.ayahNumber, 19);
    });

    test('searchAyahs: finds normalized verses accurately', () async {
      final results = await mushafRepo.searchAyahs('الله لا اله الا هو الحي القيوم');
      expect(results, isNotEmpty);
      expect(results.any((a) => a.surahId == 2 && a.ayahNumber == 255), isTrue);
    });
  });
}
