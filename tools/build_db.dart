// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String normalizeArabic(String text) {
  if (text.isEmpty) return '';
  var s = text;

  // 1. Convert Uthmanic waw-dagger-alef to Alef (e.g. الصلوة -> الصلاة)
  s = s.replaceAll('و\u0670', 'ا');
  s = s.replaceAll('وٰ', 'ا');

  // 2. Small high Yaa (ۧ) -> ي (e.g. إبرٰهيۧم -> إبراهيم)
  s = s.replaceAll('\u06E7', 'ي');
  // Small high Waw (ۥ) -> و (e.g. داوۥد -> داوود)
  s = s.replaceAll('\u06E5', 'و');

  // 3. Remove diacritics / tashkeel FIRST (fatha, damma, kasra, sukun, shaddah)
  // while keeping dagger-alef (\u0670 / ٰ)
  s = s.replaceAll(RegExp(r'[\u064B-\u065F]'), '');

  // 4. Remove Quranic annotation signs & pause marks
  s = s.replaceAll(RegExp(r'[\u0610-\u061A\u06D6-\u06ED]'), '');

  // 5. Handle words where dagger alef is pronounced but NEVER written in standard Arabic:
  // - Ilah: إلٰه / لٰه -> له
  s = s.replaceAll(RegExp(r'ل[ـ\u0640]?[\u0670ٰ]ه'), 'له');
  // - Demonstrative / Tanbih: هٰذ -> هذ, هٰؤ -> هؤ, ذٰل -> ذل, لٰك -> لك, لٰئ -> لئ
  s = s.replaceAll(RegExp(r'ه[ـ\u0640]?[\u0670ٰ]ذ'), 'هذ');
  s = s.replaceAll(RegExp(r'ه[ـ\u0640]?[\u0670ٰ]ؤ'), 'هؤ');
  s = s.replaceAll(RegExp(r'ذ[ـ\u0640]?[\u0670ٰ]ل'), 'ذل');
  s = s.replaceAll(RegExp(r'ل[ـ\u0640]?[\u0670ٰ]ك'), 'لك');
  s = s.replaceAll(RegExp(r'ل[ـ\u0640]?[\u0670ٰ]ئ'), 'لئ');
  // - Rahman: رحـٰمن -> رحمن
  s = s.replaceAll(RegExp(r'م[ـ\u0640]?[\u0670ٰ]ن'), 'من');

  // 6. Remaining dagger alef (\u0670 / ٰ) -> ا (e.g. إبراهيم, إسماعيل, السماوات, صادقين)
  s = s.replaceAll('\u0670', 'ا');
  s = s.replaceAll('ٰ', 'ا');

  // 7. Normalize Alef variants to bare Alef
  s = s.replaceAll(RegExp(r'[إأآٱ]'), 'ا');

  // 8. Standalone hamza followed by alef: ءا -> ا (ءادم -> ادم, ءامنوا -> امنوا)
  s = s.replaceAll('ءا', 'ا');

  // 9. Normalize Yaa / Alef Maqsura: ى -> ي
  s = s.replaceAll('ى', 'ي');

  // 10. Normalize Taa Marbuta: ة -> ه
  s = s.replaceAll('ة', 'ه');

  // 11. Normalize Tatweel: ـ -> ''
  s = s.replaceAll('ـ', '');

  // 12. Modern common misspellings or phonetics
  s = s.replaceAll('رحمان', 'رحمن');
  s = s.replaceAll('الاه', 'اله');
  s = s.replaceAll('هاذا', 'هذا');
  s = s.replaceAll('هاذه', 'هذه');
  s = s.replaceAll('هاؤلاء', 'هؤلاء');
  s = s.replaceAll('ذالك', 'ذلك');
  s = s.replaceAll('لاكن', 'لكن');

  // 13. Unify whitespaces
  s = s.replaceAll('\u00A0', ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ');

  return s.trim();
}

void main() async {
  final stopwatch = Stopwatch()..start();
  print('========================================');
  print('Building SQLite database: app_data.db');
  print('========================================');

  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;

  final dbDir = Directory('assets/db');
  if (!dbDir.existsSync()) {
    dbDir.createSync(recursive: true);
  }

  final dbFile = File('assets/db/app_data.db');
  if (dbFile.existsSync()) {
    dbFile.deleteSync();
    print('Deleted existing app_data.db');
  }

  final db = await dbFactory.openDatabase(dbFile.absolute.path);

  // Configure pragmas for performance
  await db.execute('PRAGMA journal_mode = WAL;');
  await db.execute('PRAGMA synchronous = NORMAL;');
  await db.execute('PRAGMA encoding = "UTF-8";');

  // 1. Create Tables
  print('Creating tables and indexes...');
  await db.execute('''
    CREATE TABLE metadata (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''');

  await db.execute('''
    CREATE TABLE surahs (
      id INTEGER PRIMARY KEY,
      name_ar TEXT NOT NULL,
      name_en TEXT NOT NULL,
      transliteration TEXT NOT NULL,
      type TEXT NOT NULL,
      total_verses INTEGER NOT NULL
    );
  ''');

  await db.execute('''
    CREATE TABLE ayahs (
      id INTEGER PRIMARY KEY,
      surah_id INTEGER NOT NULL,
      ayah_number INTEGER NOT NULL,
      page_number INTEGER,
      text_ar TEXT NOT NULL,
      text_en TEXT,
      tafsir_muyassar TEXT,
      tafsir_saadi TEXT,
      tafsir_ibn_kathir TEXT,
      text_search TEXT NOT NULL,
      FOREIGN KEY (surah_id) REFERENCES surahs (id)
    );
  ''');

  await db.execute('''
    CREATE TABLE hadith_sections (
      id INTEGER PRIMARY KEY,
      source TEXT NOT NULL,
      name TEXT NOT NULL
    );
  ''');

  await db.execute('''
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
  ''');

  await db.execute('''
    CREATE TABLE azkar_categories (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      audio TEXT,
      filename TEXT
    );
  ''');

  await db.execute('''
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
  ''');

  await db.execute('''
    CREATE TABLE names_of_allah (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      text TEXT NOT NULL
    );
  ''');

  // Standard Indexes
  await db.execute('CREATE INDEX idx_ayahs_surah_ayah ON ayahs(surah_id, ayah_number);');
  await db.execute('CREATE INDEX idx_ayahs_surah ON ayahs(surah_id);');
  await db.execute('CREATE INDEX idx_hadiths_section ON hadiths(section_id);');
  await db.execute('CREATE INDEX idx_azkar_category ON azkar(category_id);');

  // FTS5 Full-Text Search Virtual Tables
  await db.execute('''
    CREATE VIRTUAL TABLE ayahs_fts USING fts5(
      text_search,
      content='ayahs',
      content_rowid='id'
    );
  ''');

  await db.execute('''
    CREATE VIRTUAL TABLE hadiths_fts USING fts5(
      text_search,
      content='hadiths',
      content_rowid='id'
    );
  ''');

  await db.execute('''
    CREATE VIRTUAL TABLE azkar_fts USING fts5(
      text_search,
      content='azkar',
      content_rowid='id'
    );
  ''');

  // Insert metadata
  await db.rawInsert("INSERT INTO metadata (key, value) VALUES ('version', '1');");
  await db.rawInsert("INSERT INTO metadata (key, value) VALUES ('schema_created_at', '${DateTime.now().toIso8601String()}');");

  // Determine source paths (whether in assets/ or in tools/source/)
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

  var batch = db.batch();
  for (final s in surahsList) {
    batch.insert('surahs', {
      'id': s['id'],
      'name_ar': s['name'],
      'name_en': s['translation'] ?? '',
      'transliteration': s['transliteration'] ?? '',
      'type': s['type'] ?? '',
      'total_verses': s['total_verses'],
    });
  }
  await batch.commit(noResult: true);
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

  Map<String, dynamic> saadiMap = {};
  if (File(resolveSource('tafsir_saadi.json')).existsSync()) {
    saadiMap = json.decode(File(resolveSource('tafsir_saadi.json')).readAsStringSync(encoding: utf8));
  }

  Map<String, dynamic> ibnKathirMap = {};
  if (File(resolveSource('tafsir_ibn_kathir.json')).existsSync()) {
    ibnKathirMap = json.decode(File(resolveSource('tafsir_ibn_kathir.json')).readAsStringSync(encoding: utf8));
  }

  batch = db.batch();
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
      final String saadi = saadiMap['$surahId:$ayahNum'] as String? ?? '';
      final String ibnKathir = ibnKathirMap['$surahId:$ayahNum'] as String? ?? '';
      final String textSearch = normalizeArabic(textAr);

      batch.insert('ayahs', {
        'id': globalAyahId,
        'surah_id': surahId,
        'ayah_number': ayahNum,
        'page_number': null,
        'text_ar': textAr,
        'text_en': textEn,
        'tafsir_muyassar': tafsir,
        'tafsir_saadi': saadi,
        'tafsir_ibn_kathir': ibnKathir,
        'text_search': textSearch,
      });

      batch.rawInsert('INSERT INTO ayahs_fts (rowid, text_search) VALUES (?, ?);', [globalAyahId, textSearch]);
    }
  }
  await batch.commit(noResult: true);
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

  batch = db.batch();
  for (final sectionObj in hadithSections) {
    final int secId = sectionObj['id'];
    final Map<String, dynamic> data = sectionObj['data'] ?? {};
    final Map<String, dynamic> metadata = data['metadata'] ?? {};
    final String source = metadata['name'] ?? 'Muwatta Malik';
    final Map<String, dynamic> sectionMeta = metadata['section'] ?? {};
    final String chapterName = sectionMeta['name'] ?? '';

    batch.insert('hadith_sections', {
      'id': secId,
      'source': source,
      'name': chapterName,
    });
  }
  await batch.commit(noResult: true);

  batch = db.batch();
  int totalHadiths = 0;
  for (final sectionObj in hadithSections) {
    final int secId = sectionObj['id'];
    final Map<String, dynamic> data = sectionObj['data'] ?? {};
    final Map<String, dynamic> metadata = data['metadata'] ?? {};
    final String source = metadata['name'] ?? 'Muwatta Malik';
    final Map<String, dynamic> sectionMeta = metadata['section'] ?? {};
    final String chapterName = sectionMeta['name'] ?? '';

    final List<dynamic> hadithsList = data['hadiths'] ?? [];
    for (final h in hadithsList) {
      totalHadiths++;
      final int? hadithNum = h['hadithnumber'];
      final int? arabicNum = h['arabicnumber'];
      final String textAr = h['text'] ?? '';

      String? gradeStr;
      if (h['grades'] is List && (h['grades'] as List).isNotEmpty) {
        final gradesList = h['grades'] as List;
        gradeStr = gradesList.map((g) => "${g['grade']} (${g['name']})").join('; ');
      }

      final String textSearch = normalizeArabic(textAr);

      batch.insert('hadiths', {
        'id': totalHadiths,
        'section_id': secId,
        'source': source,
        'chapter': chapterName,
        'hadith_number': hadithNum,
        'arabic_number': arabicNum,
        'text_ar': textAr,
        'grade': gradeStr,
        'text_search': textSearch,
      });

      batch.rawInsert('INSERT INTO hadiths_fts (rowid, text_search) VALUES (?, ?);', [totalHadiths, textSearch]);
    }
  }
  await batch.commit(noResult: true);
  print('Loaded ${hadithSections.length} hadith sections and $totalHadiths hadiths.');

  // 5. Populate Azkar
  print('Loading Azkar from azkar.json...');
  final azkarJsonStr = File(resolveSource('azkar.json')).readAsStringSync(encoding: utf8);
  final List<dynamic> azkarCategories = json.decode(azkarJsonStr);

  batch = db.batch();
  for (final cat in azkarCategories) {
    batch.insert('azkar_categories', {
      'id': cat['id'],
      'name': cat['category'] ?? '',
      'audio': cat['audio'],
      'filename': cat['filename'],
    });
  }
  await batch.commit(noResult: true);

  batch = db.batch();
  int totalAzkarItems = 0;
  for (final cat in azkarCategories) {
    final int catId = cat['id'];
    final String catName = cat['category'] ?? '';
    final String? catAudio = cat['audio'];
    final String? catFilename = cat['filename'];

    final List<dynamic> items = cat['array'] ?? [];
    for (final item in items) {
      totalAzkarItems++;
      final int? itemId = item['id'];
      final String textAr = item['text'] ?? '';
      final int count = item['count'] is int ? item['count'] : int.tryParse(item['count']?.toString() ?? '1') ?? 1;
      final String? itemAudio = item['audio'] ?? catAudio;
      final String? itemFilename = item['filename'] ?? catFilename;
      final String textSearch = normalizeArabic(textAr);

      batch.insert('azkar', {
        'id': totalAzkarItems,
        'category_id': catId,
        'category_name': catName,
        'item_id': itemId,
        'text_ar': textAr,
        'count': count,
        'audio': itemAudio,
        'filename': itemFilename,
        'text_search': textSearch,
      });

      batch.rawInsert('INSERT INTO azkar_fts (rowid, text_search) VALUES (?, ?);', [totalAzkarItems, textSearch]);
    }
  }
  await batch.commit(noResult: true);
  print('Loaded ${azkarCategories.length} azkar categories and $totalAzkarItems azkar items.');

  // 6. Populate Names of Allah (with split of 'المعطي المانع' and 'الضار النافع' -> exactly 99 names)
  print('Loading Names of Allah from Names_Of_Allah.json...');
  final namesJsonStr = File(resolveSource('Names_Of_Allah.json')).readAsStringSync(encoding: utf8);
  final List<dynamic> rawNamesList = json.decode(namesJsonStr);

  final List<Map<String, String>> processedNames = [];
  for (final item in rawNamesList) {
    final String name = (item['name'] ?? '').toString().trim();
    final String text = (item['text'] ?? '').toString().trim();
    final String normName = normalizeArabic(name);

    if (normName == 'الله') {
      await db.rawInsert("INSERT OR REPLACE INTO metadata (key, value) VALUES ('supreme_name', ?);", [name]);
      await db.rawInsert("INSERT OR REPLACE INTO metadata (key, value) VALUES ('supreme_name_text', ?);", [text]);
      continue;
    }

    if (normName.contains('المانع') && normName.contains('المعطي')) {
      processedNames.add({
        'name': 'الْمُعْطِي',
        'text': 'هو الذي أعطى كل شيء خلقه، ويجزل العطاء لمن يشاء من عباده تفضلاً وكرماً وإحساناً.',
      });
      processedNames.add({
        'name': 'الْمَانِعُ',
        'text': 'هو الذي يمنع العطاء عمن يشاء ابتلاءً أو حمايةً، يمنع ما يشاء عمن يشاء بحكمته وعدله.',
      });
    } else if (normName.contains('الضار') && normName.contains('النافع')) {
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

  batch = db.batch();
  int nameId = 0;
  for (final n in processedNames) {
    nameId++;
    batch.insert('names_of_allah', {
      'id': nameId,
      'name': n['name']!,
      'text': n['text']!,
    });
  }
  await batch.commit(noResult: true);
  print('Loaded $nameId Names of Allah (Target was 99).');

  // Verify and optimize
  print('Running OPTIMIZE, WAL Checkpoint, and VACUUM...');
  await db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  await db.execute('PRAGMA journal_mode = DELETE;');
  await db.execute('PRAGMA optimize;');
  await db.execute('VACUUM;');

  await db.close();
  stopwatch.stop();

  final finalDbSize = dbFile.lengthSync();
  print('========================================');
  print('SUCCESS: Database created at ${dbFile.path}');
  print('Size: ${(finalDbSize / (1024 * 1024)).toStringAsFixed(2)} MB ($finalDbSize bytes)');
  print('Time taken: ${stopwatch.elapsedMilliseconds} ms');
  print('========================================');
}
