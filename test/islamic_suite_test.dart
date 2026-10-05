import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/features/calendar/data/islamic_calendar_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Islamic Calendar Service Tests', () {
    final service = IslamicCalendarService.instance;

    test('getTodayHijri returns valid Hijri day and month', () {
      final hijri = service.getTodayHijri();
      expect(hijri.hDay, inInclusiveRange(1, 30));
      expect(hijri.hMonth, inInclusiveRange(1, 12));
      expect(hijri.hYear, greaterThanOrEqualTo(1445));
    });

    test('getEventForDate detects known Islamic occasions', () {
      // 10th of Muharram (Ashura)
      final occasion = service.getEventForDate(1, 10);
      expect(occasion, isNotNull);
      expect(occasion!.title, contains('عاشوراء'));
      expect(occasion.isFastingRecommended, isTrue);

      // 1st of Shawwal (Eid Al-Fitr)
      final eid = service.getEventForDate(10, 1);
      expect(eid, isNotNull);
      expect(eid!.title, contains('عيد الفطر'));
      expect(eid.isFastingRecommended, isFalse);
    });

    test('isWhiteDay accurately identifies White Days', () {
      final hijri13 = service.fromGregorian(DateTime(2025, 1, 13));
      hijri13.hDay = 13;
      expect(service.isWhiteDay(hijri13), isTrue);

      final hijri1 = service.fromGregorian(DateTime(2025, 1, 1));
      hijri1.hDay = 1;
      expect(service.isWhiteDay(hijri1), isFalse);
    });

    test('fromGregorian and toGregorian conversions work correctly', () {
      final greg = DateTime(2025, 3, 1);
      final hijri = service.fromGregorian(greg);
      expect(hijri.hYear, greaterThanOrEqualTo(1446));

      final convertedGreg = service.toGregorian(hijri.hYear, hijri.hMonth, hijri.hDay);
      expect(convertedGreg.year, equals(2025));
    });
  });

  group('User Repository Prayer & Fasting Tracking Tests', () {
    late UserRepository repo;

    setUp(() async {
      repo = UserRepository();
      final db = await UserDatabase.instance.database;
      await db.delete('bookmarks');
      await db.delete('prayer_logs');
      await db.delete('fasting_logs');
      await db.delete('qadaa_prayers');
      await db.delete('user_achievements');
      await db.delete('reading_log');
    });

    test('Prayer logging: save, retrieve, and change status', () async {
      const testDate = '2026-05-15';
      final now = DateTime.now();
      await repo.savePrayerLog(PrayerLog(date: testDate, prayer: 'fajr', status: PrayerStatus.jamaah, createdAt: now));
      await repo.savePrayerLog(PrayerLog(date: testDate, prayer: 'dhuhr', status: PrayerStatus.onTime, createdAt: now));
      await repo.savePrayerLog(PrayerLog(date: testDate, prayer: 'asr', status: PrayerStatus.late, createdAt: now));
      await repo.savePrayerLog(PrayerLog(date: testDate, prayer: 'maghrib', status: PrayerStatus.missed, createdAt: now));
      await repo.savePrayerLog(PrayerLog(date: testDate, prayer: 'isha', status: PrayerStatus.qadaa, createdAt: now));

      final logs = await repo.getPrayerLogsForDate(testDate);
      expect(logs.length, equals(5));
      expect(logs['fajr']!.status, equals(PrayerStatus.jamaah));
      expect(logs['dhuhr']!.status, equals(PrayerStatus.onTime));
      expect(logs['asr']!.status, equals(PrayerStatus.late));
      expect(logs['maghrib']!.status, equals(PrayerStatus.missed));
      expect(logs['isha']!.status, equals(PrayerStatus.qadaa));
    });

    test('Qadaa prayers counter increment and decrement', () async {
      await repo.setQadaaCount('fajr', 10);
      await repo.setQadaaCount('dhuhr', 5);

      final counts = await repo.getQadaaCounts();
      expect(counts['fajr'], equals(10));
      expect(counts['dhuhr'], equals(5));

      // Decrement one qadaa prayer (performed)
      await repo.setQadaaCount('fajr', 9);
      final updatedCounts = await repo.getQadaaCounts();
      expect(updatedCounts['fajr'], equals(9));
    });

    test('Fasting logging and retrieval', () async {
      const testDate = '2026-05-15';
      final now = DateTime.now();
      await repo.saveFastingLog(
        FastingLog(date: testDate, type: FastingType.whiteDays, completed: true, createdAt: now),
      );

      final isFasted = await repo.isDayFasted(testDate);
      expect(isFasted, isTrue);

      final monthLogs = await repo.getFastingLogsForMonth('2026-05');
      expect(monthLogs.length, equals(1));
      expect(monthLogs.first.type, equals(FastingType.whiteDays));

      // Toggle off
      await repo.deleteFastingLog(testDate);
      final isFastedAfter = await repo.isDayFasted(testDate);
      expect(isFastedAfter, isFalse);
    });

    test('Achievements evaluation and unlock', () async {
      // Record a reading log
      await repo.logPageRead(1);

      await repo.evaluateAchievements();
      final unlocked = await repo.getUnlockedAchievements();
      expect(unlocked.contains('first_page'), isTrue);
    });

    test('JSON Backup export and import', () async {
      final now = DateTime.now();
      // Add a bookmark, a prayer log, and a fasting log
      await repo.addBookmark(
        BookmarkItem(
          type: BookmarkType.page,
          page: 25,
          color: BookmarkColor.emerald,
          note: 'Backup test note',
          createdAt: now,
        ),
      );
      await repo.savePrayerLog(PrayerLog(date: '2026-06-01', prayer: 'fajr', status: PrayerStatus.jamaah, createdAt: now));
      await repo.saveFastingLog(FastingLog(date: '2026-06-01', type: FastingType.mondayThursday, completed: true, createdAt: now));

      // Export JSON
      final jsonStr = await repo.exportUserDataJson();
      expect(jsonStr, isNotEmpty);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['version'], equals(2));
      expect(decoded['bookmarks'], isNotEmpty);
      expect(decoded['prayer_logs'], isNotEmpty);
      expect(decoded['fasting_logs'], isNotEmpty);

      // Wipe and Restore
      final db = await UserDatabase.instance.database;
      await db.delete('bookmarks');
      await db.delete('prayer_logs');
      await db.delete('fasting_logs');

      expect((await repo.getAllBookmarks()).isEmpty, isTrue);

      final success = await repo.importUserDataJson(jsonStr);
      expect(success, isTrue);

      final restoredBookmarks = await repo.getAllBookmarks();
      expect(restoredBookmarks.length, equals(1));
      expect(restoredBookmarks.first.note, equals('Backup test note'));

      final restoredPrayers = await repo.getPrayerLogsForDate('2026-06-01');
      expect(restoredPrayers['fajr']!.status, equals(PrayerStatus.jamaah));
    });
  });
}
