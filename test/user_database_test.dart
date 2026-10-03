import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database testDb;
  late UserRepository userRepo;

  setUpAll(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await UserDatabase.createTablesForTest(testDb);
    UserDatabase.customDatabaseForTesting = testDb;
    userRepo = UserRepository();
  });

  tearDownAll(() async {
    await testDb.close();
    UserDatabase.customDatabaseForTesting = null;
  });

  group('UserRepository Bookmark Tests', () {
    test('add, query and delete page bookmark', () async {
      final item = BookmarkItem(
        type: BookmarkType.page,
        page: 77,
        color: BookmarkColor.emerald,
        note: 'بداية الورد الأسبوعي',
        createdAt: DateTime.now(),
      );

      final id = await userRepo.addBookmark(item);
      expect(id, isPositive);

      final hasBookmark = await userRepo.hasPageBookmark(77);
      expect(hasBookmark, isTrue);

      final pageBookmarks = await userRepo.getBookmarksForPage(77);
      expect(pageBookmarks.length, equals(1));
      expect(pageBookmarks.first.note, equals('بداية الورد الأسبوعي'));
      expect(pageBookmarks.first.color, equals(BookmarkColor.emerald));

      await userRepo.deleteBookmarkByPage(77);
      expect(await userRepo.hasPageBookmark(77), isFalse);
    });

    test('add and query ayah bookmark', () async {
      final ayahBookmark = BookmarkItem(
        type: BookmarkType.ayah,
        page: 1,
        surah: 1,
        ayah: 2,
        color: BookmarkColor.ruby,
        note: 'آية الحمد',
        createdAt: DateTime.now(),
      );

      final id = await userRepo.addBookmark(ayahBookmark);
      expect(id, isPositive);

      final found = await userRepo.getBookmarkForAyah(1, 2);
      expect(found, isNotNull);
      expect(found!.surah, equals(1));
      expect(found.ayah, equals(2));
      expect(found.color, equals(BookmarkColor.ruby));

      await userRepo.deleteBookmarkByAyah(1, 2);
      expect(await userRepo.getBookmarkForAyah(1, 2), isNull);
    });
  });

  group('UserRepository Memorization Tests', () {
    test('setMemorized updates status and calculates statistics', () async {
      await userRepo.setMemorized(MemorizedItem(
        type: BookmarkType.page,
        page: 1,
        status: MemorizeStatus.memorized,
        updatedAt: DateTime.now(),
      ));

      await userRepo.setMemorized(MemorizedItem(
        type: BookmarkType.page,
        page: 2,
        status: MemorizeStatus.learning,
        updatedAt: DateTime.now(),
      ));

      await userRepo.setMemorized(MemorizedItem(
        type: BookmarkType.ayah,
        page: 3,
        surah: 2,
        ayah: 1,
        status: MemorizeStatus.memorized,
        updatedAt: DateTime.now(),
      ));

      final stats = await userRepo.getMemorizationStats();
      expect(stats['memorizedPages'], equals(1));
      expect(stats['learningPages'], equals(1));
      expect(stats['memorizedAyahs'], equals(1));
      expect(stats['percentage'], greaterThan(0.0));
    });
  });

  group('UserRepository Reading Log Tests', () {
    test('logPageRead records pages and updates last read', () async {
      final now = DateTime.now();
      await userRepo.logPageRead(10, date: now);
      await userRepo.logPageRead(11, date: now);

      final todayLog = await userRepo.getTodayReadingLog();
      expect(todayLog, isNotNull);
      expect(todayLog!.pagesRead, equals(2));
      expect(todayLog.lastPage, equals(11));

      final lastPage = await userRepo.getLastReadPage();
      expect(lastPage, equals(11));
    });
  });

  group('UserRepository Wird Planning & Calculation Tests', () {
    test('calculateWirdRange computes accurate boundaries', () {
      // 10 pages per day from page 1
      final range1 = UserRepository.calculateWirdRange(
        type: WirdType.pagesPerDay,
        target: 10,
        fromPage: 1,
      );
      expect(range1['startPage'], equals(1));
      expect(range1['endPage'], equals(10));
      expect(range1['pagesCount'], equals(10));

      // Khatma in 30 days (604 / 30 = 21 pages/day)
      final range2 = UserRepository.calculateWirdRange(
        type: WirdType.khatmaInDays,
        target: 30,
        fromPage: 1,
      );
      expect(range2['startPage'], equals(1));
      expect(range2['pagesCount'], equals(21));
      expect(range2['endPage'], equals(21));

      // 1 Juz per day (approx 20 pages)
      final range3 = UserRepository.calculateWirdRange(
        type: WirdType.juzPerDay,
        target: 1,
        fromPage: 21,
      );
      expect(range3['startPage'], equals(21));
      expect(range3['pagesCount'], equals(20));
      expect(range3['endPage'], equals(40));
    });

    test('saveWirdPlan and markTodayWirdCompleted advances streak and pages', () async {
      final plan = WirdPlan(
        type: WirdType.pagesPerDay,
        target: 10,
        startDate: '2026-09-30',
        startPage: 1,
        endPage: 10,
        streak: 0,
      );

      await userRepo.saveWirdPlan(plan);
      final loaded = await userRepo.getWirdPlan();
      expect(loaded, isNotNull);
      expect(loaded!.target, equals(10));
      expect(loaded.streak, equals(0));

      final completed = await userRepo.markTodayWirdCompleted();
      expect(completed, isNotNull);
      expect(completed!.streak, equals(1));
      expect(completed.startPage, equals(11));
      expect(completed.endPage, equals(20));
    });
  });

  group('UserRepository Prayer Tracking & Sync Tests', () {
    test('savePrayerLog and getPrayerLogsForDate correctly persist and retrieve logs', () async {
      final logFajr = PrayerLog(
        date: '2026-10-03',
        prayer: 'fajr',
        status: PrayerStatus.onTime,
      );
      await userRepo.savePrayerLog(logFajr);

      final logs = await userRepo.getPrayerLogsForDate('2026-10-03');
      expect(logs.containsKey('fajr'), isTrue);
      expect(logs['fajr']!.status, equals(PrayerStatus.onTime));
      expect(logs['fajr']!.prayer, equals('fajr'));
    });

    test('syncNativePrayedLogs imports logs from native and clears pending keys', () async {
      final clearedKeys = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('native_adhan_bridge'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getPendingPrayedLogs') {
            return [
              {
                'key': '2026-10-03_asr',
                'date': '2026-10-03',
                'prayer': 'asr',
                'status': 'jamaah',
              },
              {
                'key': '2026-10-03_maghrib',
                'date': '2026-10-03',
                'prayer': 'maghrib',
                'status': 'on_time',
              },
            ];
          } else if (methodCall.method == 'clearPendingPrayedLogs') {
            clearedKeys.addAll(List<String>.from(methodCall.arguments as List));
            return null;
          } else if (methodCall.method == 'markPrayerAsPrayed') {
            return true;
          }
          return null;
        },
      );

      final syncedCount = await userRepo.syncNativePrayedLogs();
      expect(syncedCount, equals(2));
      expect(clearedKeys, containsAll(['2026-10-03_asr', '2026-10-03_maghrib']));

      final logs = await userRepo.getPrayerLogsForDate('2026-10-03');
      expect(logs.containsKey('asr'), isTrue);
      expect(logs['asr']!.status, equals(PrayerStatus.jamaah));
      expect(logs.containsKey('maghrib'), isTrue);
      expect(logs['maghrib']!.status, equals(PrayerStatus.onTime));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('native_adhan_bridge'),
        null,
      );
    });
  });
}
