import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/features/adhan/presentation/views/adhan_debug_view.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widgets/zikr_image_share_dialog.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_cannon_suhoor_view.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_hub_view.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_khatma_view.dart';
import 'package:quran_app_android/features/reminders/presentation/views/reminders_debug_view.dart';
import 'package:quran_app_android/features/stats/presentation/views/achievements_dashboard_view.dart';

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
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('native_adhan_bridge'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getUpcomingPrayers') {
          return [
            {
              'prayerName': 'الفجر',
              'epochMillis': DateTime.now().add(const Duration(hours: 4)).millisecondsSinceEpoch,
              'formattedTime': '04:30 AM',
            },
            {
              'prayerName': 'الظهر',
              'epochMillis': DateTime.now().add(const Duration(hours: 10)).millisecondsSinceEpoch,
              'formattedTime': '12:15 PM',
            },
          ];
        }
        if (methodCall.method == 'getSettings') {
          return {
            'calculationMethod': 'Egyptian General Authority of Survey',
            'madhab': 'Shafi',
            'timeZoneId': 'Africa/Cairo',
            'adhanSound': 'makkah',
          };
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.taqarrab.quran/native_reminders'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getUpcomingAlarms') {
          return [
            {
              'id': 'morning_azkar_main',
              'type': 'azkar',
              'triggerEpoch': DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch,
              'channel': 'taqarrab_azkar_channel',
              'conditionSatisfied': false,
              'isNextActive': true,
            },
            {
              'id': 'daily_wird_night_reminder',
              'type': 'wird',
              'triggerEpoch': DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch,
              'channel': 'taqarrab_wird_channel',
              'conditionSatisfied': true,
              'isNextActive': false,
            },
          ];
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('native_adhan_bridge'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.taqarrab.quran/native_reminders'),
      null,
    );
  });

  Widget buildTestWidget({
    required Widget child,
    required double width,
    required double height,
    double textScale = 1.0,
  }) {
    return GetMaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }

  group('RenderFlex Overflow Regression Tests', () {
    testWidgets('ZikrImageShareDialog renders without overflow on 320dp width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const ZikrImageShareDialog(
            zikrText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
            categoryTitle: 'أذكار الصباح والمساء',
            virtue: 'كلمتان خفيفتان على اللسان ثقيلتان في الميزان',
          ),
          width: 320,
          height: 640,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تصميم بطاقة الذكر'), findsOneWidget);
      expect(find.text('كحلي إسلامي'), findsOneWidget);
      expect(find.text('مخطوطة عتيقة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ZikrImageShareDialog renders without overflow with large text scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const ZikrImageShareDialog(
            zikrText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
            categoryTitle: 'أذكار الصباح والمساء',
            virtue: 'كلمتان خفيفتان على اللسان ثقيلتان في الميزان',
          ),
          width: 360,
          height: 640,
          textScale: 1.4,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AdhanDebugView renders without overflow on 320dp width and textScale 1.3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const AdhanDebugView(),
          width: 320,
          height: 640,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('RemindersDebugView renders without overflow on 320dp width and textScale 1.3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const RemindersDebugView(),
          width: 320,
          height: 640,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('RamadanKhatmaView renders without overflow on 320dp width and textScale 1.35', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const RamadanKhatmaView(),
          width: 320,
          height: 640,
          textScale: 1.35,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('RamadanHubView renders adaptively on 320dp small phone and 768dp tablet', (tester) async {
      // 1. Small phone
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const RamadanHubView(),
          width: 320,
          height: 640,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 2. Tablet
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        buildTestWidget(
          child: const RamadanHubView(),
          width: 768,
          height: 1024,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('RamadanCannonSuhoorView renders without overflow on 320dp width and textScale 1.3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const RamadanCannonSuhoorView(),
          width: 320,
          height: 640,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AchievementsDashboardView renders adaptively on 320dp and 1024dp', (tester) async {
      // 1. Small phone with scaled text
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestWidget(
          child: const AchievementsDashboardView(),
          width: 320,
          height: 640,
          textScale: 1.3,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // 2. Large iPad / Tablet landscape
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(
        buildTestWidget(
          child: const AchievementsDashboardView(),
          width: 1024,
          height: 768,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
