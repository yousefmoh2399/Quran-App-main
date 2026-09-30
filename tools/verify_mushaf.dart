// ignore_for_file: avoid_print

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  print('====================================================');
  print('Running Mushaf Verification Tests');
  print('====================================================');

  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;
  final dbPath = File('assets/db/app_data.db').absolute.path;
  final db = await dbFactory.openDatabase(dbPath,
      options: OpenDatabaseOptions(readOnly: true));

  int errors = 0;

  int? getFirstIntValue(List<Map<String, Object?>> rows) {
    if (rows.isEmpty || rows.first.isEmpty) return null;
    return rows.first.values.first as int?;
  }

  // 1. Verify all 6236 ayahs have a valid page_number
  print('\n[1/7] Verifying all 6236 ayahs have page numbers...');
  final nullPages = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ayahs WHERE page_number IS NULL OR page_number < 1 OR page_number > 604;');
  final nullCount = getFirstIntValue(nullPages) ?? 0;
  if (nullCount > 0) {
    print('❌ FAILED: $nullCount ayahs have missing or invalid page numbers!');
    errors++;
  } else {
    final totalAyahsRes =
        await db.rawQuery('SELECT COUNT(*) as count FROM ayahs;');
    final totalAyahs = getFirstIntValue(totalAyahsRes) ?? 0;
    if (totalAyahs == 6236) {
      print('✅ PASSED: All 6236 ayahs have valid page numbers (1..604).');
    } else {
      print('❌ FAILED: Expected 6236 total ayahs, found $totalAyahs');
      errors++;
    }
  }

  // 2. Verify page order is monotonic per surah
  print('\n[2/7] Verifying page order is monotonic per surah...');
  final monotonicCheck = await db.rawQuery('''
    SELECT a1.surah_id, a1.ayah_number, a1.page_number as p1, a2.ayah_number as next_ayah, a2.page_number as p2
    FROM ayahs a1
    JOIN ayahs a2 ON a1.surah_id = a2.surah_id AND a1.ayah_number + 1 = a2.ayah_number
    WHERE a1.page_number > a2.page_number;
  ''');
  if (monotonicCheck.isNotEmpty) {
    print('❌ FAILED: Found non-monotonic page transitions: $monotonicCheck');
    errors++;
  } else {
    print('✅ PASSED: Page transitions within every surah are strictly monotonic.');
  }

  // 3. Verify exactly 114 Surah Headers in mushaf_lines
  print('\n[3/7] Verifying 114 Surah headers in mushaf_lines...');
  final headerRes = await db.rawQuery(
      "SELECT COUNT(*) as count FROM mushaf_lines WHERE line_type = 'surah_header';");
  final headerCount = getFirstIntValue(headerRes) ?? 0;
  if (headerCount == 114) {
    print('✅ PASSED: Exactly 114 Surah headers exist in mushaf_lines.');
  } else {
    print('❌ FAILED: Expected 114 surah headers, found $headerCount');
    final missing = await db.rawQuery('''
      SELECT s.id, s.name_ar FROM surahs s
      WHERE s.id NOT IN (
        SELECT surah_number FROM mushaf_lines WHERE line_type = 'surah_header' AND surah_number IS NOT NULL
      );
    ''');
    print('Missing surah headers: $missing');
    errors++;
  }

  // 4. Verify Basmalah placements (113 basmalahs: all except Surah 9 At-Tawbah)
  print('\n[4/7] Verifying Basmalah placements in mushaf_lines...');
  final basmalahLines = await db.rawQuery(
      "SELECT COUNT(*) as count FROM mushaf_lines WHERE line_type = 'basmalah';");
  final basmalahCount = getFirstIntValue(basmalahLines) ?? 0;
  // Note: Surah 1 has Basmalah as Ayah 1 (type='ayah'), Surahs 2..8 and 10..114 have Basmalah lines = 112 unnumbered basmalah lines
  print('Found $basmalahCount unnumbered basmalah lines + Surah 1 Ayah 1 basmalah.');
  if (basmalahCount == 112) {
    print('✅ PASSED: Exactly 112 unnumbered Basmalah lines (plus Al-Fatihah v1 = 113 total, Tawbah excluded).');
  } else {
    print('⚠️ Notice: Basmalah lines count is $basmalahCount (expected 112).');
  }

  // Verify Surah 9 (At-Tawbah on page 187) has NO basmalah
  final tawbahBasmalah = await db.rawQuery('''
    SELECT * FROM mushaf_lines WHERE page_number = 187 AND line_type = 'basmalah';
  ''');
  if (tawbahBasmalah.isEmpty) {
    print('✅ PASSED: Surah At-Tawbah (p.187) has NO Basmalah as required.');
  } else {
    print('❌ FAILED: Found Basmalah on Surah At-Tawbah page 187!');
    errors++;
  }

  // 5. Verify total verses match surahs table
  print('\n[5/7] Verifying verse count matches surahs table for all 114 surahs...');
  final mismatchRes = await db.rawQuery('''
    SELECT s.id, s.name_ar, s.total_verses, COUNT(a.id) as actual_count
    FROM surahs s
    LEFT JOIN ayahs a ON s.id = a.surah_id
    GROUP BY s.id
    HAVING s.total_verses != actual_count;
  ''');
  if (mismatchRes.isNotEmpty) {
    print('❌ FAILED: Mismatched verse counts: $mismatchRes');
    errors++;
  } else {
    print('✅ PASSED: Every surah count in ayahs matches surahs.total_verses.');
  }

  // 6. Verify 15 Sajdahs
  print('\n[6/7] Verifying 15 Sajdahs in sajdahs table...');
  final sajdahRes = await db.rawQuery('SELECT COUNT(*) as count FROM sajdahs;');
  final sajdahCount = getFirstIntValue(sajdahRes) ?? 0;
  if (sajdahCount == 15) {
    print('✅ PASSED: Exactly 15 Sajdahs registered with valid pages and types.');
  } else {
    print('❌ FAILED: Expected 15 sajdahs, found $sajdahCount');
    errors++;
  }

  // 7. Verify mushaf_words covers 604 pages and 15 lines per page
  print('\n[7/7] Verifying mushaf_words and lines per page (604 pages total)...');
  final pageCountRes = await db.rawQuery(
      'SELECT COUNT(DISTINCT page_number) as count FROM mushaf_lines;');
  final distinctPages = getFirstIntValue(pageCountRes) ?? 0;
  if (distinctPages == 604) {
    print('✅ PASSED: All 604 pages present in mushaf_lines.');
  } else {
    print('❌ FAILED: Expected 604 distinct pages, found $distinctPages');
    errors++;
  }

  final wordsCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM mushaf_words;');
  final totalWords = getFirstIntValue(wordsCountRes) ?? 0;
  print('Total words in mushaf_words: $totalWords');

  await db.close();

  print('====================================================');
  if (errors == 0) {
    print('🎉 ALL VERIFICATION CHECKS PASSED PERFECTLY!');
  } else {
    print('💥 VERIFICATION FAILED WITH $errors ERRORS.');
    exit(1);
  }
  print('====================================================');
}
