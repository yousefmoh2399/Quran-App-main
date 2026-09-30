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

  group('Wird Range Calculation Tests', () {
    test('calculateWirdRange: pagesPerDay', () {
      final range = UserRepository.calculateWirdRange(
        type: WirdType.pagesPerDay,
        target: 10,
        fromPage: 1,
      );
      expect(range['startPage'], equals(1));
      expect(range['endPage'], equals(10));
      expect(range['pagesCount'], equals(10));
    });

    test('calculateWirdRange: khatmaInDays (30 days)', () {
      // 604 / 30 = 20.133... -> ceil() = 21 pages/day
      final range = UserRepository.calculateWirdRange(
        type: WirdType.khatmaInDays,
        target: 30,
        fromPage: 1,
      );
      expect(range['startPage'], equals(1));
      expect(range['endPage'], equals(21));
      expect(range['pagesCount'], equals(21));
    });

    test('calculateWirdRange: juzPerDay (1 juz)', () {
      // 1 * 20 = 20 pages
      final range = UserRepository.calculateWirdRange(
        type: WirdType.juzPerDay,
        target: 1,
        fromPage: 1,
      );
      expect(range['startPage'], equals(1));
      expect(range['endPage'], equals(20));
      expect(range['pagesCount'], equals(20));
    });

    test('calculateWirdRange: clamps to 604 at end of Quran', () {
      final range = UserRepository.calculateWirdRange(
        type: WirdType.pagesPerDay,
        target: 10,
        fromPage: 600,
      );
      expect(range['startPage'], equals(600));
      expect(range['endPage'], equals(604));
    });
  });

  group('Wird Plan Repository & Streak Tests', () {
    test('save and retrieve wird plan', () async {
      final initialPlan = WirdPlan(
        type: WirdType.pagesPerDay,
        target: 10,
        startDate: '2026-09-01',
        reminderTime: '08:00',
        enabled: true,
        startPage: 1,
        endPage: 10,
        streak: 0,
      );

      await userRepo.saveWirdPlan(initialPlan);
      final retrieved = await userRepo.getWirdPlan();
      expect(retrieved, isNotNull);
      expect(retrieved!.type, equals(WirdType.pagesPerDay));
      expect(retrieved.target, equals(10));
      expect(retrieved.startPage, equals(1));
      expect(retrieved.endPage, equals(10));
      expect(retrieved.streak, equals(0));
    });

    test('markTodayWirdCompleted increments streak and advances pages', () async {
      final plan = await userRepo.getWirdPlan();
      expect(plan, isNotNull);

      final completed = await userRepo.markTodayWirdCompleted();
      expect(completed, isNotNull);
      expect(completed!.streak, equals(1));
      expect(completed.startPage, equals(11));
      expect(completed.endPage, equals(20));

      // Calling markTodayWirdCompleted again on the same day is idempotent
      final duplicate = await userRepo.markTodayWirdCompleted();
      expect(duplicate!.streak, equals(1));
      expect(duplicate.startPage, equals(11));
      expect(duplicate.endPage, equals(20));
    });

    test('streak increments on consecutive day completion', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final plan = (await userRepo.getWirdPlan())!.copyWith(
        lastCompletedDate: yesterday,
        streak: 4,
        startPage: 21,
        endPage: 30,
      );
      await userRepo.saveWirdPlan(plan);

      final updated = await userRepo.markTodayWirdCompleted();
      expect(updated, isNotNull);
      expect(updated!.streak, equals(5));
      expect(updated.startPage, equals(31));
      expect(updated.endPage, equals(40));
    });

    test('streak resets to 1 if day is skipped (broken streak)', () async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String().substring(0, 10);
      final plan = (await userRepo.getWirdPlan())!.copyWith(
        lastCompletedDate: threeDaysAgo,
        streak: 10,
        startPage: 41,
        endPage: 50,
      );
      await userRepo.saveWirdPlan(plan);

      final updated = await userRepo.markTodayWirdCompleted();
      expect(updated, isNotNull);
      expect(updated!.streak, equals(1)); // Reset after missing 3 days
      expect(updated.startPage, equals(51));
      expect(updated.endPage, equals(60));
    });

    test('completing Khatma wraps startPage around to 1', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final plan = (await userRepo.getWirdPlan())!.copyWith(
        lastCompletedDate: yesterday,
        streak: 29,
        startPage: 595,
        endPage: 604,
      );
      await userRepo.saveWirdPlan(plan);

      final completed = await userRepo.markTodayWirdCompleted();
      expect(completed, isNotNull);
      expect(completed!.streak, equals(30));
      // End page was 604, so next start wraps around to 1!
      expect(completed.startPage, equals(1));
      expect(completed.endPage, equals(10));
    });
  });
}
