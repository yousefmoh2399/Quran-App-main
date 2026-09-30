import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database management service for user personal data (Bookmarks, Memorization,
/// Reading logs, and Daily Wird plans).
///
/// Kept completely separate from `app_data.db` so database content updates
/// or schema migrations in Quran data NEVER overwrite or wipe user personal progress.
class UserDatabase {
  UserDatabase._internal();
  static final UserDatabase instance = UserDatabase._internal();

  static const String dbName = 'user_data.db';
  static const int currentDbVersion = 2;

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

    final parentDir = Directory(p.dirname(dbPath));
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    return await openDatabase(
      dbPath,
      version: currentDbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _onUpgrade(db, oldVersion, newVersion);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    // 1. Bookmarks table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        page INTEGER NOT NULL,
        surah INTEGER,
        ayah INTEGER,
        color TEXT NOT NULL DEFAULT 'gold',
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bookmarks_page ON bookmarks(page)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bookmarks_surah_ayah ON bookmarks(surah, ayah)');

    // 2. Memorized table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memorized (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        page INTEGER NOT NULL,
        surah INTEGER,
        ayah INTEGER,
        status TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_memorized_page ON memorized(page)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_memorized_surah_ayah ON memorized(surah, ayah)');

    // 3. Reading Log table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        pages_read INTEGER NOT NULL DEFAULT 0,
        last_page INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_reading_log_date ON reading_log(date)');

    // 4. Wird Plan table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wird_plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        target INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        reminder_time TEXT,
        second_reminder_time TEXT,
        enabled INTEGER NOT NULL DEFAULT 1,
        start_page INTEGER NOT NULL DEFAULT 1,
        end_page INTEGER NOT NULL DEFAULT 10,
        streak INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT
      )
    ''');

    // 5. Commute Wird Log table (separate streak & log)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS commute_wird_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        slot_id TEXT NOT NULL,
        pages_read INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_commute_log_date ON commute_wird_log(date)');

    // 6. Commute Wird State table (position & streak)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS commute_wird_state (
        id INTEGER PRIMARY KEY,
        current_page INTEGER NOT NULL DEFAULT 1,
        streak INTEGER NOT NULL DEFAULT 0,
        last_completed_date TEXT
      )
    ''');
    // Ensure default initial state exists
    await db.execute('''
      INSERT OR IGNORE INTO commute_wird_state (id, current_page, streak, last_completed_date)
      VALUES (1, 1, 0, NULL)
    ''');

    // 7. Prayer logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS prayer_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        prayer TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(date, prayer)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_prayer_logs_date ON prayer_logs(date)');

    // 8. Qadaa prayers counter table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS qadaa_prayers (
        prayer TEXT PRIMARY KEY,
        count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Prepopulate 5 daily prayers
    for (final p in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      await db.execute('''
        INSERT OR IGNORE INTO qadaa_prayers (prayer, count) VALUES (?, 0)
      ''', [p]);
    }

    // 9. Fasting logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fasting_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_fasting_logs_date ON fasting_logs(date)');

    // 10. User achievements table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_achievements (
        id TEXT PRIMARY KEY,
        unlocked_at TEXT NOT NULL
      )
    ''');

    // 11. Tafsir offline cache table (for Saadi & Ibn Kathir)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tafsir_cache (
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        tafsir_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        PRIMARY KEY (surah, ayah, tafsir_id)
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS prayer_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          prayer TEXT NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE(date, prayer)
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_prayer_logs_date ON prayer_logs(date)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS qadaa_prayers (
          prayer TEXT PRIMARY KEY,
          count INTEGER NOT NULL DEFAULT 0
        )
      ''');
      for (final p in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        await db.execute('''
          INSERT OR IGNORE INTO qadaa_prayers (prayer, count) VALUES (?, 0)
        ''', [p]);
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS fasting_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          type TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_fasting_logs_date ON fasting_logs(date)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_achievements (
          id TEXT PRIMARY KEY,
          unlocked_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS tafsir_cache (
          surah INTEGER NOT NULL,
          ayah INTEGER NOT NULL,
          tafsir_id INTEGER NOT NULL,
          text TEXT NOT NULL,
          PRIMARY KEY (surah, ayah, tafsir_id)
        )
      ''');
    }
  }

  /// Exposed for testing in-memory databases
  static Future<void> createTablesForTest(Database db) => _createTables(db);

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
