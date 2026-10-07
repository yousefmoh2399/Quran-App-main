import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/features/umrah/data/services/guide_engine.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/sai_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/tawaf_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database testDb;
  late GuideEngine guideEngine;

  setUpAll(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await UserDatabase.createTablesForTest(testDb);
    UserDatabase.customDatabaseForTesting = testDb;
    guideEngine = GuideEngine();
  });

  tearDownAll(() async {
    await testDb.close();
    UserDatabase.customDatabaseForTesting = null;
  });

  group('TawafController Unit Tests', () {
    late TawafController controller;

    setUp(() async {
      await guideEngine.resetGuideProgress('umrah');
      controller = TawafController(guideEngine: guideEngine);
      await controller.loadSavedState();
    });

    test('Initial lap count is 0 and not finished', () {
      expect(controller.currentLap.value, equals(0));
      expect(controller.isFinished.value, isFalse);
    });

    test('completeLap increments lap and clamps at 7', () async {
      for (int i = 1; i <= 7; i++) {
        await controller.completeLap();
        expect(controller.currentLap.value, equals(i));
      }
      expect(controller.isFinished.value, isTrue);

      // Attempting to advance beyond 7 does nothing
      await controller.completeLap();
      expect(controller.currentLap.value, equals(7));
    });

    test('undoLap decrements lap and unsets finished flag', () async {
      await controller.completeLap(); // lap 1
      await controller.completeLap(); // lap 2
      expect(controller.currentLap.value, equals(2));

      await controller.undoLap();
      expect(controller.currentLap.value, equals(1));
      expect(controller.isFinished.value, isFalse);
    });

    test('resetTawaf resets lap count to 0', () async {
      await controller.completeLap();
      await controller.completeLap();
      expect(controller.currentLap.value, equals(2));

      await controller.resetTawaf();
      expect(controller.currentLap.value, equals(0));
      expect(controller.isFinished.value, isFalse);
    });

    test('Tawaf progress is persisted and restored via SQLite', () async {
      await controller.completeLap();
      await controller.completeLap();
      await controller.completeLap(); // lap 3

      // Re-initialize controller simulating app restart
      final newController = TawafController(guideEngine: guideEngine);
      await newController.loadSavedState();
      expect(newController.currentLap.value, equals(3));
      expect(newController.isFinished.value, isFalse);
    });
  });

  group('SaiController Unit Tests', () {
    late SaiController controller;

    setUp(() async {
      await guideEngine.resetGuideProgress('umrah');
      controller = SaiController(guideEngine: guideEngine);
      await controller.loadSavedState();
    });

    test('Initial state: start at Safa towards Marwah', () {
      expect(controller.currentLap.value, equals(0));
      expect(controller.activeLapNumber, equals(1));
      expect(controller.currentFrom, equals('الصفا'));
      expect(controller.currentTo, equals('المروة'));
    });

    test('7 laps alternate Safa and Marwah directions correctly', () {
      // Lap 1: Safa -> Marwah
      expect(controller.getStartPoint(1), equals('الصفا'));
      expect(controller.getDestinationPoint(1), equals('المروة'));

      // Lap 2: Marwah -> Safa
      expect(controller.getStartPoint(2), equals('المروة'));
      expect(controller.getDestinationPoint(2), equals('الصفا'));

      // Lap 3: Safa -> Marwah
      expect(controller.getStartPoint(3), equals('الصفا'));
      expect(controller.getDestinationPoint(3), equals('المروة'));

      // Lap 4: Marwah -> Safa
      expect(controller.getStartPoint(4), equals('المروة'));
      expect(controller.getDestinationPoint(4), equals('الصفا'));

      // Lap 5: Safa -> Marwah
      expect(controller.getStartPoint(5), equals('الصفا'));
      expect(controller.getDestinationPoint(5), equals('المروة'));

      // Lap 6: Marwah -> Safa
      expect(controller.getStartPoint(6), equals('المروة'));
      expect(controller.getDestinationPoint(6), equals('الصفا'));

      // Lap 7: Safa -> Marwah (Final lap finishes at Marwah)
      expect(controller.getStartPoint(7), equals('الصفا'));
      expect(controller.getDestinationPoint(7), equals('المروة'));
    });

    test('toggleGreenZone toggles flag and completeLap auto-clears it', () async {
      controller.toggleGreenZone();
      expect(controller.isGreenZoneAlertActive.value, isTrue);

      await controller.completeLap();
      expect(controller.currentLap.value, equals(1));
      expect(controller.isGreenZoneAlertActive.value, isFalse);
    });

    test('Sai completion clamps at 7 and sets finished flag', () async {
      for (int i = 0; i < 7; i++) {
        await controller.completeLap();
      }
      expect(controller.currentLap.value, equals(7));
      expect(controller.isFinished.value, isTrue);

      await controller.resetSai();
      expect(controller.currentLap.value, equals(0));
      expect(controller.isFinished.value, isFalse);
    });
  });
}
