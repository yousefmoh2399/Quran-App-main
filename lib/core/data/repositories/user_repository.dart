import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../native/native_reminders_bridge.dart';
import '../models/user_models.dart';
import '../user_database.dart';

/// Repository managing user personal data:
/// - Bookmarks (Pages and Verses with custom colors and notes)
/// - Memorization tracking (Learning, Memorized, Needs Review)
/// - Reading log and statistics
/// - Daily Wird planning, progress, and streak tracking
class UserRepository {
  final UserDatabase _userDatabase;

  UserRepository({UserDatabase? userDatabase})
      : _userDatabase = userDatabase ?? UserDatabase.instance;

  Future<Database> get _db => _userDatabase.database;

  // ==========================================
  // BOOKMARKS
  // ==========================================

  Future<int> addBookmark(BookmarkItem item) async {
    final db = await _db;
    return await db.insert(
      'bookmarks',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteBookmark(int id) async {
    final db = await _db;
    return await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBookmarkByPage(int page) async {
    final db = await _db;
    return await db.delete(
      'bookmarks',
      where: "type = 'page' AND page = ?",
      whereArgs: [page],
    );
  }

  Future<int> deleteBookmarkByAyah(int surah, int ayah) async {
    final db = await _db;
    return await db.delete(
      'bookmarks',
      where: "type = 'ayah' AND surah = ? AND ayah = ?",
      whereArgs: [surah, ayah],
    );
  }

  Future<List<BookmarkItem>> getAllBookmarks() async {
    final db = await _db;
    final rows = await db.query('bookmarks', orderBy: 'created_at DESC');
    return rows.map((r) => BookmarkItem.fromMap(r)).toList();
  }

  Future<List<BookmarkItem>> getBookmarksForPage(int page) async {
    final db = await _db;
    final rows = await db.query(
      'bookmarks',
      where: 'page = ?',
      whereArgs: [page],
    );
    return rows.map((r) => BookmarkItem.fromMap(r)).toList();
  }

  Future<BookmarkItem?> getBookmarkForAyah(int surah, int ayah) async {
    final db = await _db;
    final rows = await db.query(
      'bookmarks',
      where: "type = 'ayah' AND surah = ? AND ayah = ?",
      whereArgs: [surah, ayah],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BookmarkItem.fromMap(rows.first);
  }

  Future<BookmarkItem?> getLatestBookmark() async {
    final db = await _db;
    final rows = await db.query(
      'bookmarks',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BookmarkItem.fromMap(rows.first);
  }

  Future<bool> hasPageBookmark(int page) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM bookmarks WHERE type = 'page' AND page = ?",
      [page],
    ));
    return (count ?? 0) > 0;
  }

  // ==========================================
  // MEMORIZATION
  // ==========================================

  Future<int> setMemorized(MemorizedItem item) async {
    final db = await _db;
    // Check if existing record exists
    if (item.type == BookmarkType.page) {
      await db.delete(
        'memorized',
        where: "type = 'page' AND page = ?",
        whereArgs: [item.page],
      );
    } else {
      await db.delete(
        'memorized',
        where: "type = 'ayah' AND surah = ? AND ayah = ?",
        whereArgs: [item.surah, item.ayah],
      );
    }
    return await db.insert('memorized', item.toMap());
  }

  Future<int> deleteMemorized(int id) async {
    final db = await _db;
    return await db.delete('memorized', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMemorizedByPage(int page) async {
    final db = await _db;
    return await db.delete(
      'memorized',
      where: "type = 'page' AND page = ?",
      whereArgs: [page],
    );
  }

  Future<int> deleteMemorizedByAyah(int surah, int ayah) async {
    final db = await _db;
    return await db.delete(
      'memorized',
      where: "type = 'ayah' AND surah = ? AND ayah = ?",
      whereArgs: [surah, ayah],
    );
  }

  Future<List<MemorizedItem>> getAllMemorized() async {
    final db = await _db;
    final rows = await db.query('memorized', orderBy: 'updated_at DESC');
    return rows.map((r) => MemorizedItem.fromMap(r)).toList();
  }

  Future<List<MemorizedItem>> getMemorizedForPage(int page) async {
    final db = await _db;
    final rows = await db.query(
      'memorized',
      where: 'page = ?',
      whereArgs: [page],
    );
    return rows.map((r) => MemorizedItem.fromMap(r)).toList();
  }

  Future<MemorizedItem?> getMemorizedForAyah(int surah, int ayah) async {
    final db = await _db;
    final rows = await db.query(
      'memorized',
      where: "type = 'ayah' AND surah = ? AND ayah = ?",
      whereArgs: [surah, ayah],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MemorizedItem.fromMap(rows.first);
  }

  /// Calculates statistics of memorization:
  /// - memorizedPages: total pages marked fully memorized
  /// - learningPages: total pages in progress
  /// - reviewPages: total pages needing review
  /// - totalMemorizedAyahs: individual ayahs memorized
  /// - percentageOfQuran: fraction of 604 pages
  Future<Map<String, dynamic>> getMemorizationStats() async {
    final db = await _db;
    final pageRows = await db.rawQuery('''
      SELECT status, COUNT(*) as cnt 
      FROM memorized 
      WHERE type = 'page' 
      GROUP BY status
    ''');

    int memorizedPages = 0;
    int learningPages = 0;
    int reviewPages = 0;

    for (final r in pageRows) {
      final st = r['status'] as String?;
      final cnt = (r['cnt'] as int?) ?? 0;
      if (st == MemorizeStatus.memorized.key) {
        memorizedPages = cnt;
      } else if (st == MemorizeStatus.learning.key) {
        learningPages = cnt;
      } else if (st == MemorizeStatus.needsReview.key) {
        reviewPages = cnt;
      }
    }

    final ayahCount = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) 
      FROM memorized 
      WHERE type = 'ayah' AND status = 'memorized'
    ''')) ?? 0;

    final double percentage = (memorizedPages / 604.0) * 100.0;
    final double juzCount = memorizedPages / 20.0; // Approx 20 pages per Juz

    return {
      'memorizedPages': memorizedPages,
      'learningPages': learningPages,
      'reviewPages': reviewPages,
      'memorizedAyahs': ayahCount,
      'juzCount': juzCount,
      'percentage': percentage,
    };
  }

  // ==========================================
  // READING LOG
  // ==========================================

  String _formatDate(DateTime dt) {
    return dt.toIso8601String().substring(0, 10); // YYYY-MM-DD
  }

  Future<void> logPageRead(int pageNumber, {DateTime? date}) async {
    final db = await _db;
    final dateStr = _formatDate(date ?? DateTime.now());

    final existing = await db.query(
      'reading_log',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('reading_log', {
        'date': dateStr,
        'pages_read': 1,
        'last_page': pageNumber,
      });
    } else {
      final currentRead = existing.first['pages_read'] as int? ?? 0;
      await db.update(
        'reading_log',
        {
          'pages_read': currentRead + 1,
          'last_page': pageNumber,
        },
        where: 'date = ?',
        whereArgs: [dateStr],
      );
    }
  }

  Future<ReadingLogEntry?> getTodayReadingLog() async {
    final db = await _db;
    final dateStr = _formatDate(DateTime.now());
    final rows = await db.query(
      'reading_log',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReadingLogEntry.fromMap(rows.first);
  }

  Future<List<ReadingLogEntry>> getReadingLog({int limit = 30}) async {
    final db = await _db;
    final rows = await db.query(
      'reading_log',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((r) => ReadingLogEntry.fromMap(r)).toList();
  }

  Future<int?> getLastReadPage() async {
    final db = await _db;
    final rows = await db.query(
      'reading_log',
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['last_page'] as int?;
  }

  Future<Map<String, dynamic>> getReadingStats() async {
    final db = await _db;
    final totalPages = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(pages_read) FROM reading_log')) ?? 0;
    final totalDays = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM reading_log WHERE pages_read > 0')) ?? 0;
    
    final logs = await getReadingLog(limit: 60);
    int streak = 0;
    DateTime checkDate = DateTime.now();
    final logDates = logs.where((l) => l.pagesRead > 0).map((l) => l.date).toSet();
    
    final todayStr = _formatDate(checkDate);
    final yesterdayStr = _formatDate(checkDate.subtract(const Duration(days: 1)));
    if (logDates.contains(todayStr)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else if (logDates.contains(yesterdayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    while (logDates.contains(_formatDate(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return {
      'totalPages': totalPages,
      'totalDays': totalDays,
      'streak': streak,
    };
  }

  // ==========================================
  // WIRD PLAN & STREAK
  // ==========================================

  Future<WirdPlan?> getWirdPlan() async {
    final db = await _db;
    final rows = await db.query('wird_plan', limit: 1);
    if (rows.isEmpty) return null;
    return WirdPlan.fromMap(rows.first);
  }

  Future<int> saveWirdPlan(WirdPlan plan) async {
    final db = await _db;
    final existing = await getWirdPlan();
    int res;
    if (existing == null) {
      res = await db.insert('wird_plan', plan.toMap());
    } else {
      res = await db.update(
        'wird_plan',
        plan.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }

    // Sync with Native Reminders Engine
    try {
      int hour = 20;
      int minute = 0;
      if (plan.reminderTime.isNotEmpty) {
        final parts = plan.reminderTime.split(':');
        if (parts.length >= 2) {
          hour = int.tryParse(parts[0]) ?? 20;
          minute = int.tryParse(parts[1]) ?? 0;
        }
      }
      NativeRemindersBridge.saveReminder({
        'id': 'wird_daily',
        'type': 'wird_daily',
        'schedule_json': jsonEncode({'hour': hour, 'minute': minute}),
        'payload_json': jsonEncode({
          'title': 'وردك القرآني اليومي',
          'body': 'حان وقت وردك القرآني (صـ ${plan.startPage} إلى ${plan.endPage})',
          'start_page': plan.startPage,
        }),
        'enabled': plan.enabled ? 1 : 0,
        'last_triggered': 0,
      });
    } catch (_) {}

    return res;
  }

  /// Calculates target start and end pages for a given plan starting from [fromPage].
  static Map<String, int> calculateWirdRange({
    required WirdType type,
    required int target,
    required int fromPage,
  }) {
    int start = fromPage.clamp(1, 604);
    int pagesCount = 10;

    switch (type) {
      case WirdType.pagesPerDay:
        pagesCount = target.clamp(1, 604);
        break;
      case WirdType.khatmaInDays:
        // 604 pages / target days (e.g. 30 days -> 20 pages/day)
        final days = target.clamp(1, 365);
        pagesCount = (604 / days).ceil().clamp(1, 604);
        break;
      case WirdType.juzPerDay:
        // 1 juz approx 20 pages
        final juzCount = target.clamp(1, 30);
        pagesCount = (juzCount * 20).clamp(1, 604);
        break;
    }

    int end = (start + pagesCount - 1).clamp(1, 604);
    return {'startPage': start, 'endPage': end, 'pagesCount': pagesCount};
  }

  /// Marks today's wird completed, increments streak, and advances wird range to next pages.
  Future<WirdPlan?> markTodayWirdCompleted() async {
    final plan = await getWirdPlan();
    if (plan == null) return null;

    final today = _formatDate(DateTime.now());
    if (plan.lastCompletedDate == today) {
      return plan; // Already marked today
    }

    // Check if streak is continuous (yesterday or today)
    int newStreak = plan.streak;
    if (plan.lastCompletedDate != null) {
      final lastDate = DateTime.tryParse(plan.lastCompletedDate!);
      if (lastDate != null) {
        final now = DateTime.now();
        final todayDateOnly = DateTime(now.year, now.month, now.day);
        final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final diff = todayDateOnly.difference(lastDateOnly).inDays;
        if (diff == 1) {
          newStreak += 1;
        } else if (diff == 0) {
          // Same day completion (already handled earlier, but safe guard)
        } else {
          newStreak = 1; // Streak broken, restart
        }
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    // Advance next wird starting page
    int nextStart = (plan.endPage + 1);
    if (nextStart > 604) {
      nextStart = 1; // Completed Khatma! Loop back to Al-Fatihah
    }
    final range = calculateWirdRange(
      type: plan.type,
      target: plan.target,
      fromPage: nextStart,
    );

    final updated = plan.copyWith(
      streak: newStreak,
      lastCompletedDate: today,
      startPage: range['startPage']!,
      endPage: range['endPage']!,
    );

    await saveWirdPlan(updated);

    try {
      await NativeRemindersBridge.markWirdCompleted(date: today);
    } catch (_) {}

    await evaluateAchievements();
    return updated;
  }

  // ==========================================
  // PRAYER TRACKING & QADAA
  // ==========================================

  Future<void> savePrayerLog(PrayerLog log) async {
    final db = await _db;
    await db.insert(
      'prayer_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await evaluateAchievements();
  }

  Future<Map<String, PrayerLog>> getPrayerLogsForDate(String date) async {
    final db = await _db;
    final rows = await db.query(
      'prayer_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    final map = <String, PrayerLog>{};
    for (final r in rows) {
      final log = PrayerLog.fromMap(r);
      map[log.prayer] = log;
    }
    return map;
  }

  Future<List<PrayerLog>> getPrayerLogsBetween(String startDate, String endDate) async {
    final db = await _db;
    final rows = await db.query(
      'prayer_logs',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return rows.map((r) => PrayerLog.fromMap(r)).toList();
  }

  Future<Map<String, int>> getQadaaCounts() async {
    final db = await _db;
    final rows = await db.query('qadaa_prayers');
    final map = <String, int>{'fajr': 0, 'dhuhr': 0, 'asr': 0, 'maghrib': 0, 'isha': 0};
    for (final r in rows) {
      final prayer = r['prayer'] as String;
      final count = r['count'] as int? ?? 0;
      map[prayer] = count;
    }
    return map;
  }

  Future<void> setQadaaCount(String prayer, int count) async {
    final db = await _db;
    await db.insert(
      'qadaa_prayers',
      {'prayer': prayer, 'count': count.clamp(0, 99999)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // FASTING TRACKING
  // ==========================================

  Future<void> saveFastingLog(FastingLog log) async {
    final db = await _db;
    await db.insert(
      'fasting_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await evaluateAchievements();
  }

  Future<void> deleteFastingLog(String date) async {
    final db = await _db;
    await db.delete('fasting_logs', where: 'date = ?', whereArgs: [date]);
  }

  Future<List<FastingLog>> getFastingLogsForMonth(String yearMonthPrefix) async {
    final db = await _db;
    final rows = await db.query(
      'fasting_logs',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonthPrefix%'],
      orderBy: 'date ASC',
    );
    return rows.map((r) => FastingLog.fromMap(r)).toList();
  }

  Future<bool> isDayFasted(String date) async {
    final db = await _db;
    final rows = await db.query(
      'fasting_logs',
      where: 'date = ? AND completed = 1',
      whereArgs: [date],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ==========================================
  // TAFSIR CACHE
  // ==========================================

  Future<String?> getCachedTafsir(int surah, int ayah, int tafsirId) async {
    final db = await _db;
    final rows = await db.query(
      'tafsir_cache',
      columns: ['text'],
      where: 'surah = ? AND ayah = ? AND tafsir_id = ?',
      whereArgs: [surah, ayah, tafsirId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['text'] as String?;
  }

  Future<void> cacheTafsir(int surah, int ayah, int tafsirId, String text) async {
    final db = await _db;
    await db.insert(
      'tafsir_cache',
      {'surah': surah, 'ayah': ayah, 'tafsir_id': tafsirId, 'text': text},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // ACHIEVEMENTS & STATS
  // ==========================================

  Future<Set<String>> getUnlockedAchievements() async {
    final db = await _db;
    final rows = await db.query('user_achievements');
    return rows.map((r) => r['id'] as String).toSet();
  }

  Future<bool> unlockAchievement(String badgeId) async {
    final db = await _db;
    final rows = await db.query('user_achievements', where: 'id = ?', whereArgs: [badgeId], limit: 1);
    if (rows.isNotEmpty) return false;

    await db.insert('user_achievements', {
      'id': badgeId,
      'unlocked_at': DateTime.now().toIso8601String(),
    });
    return true;
  }

  Future<void> evaluateAchievements() async {
    final stats = await getReadingStats();
    final totalPages = stats['totalPages'] ?? 0;
    final totalDays = stats['totalDays'] ?? 0;

    if (totalPages >= 1) await unlockAchievement('first_page');
    if (totalDays >= 3) await unlockAchievement('streak_3');
    if (totalDays >= 7) await unlockAchievement('streak_7');
    if (totalDays >= 30) await unlockAchievement('streak_30');

    // Check prayer achievement
    final today = _formatDate(DateTime.now());
    final todayPrayers = await getPrayerLogsForDate(today);
    if (todayPrayers.length >= 5 && todayPrayers.values.every((p) => p.status == PrayerStatus.onTime || p.status == PrayerStatus.jamaah)) {
      await unlockAchievement('prayers_day');
    }

    // Check fasting achievement
    final db = await _db;
    final fastingCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM fasting_logs WHERE completed = 1')) ?? 0;
    if (fastingCount >= 1) await unlockAchievement('fasting_day');

    final plan = await getWirdPlan();
    if (plan != null && (plan.streak >= 30 || plan.lastCompletedDate != null && plan.startPage == 1 && plan.streak > 10)) {
      await unlockAchievement('first_khatma');
    }
  }

  // ==========================================
  // BACKUP & RESTORE
  // ==========================================

  Future<String> exportUserDataJson() async {
    final db = await _db;
    final data = <String, dynamic>{
      'version': 2,
      'app': 'taqarrab',
      'exported_at': DateTime.now().toIso8601String(),
      'bookmarks': await db.query('bookmarks'),
      'memorized': await db.query('memorized'),
      'reading_log': await db.query('reading_log'),
      'wird_plan': await db.query('wird_plan'),
      'commute_wird_log': await db.query('commute_wird_log'),
      'commute_wird_state': await db.query('commute_wird_state'),
      'prayer_logs': await db.query('prayer_logs'),
      'qadaa_prayers': await db.query('qadaa_prayers'),
      'fasting_logs': await db.query('fasting_logs'),
      'user_achievements': await db.query('user_achievements'),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importUserDataJson(String jsonStr) async {
    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      if (!decoded.containsKey('version')) return false;

      final db = await _db;
      await db.transaction((txn) async {
        void safeRestore(String table, String key) async {
          if (decoded.containsKey(key)) {
            final list = decoded[key] as List<dynamic>?;
            if (list != null) {
              for (final item in list) {
                if (item is Map<String, dynamic>) {
                  await txn.insert(table, item, conflictAlgorithm: ConflictAlgorithm.replace);
                }
              }
            }
          }
        }

        safeRestore('bookmarks', 'bookmarks');
        safeRestore('memorized', 'memorized');
        safeRestore('reading_log', 'reading_log');
        safeRestore('wird_plan', 'wird_plan');
        safeRestore('commute_wird_log', 'commute_wird_log');
        safeRestore('commute_wird_state', 'commute_wird_state');
        safeRestore('prayer_logs', 'prayer_logs');
        safeRestore('qadaa_prayers', 'qadaa_prayers');
        safeRestore('fasting_logs', 'fasting_logs');
        safeRestore('user_achievements', 'user_achievements');
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

