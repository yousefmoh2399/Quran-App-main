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

  group('SQLite Repositories Unit Tests', () {
    late Database db;
    late QuranRepository quranRepo;
    late HadithRepository hadithRepo;
    late AzkarRepository azkarRepo;
    late NamesRepository namesRepo;

    setUp(() async {
      final dbPath = File('assets/db/app_data.db').absolute.path;
      db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      AppDatabase.customDatabaseForTesting = db;

      quranRepo = QuranRepository();
      hadithRepo = HadithRepository();
      azkarRepo = AzkarRepository();
      namesRepo = NamesRepository();
    });

    tearDown(() async {
      await db.close();
      AppDatabase.customDatabaseForTesting = null;
    });

    test('QuranRepository: verify exactly 114 surahs and 6236 total ayahs', () async {
      final surahs = await quranRepo.getSurahs();
      expect(surahs.length, 114);
      expect(surahs.first.nameAr, 'الفاتحة');
      expect(surahs.last.nameAr, 'الناس');

      // Verify total verses count in table equals 6236
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM ayahs;');
      final totalAyahs = Sqflite.firstIntValue(res);
      expect(totalAyahs, 6236);

      // Verify Al-Fatihah has 7 verses
      final fatihahAyahs = await quranRepo.getAyahs(1);
      expect(fatihahAyahs.length, 7);
      expect(fatihahAyahs.first.textAr, contains('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ'));

      // Verify Al-Baqarah has 286 verses
      final baqarahAyahs = await quranRepo.getAyahs(2);
      expect(baqarahAyahs.length, 286);

      // Verify page_number column exists and is nullable (empty for now)
      expect(fatihahAyahs.first.pageNumber, isNull);
    });

    test('QuranRepository: verify Tafsir retrieval', () async {
      final tafsir = await quranRepo.getTafsir(1, 1);
      expect(tafsir, isNotNull);
      expect(tafsir, isNotEmpty);
      expect(tafsir, contains('الفاتحة'));
    });

    test('QuranRepository: searchAyahs returns relevant results with Arabic normalization', () async {
      // Search for 'الرحمن' without tashkeel
      final searchResults = await quranRepo.searchAyahs('الرحمن');
      expect(searchResults, isNotEmpty);
      // Al-Fatihah ayah 1 or 3 should match
      final matchFatihah = searchResults.any((a) => a.surahId == 1);
      expect(matchFatihah, isTrue);

      // Search for 'الله' with different alef form
      final allahResults = await quranRepo.searchAyahs('إله');
      expect(allahResults, isNotEmpty);
    });

    test('HadithRepository: verify 61 sections and exactly 1840 hadiths', () async {
      final sections = await hadithRepo.getSections();
      expect(sections.length, 61);
      expect(sections.first.source, 'Muwatta Malik');
      expect(sections.first.name, 'أوقات الصلاة');

      final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM hadiths;');
      final totalHadiths = Sqflite.firstIntValue(countRes);
      expect(totalHadiths, 1840);

      // Verify section 1 has 31 hadiths
      final section1Hadiths = await hadithRepo.getHadithsBySection(1);
      expect(section1Hadiths.length, 31);
      expect(section1Hadiths.first.grade, contains('Sahih'));

      // Test search
      final searchResults = await hadithRepo.searchHadiths('الصلاة');
      expect(searchResults, isNotEmpty);
    });

    test('AzkarRepository: verify 132 categories and exactly 267 azkar items', () async {
      final categories = await azkarRepo.getCategories();
      expect(categories.length, 132);

      final countRes = await db.rawQuery('SELECT COUNT(*) as count FROM azkar;');
      final totalAzkar = Sqflite.firstIntValue(countRes);
      expect(totalAzkar, 267);

      // Verify morning/evening azkar
      final morningAzkar = await azkarRepo.getAzkarByCategory(1);
      expect(morningAzkar, isNotEmpty);
      expect(morningAzkar.first.textAr, contains('اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ'));

      // Verify audio field is preserved
      expect(morningAzkar.first.audio, isNotNull);

      // Test search
      final searchResults = await azkarRepo.searchAzkar('الحمد');
      expect(searchResults, isNotEmpty);
    });

    test('NamesRepository: verify exactly 99 Names of Allah with split names', () async {
      final names = await namesRepo.getNames();
      expect(names.length, 99);

      // Verify split of "المعطي المانع"
      final moati = names.firstWhere((n) => n.name.contains('المعطي') || n.name.contains('الْمُعْطِي'));
      final mane = names.firstWhere((n) => n.name.contains('المانع') || n.name.contains('الْمَانِعُ'));
      expect(moati.id, isNot(equals(mane.id)));
      expect(moati.text, contains('العطاء'));
      expect(mane.text, contains('يمنع'));

      // Verify split of "الضار النافع"
      final daar = names.firstWhere((n) => n.name.contains('الضار') || n.name.contains('الضَّارُّ'));
      final nafe = names.firstWhere((n) => n.name.contains('النافع') || n.name.contains('النَّافِعُ'));
      expect(daar.id, isNot(equals(nafe.id)));
      expect(daar.text, contains('ضر'));
      expect(nafe.text, contains('نفع'));
    });
  });
}
