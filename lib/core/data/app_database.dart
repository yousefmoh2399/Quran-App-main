import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database management service handling asset extraction, versioning, and connection.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static const String dbName = 'app_data.db';
  static const int currentDbVersion = 1;

  Database? _db;

  /// Visible for testing to inject an in-memory or mock database.
  @visibleForTesting
  static Database? customDatabaseForTesting;

  Future<Database> get database async {
    if (customDatabaseForTesting != null) {
      return customDatabaseForTesting!;
    }
    if (_db != null && _db!.isOpen) {
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, dbName);

    final exists = await databaseExists(dbPath);

    if (!exists) {
      debugPrint('AppDatabase: Database does not exist at $dbPath. Copying from assets...');
      await _copyDatabaseFromAssets(dbPath);
    } else {
      // Check version if database already exists
      try {
        final tempDb = await openDatabase(dbPath, readOnly: true);
        final versionRes = await tempDb.rawQuery("SELECT value FROM metadata WHERE key = 'version'");
        await tempDb.close();

        final installedVersion = versionRes.isNotEmpty
            ? int.tryParse(versionRes.first['value'].toString()) ?? 0
            : 0;

        if (installedVersion < currentDbVersion) {
          debugPrint('AppDatabase: Upgrading database from v$installedVersion to v$currentDbVersion...');
          await deleteDatabase(dbPath);
          await _copyDatabaseFromAssets(dbPath);
        }
      } catch (e) {
        debugPrint('AppDatabase: Error reading version, re-copying database: $e');
        await deleteDatabase(dbPath);
        await _copyDatabaseFromAssets(dbPath);
      }
    }

    return await openDatabase(
      dbPath,
      readOnly: true,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _copyDatabaseFromAssets(String destinationPath) async {
    final parentDir = Directory(p.dirname(destinationPath));
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final ByteData data = await rootBundle.load('assets/db/$dbName');
    final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(destinationPath).writeAsBytes(bytes, flush: true);
    debugPrint('AppDatabase: Database copied successfully (${bytes.length} bytes).');
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
