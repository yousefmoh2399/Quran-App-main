import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/features/tafsser/data/tafsir_repository.dart';

/// Custom HttpOverrides that strictly prevents any network access.
/// If any code attempts to open an HTTP connection, an exception is thrown.
class StrictNoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('STRICT NETWORK GUARD: Prohibited network call attempted!');
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Set strict network guard
    HttpOverrides.global = StrictNoNetworkHttpOverrides();
  });

  group('Offline-First & Tafsir 6236 Verification Tests', () {
    late Database db;
    late QuranRepository quranRepo;
    late HadithRepository hadithRepo;
    late AzkarRepository azkarRepo;
    late NamesRepository namesRepo;
    late TafsirRepository tafsirRepo;

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
      tafsirRepo = TafsirRepository.instance;
    });

    tearDown(() async {
      await db.close();
      AppDatabase.customDatabaseForTesting = null;
    });

    test('Strict Network Guard: Repositories make ZERO network requests', () async {
      // Under StrictNoNetworkHttpOverrides, any network call immediately throws.
      // 1. Quran
      final surahs = await quranRepo.getSurahs();
      expect(surahs.length, 114);
      final ayahs = await quranRepo.getAyahs(1);
      expect(ayahs.length, 7);

      // 2. Hadith
      final sections = await hadithRepo.getSections();
      expect(sections, isNotEmpty);

      // 3. Azkar
      final categories = await azkarRepo.getCategories();
      expect(categories, isNotEmpty);

      // 4. Names of Allah
      final names = await namesRepo.getNames();
      expect(names.length, 99);

      // 5. Tafsir for all 3 sources
      final muyassar = await tafsirRepo.getAyahTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        source: TafsirSource.muyassar,
      );
      expect(muyassar, isNotEmpty);
      expect(muyassar, isNot('التفسير غير متوفر حالياً'));

      final saadi = await tafsirRepo.getAyahTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        source: TafsirSource.saadi,
      );
      expect(saadi, isNotEmpty);
      expect(saadi, isNot('التفسير غير متوفر حالياً'));

      final ibnKathir = await tafsirRepo.getAyahTafsir(
        surahNumber: 1,
        ayahNumber: 1,
        source: TafsirSource.ibnKathir,
      );
      expect(ibnKathir, isNotEmpty);
      expect(ibnKathir, isNot('التفسير غير متوفر حالياً'));
    });

    test('Database contains exactly 6236 non-empty verses for each Tafsir source', () async {
      // 1. Total ayahs count
      final totalRes = await db.rawQuery('SELECT COUNT(*) as c FROM ayahs;');
      final totalAyahs = Sqflite.firstIntValue(totalRes) ?? 0;
      expect(totalAyahs, 6236, reason: 'Quran must have exactly 6236 ayahs');

      // 2. Tafsir Al-Muyassar
      final muyassarRes = await db.rawQuery(
        "SELECT COUNT(*) as c FROM ayahs WHERE tafsir_muyassar IS NOT NULL AND trim(tafsir_muyassar) != '';",
      );
      final muyassarCount = Sqflite.firstIntValue(muyassarRes) ?? 0;
      expect(muyassarCount, 6236, reason: 'Tafsir Muyassar must cover all 6236 ayahs with 0 empty');

      // 3. Tafsir Al-Saadi
      final saadiRes = await db.rawQuery(
        "SELECT COUNT(*) as c FROM ayahs WHERE tafsir_saadi IS NOT NULL AND trim(tafsir_saadi) != '';",
      );
      final saadiCount = Sqflite.firstIntValue(saadiRes) ?? 0;
      expect(saadiCount, 6236, reason: 'Tafsir Al-Saadi must cover all 6236 ayahs with 0 empty');

      // 4. Tafsir Ibn Kathir
      final ibnKathirRes = await db.rawQuery(
        "SELECT COUNT(*) as c FROM ayahs WHERE tafsir_ibn_kathir IS NOT NULL AND trim(tafsir_ibn_kathir) != '';",
      );
      final ibnKathirCount = Sqflite.firstIntValue(ibnKathirRes) ?? 0;
      expect(ibnKathirCount, 6236, reason: 'Tafsir Ibn Kathir must cover all 6236 ayahs with 0 empty');

      // 5. Zero empty check
      final emptyCheck = await db.rawQuery('''
        SELECT COUNT(*) as c FROM ayahs 
        WHERE tafsir_muyassar IS NULL OR trim(tafsir_muyassar) = ''
           OR tafsir_saadi IS NULL OR trim(tafsir_saadi) = ''
           OR tafsir_ibn_kathir IS NULL OR trim(tafsir_ibn_kathir) = '';
      ''');
      final emptyTotal = Sqflite.firstIntValue(emptyCheck) ?? 0;
      expect(emptyTotal, 0, reason: 'There must be zero empty or missing tafsir entries');
    });

    test('Boundary and grouped verses return valid tafsirs for all sources', () async {
      final testCases = [
        (1, 1),   // First ayah of Quran
        (2, 286), // Last ayah of Al-Baqarah (previously grouped)
        (5, 97),  // Previously grouped in Ibn Kathir
        (114, 6), // Last ayah of Quran
      ];

      for (final (surah, ayah) in testCases) {
        for (final source in TafsirSource.values) {
          final text = await tafsirRepo.getAyahTafsir(
            surahNumber: surah,
            ayahNumber: ayah,
            source: source,
          );
          expect(text, isNotEmpty, reason: 'Ayah $surah:$ayah must have non-empty ${source.title}');
          expect(text, isNot('التفسير غير متوفر حالياً'),
              reason: 'Ayah $surah:$ayah must not return fallback message');
        }
      }
    });
  });
}
