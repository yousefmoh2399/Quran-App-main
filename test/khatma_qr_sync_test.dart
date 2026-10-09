import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/features/khatma_circles/data/models/khatma_circle_model.dart';
import 'package:quran_app_android/features/khatma_circles/data/services/khatma_circles_service.dart';
import 'package:quran_app_android/features/khatma_circles/presentation/controllers/khatma_circles_controller.dart';
import 'package:quran_app_android/features/khatma_circles/presentation/views/khatma_qr_display_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database testDb;

  setUpAll(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await UserDatabase.createTablesForTest(testDb);
    UserDatabase.customDatabaseForTesting = testDb;
  });

  tearDownAll(() async {
    await testDb.close();
    UserDatabase.customDatabaseForTesting = null;
  });

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Khatma Circles QR Offline Encoding & Parsing Tests', () {
    test('generateCircleQrPayload and parseCircleQrPayload preserve circle structure and juz assignments', () {
      final service = KhatmaCirclesService();
      final now = DateTime.now();

      final originalJuz = List.generate(
        30,
        (i) => KhatmaCircleJuz(
          circleId: 'circle_family_test',
          juzNumber: i + 1,
          assignedTo: i == 0 ? 'يوسف' : (i == 1 ? 'سارة' : ''),
          status: i == 0 ? 'completed' : (i == 1 ? 'in_progress' : 'available'),
        ),
      );

      final circle = KhatmaCircle(
        id: 'circle_family_test',
        title: 'ختمة العائلة الكريمة',
        description: 'ختمة شهرية لجميع أفراد الأسرة',
        createdAt: now,
        isCompleted: false,
        juzList: originalJuz,
      );

      final payload = service.generateCircleQrPayload(circle);
      expect(payload.startsWith(KhatmaCirclesService.qrCirclePrefix), isTrue);

      final parsed = service.parseCircleQrPayload(payload);
      expect(parsed, isNotNull);
      expect(parsed!.id, equals('circle_family_test'));
      expect(parsed.title, equals('ختمة العائلة الكريمة'));
      expect(parsed.description, equals('ختمة شهرية لجميع أفراد الأسرة'));
      expect(parsed.juzList.length, equals(30));

      expect(parsed.juzList[0].assignedTo, equals('يوسف'));
      expect(parsed.juzList[0].status, equals('completed'));
      expect(parsed.juzList[0].isCompleted, isTrue);

      expect(parsed.juzList[1].assignedTo, equals('سارة'));
      expect(parsed.juzList[1].status, equals('in_progress'));
      expect(parsed.juzList[1].isInProgress, isTrue);

      expect(parsed.juzList[2].assignedTo, equals(''));
      expect(parsed.juzList[2].isAvailable, isTrue);
    });

    test('generateMemberProgressQrPayload and parseMemberProgressQrPayload format daily member progress accurately', () {
      final service = KhatmaCirclesService();

      final payload = service.generateMemberProgressQrPayload(
        circleId: 'circle_100',
        memberName: 'أحمد',
        juzNumbers: [5, 6],
        status: 'completed',
      );

      expect(payload.startsWith(KhatmaCirclesService.qrProgressPrefix), isTrue);

      final parsed = service.parseMemberProgressQrPayload(payload);
      expect(parsed, isNotNull);
      expect(parsed!['circleId'], equals('circle_100'));
      expect(parsed['memberName'], equals('أحمد'));
      expect(parsed['juzNumbers'], equals([5, 6]));
      expect(parsed['status'], equals('completed'));
    });
  });

  group('Khatma Circles QR Database Sync Tests', () {
    test('importOrUpdateCircle and applyMemberProgress sync changes in SQLite offline', () async {
      final service = KhatmaCirclesService();
      final created = await service.createCircle(title: 'ختمة رمضان للعائلة');

      expect(created.completedJuzCount, equals(0));

      // Simulate member daily progress update from scanned QR
      final progressData = {
        'circleId': created.id,
        'memberName': 'فاطمة',
        'juzNumbers': [1, 2],
        'status': 'completed',
      };

      final controller = KhatmaCirclesController();
      final success = await controller.applyMemberProgressFromQr(progressData);
      expect(success, isTrue);

      final updatedCircle = await service.getCircleById(created.id);
      expect(updatedCircle, isNotNull);
      expect(updatedCircle!.completedJuzCount, equals(2));
      expect(updatedCircle.juzList[0].assignedTo, equals('فاطمة'));
      expect(updatedCircle.juzList[0].isCompleted, isTrue);
      expect(updatedCircle.juzList[1].assignedTo, equals('فاطمة'));
      expect(updatedCircle.juzList[1].isCompleted, isTrue);
    });
  });

  group('KhatmaQrDisplayDialog Widget Tests', () {
    testWidgets('renders QR code and title in dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KhatmaQrDisplayDialog(
              title: 'ختمة العائلة',
              subtitle: 'امسح هذا الرمز للانضمام',
              payload: 'taqarrab:circle:{"v":1,"id":"c1","t":"test","j":[]}',
              type: KhatmaQrType.circleFull,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('ختمة العائلة'), findsOneWidget);
      expect(find.text('رمز الختمة الجماعية'), findsOneWidget);
      expect(find.text('نسخ الشفرة'), findsOneWidget);
      expect(find.text('مشاركة الرمز'), findsOneWidget);
    });
  });
}
