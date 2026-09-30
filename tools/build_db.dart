// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';

String normalizeArabic(String text) {
  return text
      // Remove diacritics / tashkeel
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      // Remove Quranic annotation signs
      .replaceAll(RegExp(r'[\u0610-\u061A\u06D6-\u06ED]'), '')
      // Normalize Alef variants
      .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
      // Normalize Yaa
      .replaceAll('ى', 'ي')
      // Normalize Taa Marbuta
      .replaceAll('ة', 'ه')
      // Normalize Tatweel
      .replaceAll('ـ', '')
      // Replace non-breaking space
      .replaceAll('\u00A0', ' ')
      .trim();
}

void main() {
  final stopwatch = Stopwatch()..start();
  print('========================================');
  print('Building SQLite database: app_data.db');
  print('========================================');

  final dbDir = Directory('assets/db');
  if (!dbDir.existsSync()) {
    dbDir.createSync(recursive: true);
  }

  final dbFile = File('assets/db/app_data.db');
  if (dbFile.existsSync()) {
    dbFile.deleteSync();
    print('Deleted existing app_data.db');
  }

  final db = sqlite3.open(dbFile.path);

  // Configure pragmas for performance
  db.execute('PRAGMA journal_mode = WAL;');
  db.execute('PRAGMA synchronous = NORMAL;');
  db.execute('PRAGMA encoding = "UTF-8";');

  // 1. Create Tables
  print('Creating tables and indexes...');
  db.execute('''
    CREATE TABLE metadata (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );

    CREATE TABLE surahs (
      id INTEGER PRIMARY KEY,
      name_ar TEXT NOT NULL,
      name_en TEXT NOT NULL,
      transliteration TEXT NOT NULL,
      type TEXT NOT NULL,
      total_verses INTEGER NOT NULL
    );

    CREATE TABLE ayahs (
      id INTEGER PRIMARY KEY,
      surah_id INTEGER NOT NULL,
      ayah_number INTEGER NOT NULL,
      page_number INTEGER,
      text_ar TEXT NOT NULL,
      text_en TEXT,
      tafsir_muyassar TEXT,
      text_search TEXT NOT NULL,
      FOREIGN KEY (surah_id) REFERENCES surahs (id)
    );

    CREATE TABLE hadith_sections (
      id INTEGER PRIMARY KEY,
      source TEXT NOT NULL,
      name TEXT NOT NULL
    );

    CREATE TABLE hadiths (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      section_id INTEGER NOT NULL,
      source TEXT NOT NULL,
      chapter TEXT NOT NULL,
      hadith_number INTEGER,
      arabic_number INTEGER,
      text_ar TEXT NOT NULL,
      grade TEXT,
      text_search TEXT NOT NULL,
      FOREIGN KEY (section_id) REFERENCES hadith_sections (id)
    );

    CREATE TABLE azkar_categories (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      audio TEXT,
      filename TEXT
    );

    CREATE TABLE azkar (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER NOT NULL,
      category_name TEXT NOT NULL,
      item_id INTEGER,
      text_ar TEXT NOT NULL,
      count INTEGER NOT NULL,
      audio TEXT,
      filename TEXT,
      text_search TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES azkar_categories (id)
    );

    CREATE TABLE names_of_allah (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      text TEXT NOT NULL
    );

    -- Standard Indexes
    CREATE INDEX idx_ayahs_surah_ayah ON ayahs(surah_id, ayah_number);
    CREATE INDEX idx_ayahs_surah ON ayahs(surah_id);
    CREATE INDEX idx_hadiths_section ON hadiths(section_id);
    CREATE INDEX idx_azkar_category ON azkar(category_id);

    -- FTS5 Full-Text Search Virtual Tables
    CREATE VIRTUAL TABLE ayahs_fts USING fts5(
      text_search,
      content='ayahs',
      content_rowid='id'
    );

    CREATE VIRTUAL TABLE hadiths_fts USING fts5(
      text_search,
      content='hadiths',
      content_rowid='id'
    );

    CREATE VIRTUAL TABLE azkar_fts USING fts5(
      text_search,
      content='azkar',
      content_rowid='id'
    );
  ''');

  // Insert metadata
  db.execute("INSERT INTO metadata (key, value) VALUES ('version', '1');");
  db.execute("INSERT INTO metadata (key, value) VALUES ('schema_created_at', '${DateTime.now().toIso8601String()}');");

  // Determine source paths (whether still in assets/ or in tools/source/)
  String resolveSource(String filename) {
    if (File('tools/source/$filename').existsSync()) {
      return 'tools/source/$filename';
    }
    return 'assets/$filename';
  }

  // 2. Populate Surahs
  print('Loading Surahs from name_quran.json...');
  final surahsJsonStr = File(resolveSource('name_quran.json')).readAsStringSync(encoding: utf8);
  final List<dynamic> surahsList = json.decode(surahsJsonStr);

  db.execute('BEGIN TRANSACTION;');
  final insertSurahStmt = db.prepare('''
    INSERT INTO surahs (id, name_ar, name_en, transliteration, type, total_verses)
    VALUES (?, ?, ?, ?, ?, ?);
  ''');
  for (final s in surahsList) {
    insertSurahStmt.execute([
      s['id'],
      s['name'],
      s['translation'] ?? '',
      s['transliteration'] ?? '',
      s['type'] ?? '',
      s['total_verses'],
    ]);
  }
  insertSurahStmt.dispose();
  db.execute('COMMIT;');
  print('Loaded ${surahsList.length} surahs.');

  // 3. Populate Ayahs (from quran_en.json and ar_muyassar.json)
  print('Loading Quran text and Tafsir...');
  final quranEnJsonStr = File(resolveSource('quran_en.json')).readAsStringSync(encoding: utf8);
  final List<dynamic> quranEnList = json.decode(quranEnJsonStr);

  final tafsirJsonStr = File(resolveSource('ar_muyassar.json')).readAsStringSync(encoding: utf8);
  final List<dynamic> tafsirList = json.decode(tafsirJsonStr);

  // Build tafsir lookup: Map<"sura:aya", tafsirText>
  final Map<String, String> tafsirMap = {};
  for (final suraData in tafsirList) {
    final List<dynamic> data = suraData['data'] ?? [];
    for (final item in data) {
      final sura = item['sura'];
      final aya = item['aya'];
      final text = item['text'] as String? ?? '';
      tafsirMap['$sura:$aya'] = text;
    }
  }

  db.execute('BEGIN TRANSACTION;');
  final insertAyahStmt = db.prepare('''
    INSERT INTO ayahs (id, surah_id, ayah_number, page_number, text_ar, text_en, tafsir_muyassar, text_search)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?);
  ''');
  final insertAyahFtsStmt = db.prepare('''
    INSERT INTO ayahs_fts (rowid, text_search)
    VALUES (?, ?);
  ''');

  int globalAyahId = 0;
  for (final surahObj in quranEnList) {
    final int surahId = surahObj['id'];
    final List<dynamic> verses = surahObj['verses'];

    for (final v in verses) {
      globalAyahId++;
      final int ayahNum = v['id'];
      final String textAr = v['text'] as String;
      final String textEn = v['translation'] as String? ?? '';
      final String tafsir = tafsirMap['$surahId:$ayahNum'] ?? '';
      final String textSearch = normalizeArabic(textAr);

      insertAyahStmt.execute([
        globalAyahId,
        surahId,
        ayahNum,
        null, // page_number left NULL for Quran mushaf phase
        textAr,
        textEn,
        tafsir,
        textSearch,
      ]);

      insertAyahFtsStmt.execute([globalAyahId, textSearch]);
    }
  }
  insertAyahStmt.dispose();
  insertAyahFtsStmt.dispose();
  db.execute('COMMIT;');
  print('Loaded $globalAyahId ayahs (Total verses).');

  // 4. Populate Hadiths
  print('Loading Hadith from hadith.json...');
  String hadithPath;
  if (File('tools/source/hadith.json').existsSync()) {
    hadithPath = 'tools/source/hadith.json';
  } else if (File('assets/sections/hadith.json').existsSync()) {
    hadithPath = 'assets/sections/hadith.json';
  } else {
    hadithPath = resolveSource('hadith.json');
  }

  final hadithJsonStr = File(hadithPath).readAsStringSync(encoding: utf8);
  final List<dynamic> hadithSections = json.decode(hadithJsonStr);

  db.execute('BEGIN TRANSACTION;');
  final insertHadithSectionStmt = db.prepare('''
    INSERT INTO hadith_sections (id, source, name)
    VALUES (?, ?, ?);
  ''');

  final insertHadithStmt = db.prepare('''
    INSERT INTO hadiths (section_id, source, chapter, hadith_number, arabic_number, text_ar, grade, text_search)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?);
  ''');

  final insertHadithFtsStmt = db.prepare('''
    INSERT INTO hadiths_fts (rowid, text_search)
    VALUES (?, ?);
  ''');

  int totalHadiths = 0;
  for (final sectionObj in hadithSections) {
    final int secId = sectionObj['id'];
    final Map<String, dynamic> data = sectionObj['data'] ?? {};
    final Map<String, dynamic> metadata = data['metadata'] ?? {};
    final String source = metadata['name'] ?? 'Muwatta Malik';
    final Map<String, dynamic> sectionMeta = metadata['section'] ?? {};
    final String chapterName = sectionMeta['name'] ?? '';

    insertHadithSectionStmt.execute([secId, source, chapterName]);

    final List<dynamic> hadithsList = data['hadiths'] ?? [];
    for (final h in hadithsList) {
      final int? hadithNum = h['hadithnumber'];
      final int? arabicNum = h['arabicnumber'];
      final String textAr = h['text'] ?? '';
      
      String? gradeStr;
      if (h['grades'] is List && (h['grades'] as List).isNotEmpty) {
        final gradesList = h['grades'] as List;
        gradeStr = gradesList.map((g) => "${g['grade']} (${g['name']})").join('; ');
      }

      final String textSearch = normalizeArabic(textAr);

      insertHadithStmt.execute([
        secId,
        source,
        chapterName,
        hadithNum,
        arabicNum,
        textAr,
        gradeStr,
        textSearch,
      ]);

      totalHadiths++;
      final lastRowId = db.lastInsertRowId;
      insertHadithFtsStmt.execute([lastRowId, textSearch]);
    }
  }
  insertHadithSectionStmt.dispose();
  insertHadithStmt.dispose();
  insertHadithFtsStmt.dispose();
  db.execute('COMMIT;');
  print('Loaded ${hadithSections.length} hadith sections and $totalHadiths hadiths.');

  // 5. Populate Azkar
  print('Loading Azkar from azkar.json...');
  final azkarJsonStr = File(resolveSource('azkar.json')).readAsStringSync(encoding: utf8);
  final List<dynamic> azkarCategories = json.decode(azkarJsonStr);

  db.execute('BEGIN TRANSACTION;');
  final insertAzkarCategoryStmt = db.prepare('''
    INSERT INTO azkar_categories (id, name, audio, filename)
    VALUES (?, ?, ?, ?);
  ''');

  final insertAzkarStmt = db.prepare('''
    INSERT INTO azkar (category_id, category_name, item_id, text_ar, count, audio, filename, text_search)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?);
  ''');

  final insertAzkarFtsStmt = db.prepare('''
    INSERT INTO azkar_fts (rowid, text_search)
    VALUES (?, ?);
  ''');

  int totalAzkarItems = 0;
  for (final cat in azkarCategories) {
    final int catId = cat['id'];
    final String catName = cat['category'] ?? '';
    final String? catAudio = cat['audio'];
    final String? catFilename = cat['filename'];

    insertAzkarCategoryStmt.execute([catId, catName, catAudio, catFilename]);

    final List<dynamic> items = cat['array'] ?? [];
    for (final item in items) {
      final int? itemId = item['id'];
      final String textAr = item['text'] ?? '';
      final int count = item['count'] is int ? item['count'] : int.tryParse(item['count']?.toString() ?? '1') ?? 1;
      final String? itemAudio = item['audio'] ?? catAudio;
      final String? itemFilename = item['filename'] ?? catFilename;
      final String textSearch = normalizeArabic(textAr);

      insertAzkarStmt.execute([
        catId,
        catName,
        itemId,
        textAr,
        count,
        itemAudio,
        itemFilename,
        textSearch,
      ]);

      totalAzkarItems++;
      final lastRowId = db.lastInsertRowId;
      insertAzkarFtsStmt.execute([lastRowId, textSearch]);
    }
  }
  insertAzkarCategoryStmt.dispose();
  insertAzkarStmt.dispose();
  insertAzkarFtsStmt.dispose();
  db.execute('COMMIT;');
  print('Loaded ${azkarCategories.length} azkar categories and $totalAzkarItems azkar items.');

  // 6. Populate Names of Allah (with split of 'المعطي المانع' and 'الضار النافع')
  print('Loading Names of Allah from Names_Of_Allah.json...');
  final namesJsonStr = File(resolveSource('Names_Of_Allah.json')).readAsStringSync(encoding: utf8);
  final List<dynamic> rawNamesList = json.decode(namesJsonStr);

  final List<Map<String, String>> processedNames = [];
  for (final item in rawNamesList) {
    final String name = (item['name'] ?? '').toString().trim();
    final String text = (item['text'] ?? '').toString().trim();

    if (name.contains('المانع') && name.contains('المعطي')) {
      // Split 'المعطي المانع'
      processedNames.add({
        'name': 'الْمُعْطِي',
        'text': 'هو الذي أعطى كل شيء خلقه، ويجزل العطاء لمن يشاء من عباده تفضلاً وكرماً وإحساناً.',
      });
      processedNames.add({
        'name': 'الْمَانِعُ',
        'text': 'هو الذي يمنع العطاء عمن يشاء ابتلاءً أو حمايةً، يمنع ما يشاء عمن يشاء بحكمته وعدله.',
      });
    } else if (name.contains('الضار') && name.contains('النافع')) {
      // Split 'الضار النافع'
      processedNames.add({
        'name': 'الضَّارُّ',
        'text': 'هو المقدر للضر على من أراد كيف أراد ابتلاءً أو عقوبةً بمقتضى حكمته وعدله سبحانه.',
      });
      processedNames.add({
        'name': 'النَّافِعُ',
        'text': 'هو المقدر للنفع والخير لمن أراد كيف أراد، المنعم بالخير والبركة على من يشاء سبحانه.',
      });
    } else {
      processedNames.add({
        'name': name,
        'text': text,
      });
    }
  }

  db.execute('BEGIN TRANSACTION;');
  final insertNameStmt = db.prepare('''
    INSERT INTO names_of_allah (id, name, text)
    VALUES (?, ?, ?);
  ''');

  int nameId = 0;
  for (final n in processedNames) {
    nameId++;
    insertNameStmt.execute([nameId, n['name'], n['text']]);
  }
  insertNameStmt.dispose();
  db.execute('COMMIT;');
  print('Loaded $nameId Names of Allah (Target was 99).');

  // Verify and optimize
  print('Running OPTIMIZE and VACUUM...');
  db.execute('PRAGMA optimize;');
  db.execute('VACUUM;');

  db.dispose();
  stopwatch.stop();

  final finalDbSize = dbFile.lengthSync();
  print('========================================');
  print('SUCCESS: Database created at ${dbFile.path}');
  print('Size: ${(finalDbSize / (1024 * 1024)).toStringAsFixed(2)} MB ($finalDbSize bytes)');
  print('Time taken: ${stopwatch.elapsedMilliseconds} ms');
  print('========================================');
}
