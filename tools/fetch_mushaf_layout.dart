// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String kBaseUrl =
    'https://raw.githubusercontent.com/zonetecde/mushaf-layout/refs/heads/main/mushaf';

const List<Map<String, dynamic>> kSajdahs = [
  {'sajdah_number': 1, 'surah': 7, 'ayah': 206, 'type': 'recommended'},
  {'sajdah_number': 2, 'surah': 13, 'ayah': 15, 'type': 'recommended'},
  {'sajdah_number': 3, 'surah': 16, 'ayah': 50, 'type': 'recommended'},
  {'sajdah_number': 4, 'surah': 17, 'ayah': 109, 'type': 'recommended'},
  {'sajdah_number': 5, 'surah': 19, 'ayah': 58, 'type': 'recommended'},
  {'sajdah_number': 6, 'surah': 22, 'ayah': 18, 'type': 'recommended'},
  {'sajdah_number': 7, 'surah': 22, 'ayah': 77, 'type': 'recommended'},
  {'sajdah_number': 8, 'surah': 25, 'ayah': 60, 'type': 'recommended'},
  {'sajdah_number': 9, 'surah': 27, 'ayah': 26, 'type': 'recommended'},
  {'sajdah_number': 10, 'surah': 32, 'ayah': 15, 'type': 'obligatory'},
  {'sajdah_number': 11, 'surah': 38, 'ayah': 24, 'type': 'recommended'},
  {'sajdah_number': 12, 'surah': 41, 'ayah': 38, 'type': 'obligatory'},
  {'sajdah_number': 13, 'surah': 53, 'ayah': 62, 'type': 'obligatory'},
  {'sajdah_number': 14, 'surah': 84, 'ayah': 21, 'type': 'recommended'},
  {'sajdah_number': 15, 'surah': 96, 'ayah': 19, 'type': 'obligatory'},
];

// 30 Ajza' start positions (surah, ayah, start_page)
const List<Map<String, dynamic>> kJuzMetadata = [
  {'juz': 1, 'name': 'الم', 'surah': 1, 'ayah': 1, 'page': 1},
  {'juz': 2, 'name': 'سيقول', 'surah': 2, 'ayah': 142, 'page': 22},
  {'juz': 3, 'name': 'تلك الرسل', 'surah': 2, 'ayah': 253, 'page': 42},
  {'juz': 4, 'name': 'لن تنالوا', 'surah': 3, 'ayah': 93, 'page': 62},
  {'juz': 5, 'name': 'والمحصنات', 'surah': 4, 'ayah': 24, 'page': 82},
  {'juz': 6, 'name': 'لا يحب الله', 'surah': 4, 'ayah': 148, 'page': 102},
  {'juz': 7, 'name': 'وإذا سمعوا', 'surah': 5, 'ayah': 82, 'page': 121},
  {'juz': 8, 'name': 'ولو أننا', 'surah': 6, 'ayah': 111, 'page': 142},
  {'juz': 9, 'name': 'قال الملأ', 'surah': 7, 'ayah': 88, 'page': 162},
  {'juz': 10, 'name': 'واعلموا', 'surah': 8, 'ayah': 41, 'page': 182},
  {'juz': 11, 'name': 'يعتذرون', 'surah': 9, 'ayah': 93, 'page': 201},
  {'juz': 12, 'name': 'وما من دابة', 'surah': 11, 'ayah': 6, 'page': 222},
  {'juz': 13, 'name': 'وما أبرئ', 'surah': 12, 'ayah': 53, 'page': 242},
  {'juz': 14, 'name': 'ربما', 'surah': 15, 'ayah': 1, 'page': 262},
  {'juz': 15, 'name': 'سبحان الذي', 'surah': 17, 'ayah': 1, 'page': 282},
  {'juz': 16, 'name': 'قال ألم', 'surah': 18, 'ayah': 75, 'page': 302},
  {'juz': 17, 'name': 'اقترب', 'surah': 21, 'ayah': 1, 'page': 322},
  {'juz': 18, 'name': 'قد أفلح', 'surah': 23, 'ayah': 1, 'page': 342},
  {'juz': 19, 'name': 'وقال الذين', 'surah': 25, 'ayah': 21, 'page': 362},
  {'juz': 20, 'name': 'أمن خلق', 'surah': 27, 'ayah': 56, 'page': 382},
  {'juz': 21, 'name': 'اتل ما أوحي', 'surah': 29, 'ayah': 46, 'page': 402},
  {'juz': 22, 'name': 'ومن يقنت', 'surah': 33, 'ayah': 31, 'page': 422},
  {'juz': 23, 'name': 'وما أنزلنا', 'surah': 36, 'ayah': 28, 'page': 442},
  {'juz': 24, 'name': 'فمن أظلم', 'surah': 39, 'ayah': 32, 'page': 462},
  {'juz': 25, 'name': 'إليه يرد', 'surah': 41, 'ayah': 47, 'page': 482},
  {'juz': 26, 'name': 'حم', 'surah': 46, 'ayah': 1, 'page': 502},
  {'juz': 27, 'name': 'قال فما خطبكم', 'surah': 51, 'ayah': 31, 'page': 522},
  {'juz': 28, 'name': 'قد سمع الله', 'surah': 58, 'ayah': 1, 'page': 542},
  {'juz': 29, 'name': 'تبارك الذي', 'surah': 67, 'ayah': 1, 'page': 562},
  {'juz': 30, 'name': 'عم يتساءلون', 'surah': 78, 'ayah': 1, 'page': 582},
];

Future<void> main() async {
  final stopwatch = Stopwatch()..start();
  print('====================================================');
  print('Step 1: Fetching & Populating Madani Mushaf Layout Data');
  print('====================================================');

  final cacheDir = Directory('tools/source/mushaf_layout');
  if (!cacheDir.existsSync()) {
    cacheDir.createSync(recursive: true);
  }

  // 1. Verify connectivity with test request
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);
  try {
    final testReq = await client.getUrl(Uri.parse('$kBaseUrl/page-001.json'));
    final testRes = await testReq.close();
    if (testRes.statusCode != 200) {
      print('❌ Failed to reach layout API (status: ${testRes.statusCode})');
      exit(1);
    }
  } catch (e) {
    print('❌ Network error / API unreachable: $e');
    print('Aborting process as requested.');
    exit(1);
  }

  // 2. Download missing pages concurrently
  print('Downloading layout for all 604 pages...');
  final List<int> pagesToDownload = [];
  for (int p = 1; p <= 604; p++) {
    final pad = p.toString().padLeft(3, '0');
    final file = File('${cacheDir.path}/page-$pad.json');
    if (!file.existsSync() || file.lengthSync() < 100) {
      pagesToDownload.add(p);
    }
  }

  if (pagesToDownload.isNotEmpty) {
    print('Fetching ${pagesToDownload.length} pages from remote repository...');
    const int batchSize = 25;
    for (int i = 0; i < pagesToDownload.length; i += batchSize) {
      final end = (i + batchSize < pagesToDownload.length)
          ? i + batchSize
          : pagesToDownload.length;
      final chunk = pagesToDownload.sublist(i, end);

      await Future.wait(chunk.map((page) async {
        final pad = page.toString().padLeft(3, '0');
        final uri = Uri.parse('$kBaseUrl/page-$pad.json');
        final req = await client.getUrl(uri);
        final res = await req.close();
        if (res.statusCode == 200) {
          final content = await res.transform(utf8.decoder).join();
          File('${cacheDir.path}/page-$pad.json').writeAsStringSync(content);
        } else {
          throw Exception('Failed to fetch page $page: ${res.statusCode}');
        }
      }));

      final progress = ((end / pagesToDownload.length) * 100).toStringAsFixed(1);
      stdout.write('\rDownloaded $end/${pagesToDownload.length} ($progress%)');
    }
    print('\nAll 604 pages downloaded and cached locally.');
  } else {
    print('All 604 pages already cached locally in ${cacheDir.path}.');
  }
  client.close();

  // 3. Connect to SQLite database
  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;
  final dbPath = File('assets/db/app_data.db').absolute.path;
  final db = await dbFactory.openDatabase(dbPath);

  await db.execute('PRAGMA synchronous = NORMAL;');

  print('\nCreating Mushaf tables in SQLite...');
  await db.execute('DROP TABLE IF EXISTS mushaf_lines;');
  await db.execute('DROP TABLE IF EXISTS mushaf_words;');
  await db.execute('DROP TABLE IF EXISTS juz_metadata;');
  await db.execute('DROP TABLE IF EXISTS hizb_metadata;');
  await db.execute('DROP TABLE IF EXISTS rub_metadata;');
  await db.execute('DROP TABLE IF EXISTS sajdahs;');

  await db.execute('''
    CREATE TABLE mushaf_lines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      page_number INTEGER NOT NULL,
      line_number INTEGER NOT NULL,
      line_type TEXT NOT NULL,
      surah_number INTEGER,
      text TEXT,
      qpc_v2 TEXT
    );
  ''');

  await db.execute('''
    CREATE TABLE mushaf_words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      page_number INTEGER NOT NULL,
      line_number INTEGER NOT NULL,
      word_index INTEGER NOT NULL,
      surah_number INTEGER NOT NULL,
      ayah_number INTEGER NOT NULL,
      location TEXT NOT NULL,
      text_uthmani TEXT NOT NULL,
      glyph_code TEXT NOT NULL
    );
  ''');

  await db.execute('''
    CREATE TABLE juz_metadata (
      juz_number INTEGER PRIMARY KEY,
      name_ar TEXT NOT NULL,
      start_surah INTEGER NOT NULL,
      start_ayah INTEGER NOT NULL,
      start_page INTEGER NOT NULL
    );
  ''');

  await db.execute('''
    CREATE TABLE sajdahs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sajdah_number INTEGER NOT NULL,
      surah_number INTEGER NOT NULL,
      ayah_number INTEGER NOT NULL,
      page_number INTEGER NOT NULL,
      type TEXT NOT NULL
    );
  ''');

  print('Parsing pages and inserting into SQLite...');
  final Map<String, int> ayahFirstPageMap = {}; // "$surah:$ayah" -> min page

  for (int p = 1; p <= 604; p++) {
    final pad = p.toString().padLeft(3, '0');
    final file = File('${cacheDir.path}/page-$pad.json');
    final jsonStr = file.readAsStringSync(encoding: utf8);
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final lines = data['lines'] as List<dynamic>;

    final batch = db.batch();

    for (final lineData in lines) {
      final lineNum = lineData['line'] as int;
      final rawType = lineData['type'] as String;

      String lineType;
      int? surahNumber;
      String? lineText;
      String? qpcV2;

      if (rawType == 'surah-header') {
        lineType = 'surah_header';
        surahNumber = int.tryParse(lineData['surah']?.toString() ?? '');
        lineText = lineData['text'] as String?;
      } else if (rawType == 'basmala') {
        lineType = 'basmalah';
        qpcV2 = lineData['qpcV2'] as String?;
        lineText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
      } else {
        lineType = 'ayah';
        lineText = lineData['text'] as String?;
      }

      final wordsList = lineData['words'] as List<dynamic>?;
      if (wordsList != null && wordsList.isNotEmpty) {
        final qpcList = <String>[];
        for (int w = 0; w < wordsList.length; w++) {
          final wordObj = wordsList[w];
          final location = wordObj['location'] as String; // "surah:ayah:word"
          final parts = location.split(':');
          final sNum = int.parse(parts[0]);
          final aNum = int.parse(parts[1]);
          final wNum = int.parse(parts[2]);
          final wText = wordObj['word'] as String;
          final glyph = wordObj['qpcV2'] as String;
          qpcList.add(glyph);

          // Track first page of each ayah
          final key = '$sNum:$aNum';
          if (!ayahFirstPageMap.containsKey(key)) {
            ayahFirstPageMap[key] = p;
          }

          batch.insert('mushaf_words', {
            'page_number': p,
            'line_number': lineNum,
            'word_index': wNum,
            'surah_number': sNum,
            'ayah_number': aNum,
            'location': location,
            'text_uthmani': wText,
            'glyph_code': glyph,
          });
        }
        qpcV2 ??= qpcList.join(' ');
      }

      batch.insert('mushaf_lines', {
        'page_number': p,
        'line_number': lineNum,
        'line_type': lineType,
        'surah_number': surahNumber,
        'text': lineText,
        'qpc_v2': qpcV2,
      });
    }

    await batch.commit(noResult: true);
  }

  // Insert Juz metadata
  print('Inserting 30 Ajza metadata...');
  final juzBatch = db.batch();
  for (final j in kJuzMetadata) {
    juzBatch.insert('juz_metadata', {
      'juz_number': j['juz'],
      'name_ar': j['name'],
      'start_surah': j['surah'],
      'start_ayah': j['ayah'],
      'start_page': j['page'],
    });
  }
  await juzBatch.commit(noResult: true);

  // Insert Sajdahs
  print('Inserting 15 Sajdahs metadata...');
  final sajdahBatch = db.batch();
  for (final s in kSajdahs) {
    final sNum = s['surah'] as int;
    final aNum = s['ayah'] as int;
    final page = ayahFirstPageMap['$sNum:$aNum'] ?? 1;
    sajdahBatch.insert('sajdahs', {
      'sajdah_number': s['sajdah_number'],
      'surah_number': sNum,
      'ayah_number': aNum,
      'page_number': page,
      'type': s['type'],
    });
  }
  await sajdahBatch.commit(noResult: true);

  // 4. Update page_number in ayahs table for all 6236 ayahs
  print('Updating page_number in ayahs table for all 6236 verses...');
  final updateBatch = db.batch();
  for (final entry in ayahFirstPageMap.entries) {
    final parts = entry.key.split(':');
    final sId = int.parse(parts[0]);
    final aId = int.parse(parts[1]);
    updateBatch.rawUpdate(
      'UPDATE ayahs SET page_number = ? WHERE surah_id = ? AND ayah_number = ?;',
      [entry.value, sId, aId],
    );
  }
  await updateBatch.commit(noResult: true);

  // 5. Create indexes
  print('Creating indexes for mushaf tables...');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_mushaf_lines_page ON mushaf_lines(page_number);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_mushaf_words_page ON mushaf_words(page_number);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_mushaf_words_ayah ON mushaf_words(surah_number, ayah_number);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_ayahs_page ON ayahs(page_number);');

  await db.close();
  stopwatch.stop();
  print('====================================================');
  print('Done in ${stopwatch.elapsed.inSeconds}s!');
  print('====================================================');
}
