// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  final stopwatch = Stopwatch()..start();
  print('====================================================');
  print('Populating Saadi & Ibn Kathir into app_data.db');
  print('====================================================');

  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;
  final dbFile = File('assets/db/app_data.db');

  if (!dbFile.existsSync()) {
    throw Exception('Database file assets/db/app_data.db does not exist!');
  }

  final initialSize = dbFile.lengthSync();
  print('Initial DB Size: ${(initialSize / (1024 * 1024)).toStringAsFixed(2)} MB ($initialSize bytes)');

  // Load JSON datasets
  final saadiFile = File('tools/source/tafsir_saadi.json');
  final ibnKathirFile = File('tools/source/tafsir_ibn_kathir.json');

  if (!saadiFile.existsSync() || !ibnKathirFile.existsSync()) {
    throw Exception('Tafsir JSON files missing in tools/source/ !');
  }

  print('Loading tafsir JSON files...');
  final Map<String, dynamic> saadiMap = json.decode(saadiFile.readAsStringSync(encoding: utf8));
  final Map<String, dynamic> ibnKathirMap = json.decode(ibnKathirFile.readAsStringSync(encoding: utf8));

  print('Saadi records in JSON: ${saadiMap.length}');
  print('Ibn Kathir records in JSON: ${ibnKathirMap.length}');

  if (saadiMap.length != 6236 || ibnKathirMap.length != 6236) {
    throw Exception('Expected exactly 6236 records per tafsir!');
  }

  // Open DB for writing
  final db = await dbFactory.openDatabase(dbFile.absolute.path);

  // Configure pragmas
  await db.execute('PRAGMA journal_mode = WAL;');
  await db.execute('PRAGMA synchronous = NORMAL;');

  // Check columns on ayahs table
  print('Checking table schema...');
  final tableInfo = await db.rawQuery('PRAGMA table_info(ayahs);');
  final columnNames = tableInfo.map((row) => row['name'] as String).toSet();

  if (!columnNames.contains('tafsir_saadi')) {
    print('Adding column tafsir_saadi to ayahs...');
    await db.execute('ALTER TABLE ayahs ADD COLUMN tafsir_saadi TEXT;');
  } else {
    print('Column tafsir_saadi already exists.');
  }

  if (!columnNames.contains('tafsir_ibn_kathir')) {
    print('Adding column tafsir_ibn_kathir to ayahs...');
    await db.execute('ALTER TABLE ayahs ADD COLUMN tafsir_ibn_kathir TEXT;');
  } else {
    print('Column tafsir_ibn_kathir already exists.');
  }

  // Populate data in batches
  print('Updating ayahs table with tafsir content...');
  final ayahs = await db.rawQuery('SELECT id, surah_id, ayah_number FROM ayahs ORDER BY id ASC;');
  print('Total ayahs in DB: ${ayahs.length}');

  var batch = db.batch();
  int count = 0;
  int batchSize = 500;

  for (final ayah in ayahs) {
    final int surahId = ayah['surah_id'] as int;
    final int ayahNum = ayah['ayah_number'] as int;
    final key = '$surahId:$ayahNum';

    final saadiText = saadiMap[key] as String? ?? '';
    final ibnKathirText = ibnKathirMap[key] as String? ?? '';

    batch.rawUpdate(
      'UPDATE ayahs SET tafsir_saadi = ?, tafsir_ibn_kathir = ? WHERE surah_id = ? AND ayah_number = ?',
      [saadiText, ibnKathirText, surahId, ayahNum],
    );

    count++;
    if (count % batchSize == 0) {
      await batch.commit(noResult: true);
      batch = db.batch();
      print('Updated $count / ${ayahs.length} ayahs...');
    }
  }

  if (count % batchSize != 0) {
    await batch.commit(noResult: true);
  }

  print('All $count ayahs updated.');

  // Update DB metadata version to 2
  await db.rawInsert("INSERT OR REPLACE INTO metadata (key, value) VALUES ('version', '2');");
  await db.rawInsert("INSERT OR REPLACE INTO metadata (key, value) VALUES ('tafsirs_updated_at', '${DateTime.now().toIso8601String()}');");

  // Verify non-empty counts
  print('\n---------------- VERIFICATION ----------------');
  final muyassarRes = await db.rawQuery("SELECT COUNT(*) as c FROM ayahs WHERE tafsir_muyassar IS NOT NULL AND trim(tafsir_muyassar) != '';");
  final saadiRes = await db.rawQuery("SELECT COUNT(*) as c FROM ayahs WHERE tafsir_saadi IS NOT NULL AND trim(tafsir_saadi) != '';");
  final ibnKathirRes = await db.rawQuery("SELECT COUNT(*) as c FROM ayahs WHERE tafsir_ibn_kathir IS NOT NULL AND trim(tafsir_ibn_kathir) != '';");

  final muyassarCount = (muyassarRes.first['c'] as int?) ?? 0;
  final saadiCount = (saadiRes.first['c'] as int?) ?? 0;
  final ibnKathirCount = (ibnKathirRes.first['c'] as int?) ?? 0;

  print('Tafsir Muyassar non-empty verses: $muyassarCount / 6236 (Empty: ${6236 - muyassarCount})');
  print('Tafsir Al-Saadi non-empty verses: $saadiCount / 6236 (Empty: ${6236 - saadiCount})');
  print('Tafsir Ibn Kathir non-empty verses: $ibnKathirCount / 6236 (Empty: ${6236 - ibnKathirCount})');

  if (saadiCount != 6236 || ibnKathirCount != 6236) {
    throw Exception('Verification failed: Some verses have empty tafsir!');
  }

  // Vacuum & Optimize
  print('\nOptimizing database (PRAGMA optimize, VACUUM)...');
  await db.execute('PRAGMA wal_checkpoint(TRUNCATE);');
  await db.execute('PRAGMA journal_mode = DELETE;');
  await db.execute('PRAGMA optimize;');
  await db.execute('VACUUM;');

  await db.close();
  stopwatch.stop();

  final finalSize = dbFile.lengthSync();
  print('====================================================');
  print('SUCCESS: app_data.db updated!');
  print('Size BEFORE: ${(initialSize / (1024 * 1024)).toStringAsFixed(2)} MB ($initialSize bytes)');
  print('Size AFTER:  ${(finalSize / (1024 * 1024)).toStringAsFixed(2)} MB ($finalSize bytes)');
  print('Size Delta:  +${((finalSize - initialSize) / (1024 * 1024)).toStringAsFixed(2)} MB (+${finalSize - initialSize} bytes)');
  print('Time taken:  ${stopwatch.elapsedMilliseconds} ms');
  print('====================================================');
}
