import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/views/sai_counter_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/tawaf_counter_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/umrah_hub_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Widget buildTestApp({
  required Widget child,
  double width = 320.0,
  double height = 640.0,
  double textScale = 1.0,
}) {
  return GetMaterialApp(
    theme: ThemeData(
      extensions: const [AppColorsExtension.light],
    ),
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
    Get.reset();
    Get.put(UmrahPreferencesController());
  });

  group('TawafCounterView Widget Tests', () {
    testWidgets('Renders Tawaf counter, Kaaba label, and advances lap on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(child: const TawafCounterView(), width: 360, height: 700));
      await tester.pumpAndSettle();

      expect(find.text('عدّاد طواف الكعبة المشرفة'), findsOneWidget);
      expect(find.text('طواف العمرة'), findsWidgets);
      expect(find.text('0'), findsOneWidget);
      expect(find.text(' / 7'), findsOneWidget);

      // Tap Complete Lap
      final completeButton = find.text('إتمام الشوط 1');
      expect(completeButton, findsOneWidget);

      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('إتمام الشوط 2'), findsOneWidget);
    });
  });

  group('SaiCounterView Widget Tests', () {
    testWidgets('Renders Safa-Marwah directions and green zone banner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(child: const SaiCounterView(), width: 360, height: 700));
      await tester.pumpAndSettle();

      expect(find.text('عدّاد السعي (الصفا والمروة)'), findsOneWidget);
      expect(find.text('الصفا'), findsWidgets);
      expect(find.text('المروة'), findsWidgets);
      expect(find.text('تنبيه: بين الميلين الأخضرين (المنطقة الخضراء)'), findsOneWidget);

      // Complete first lap (Safa -> Marwah)
      final completeBtn = find.text('إتمام الشوط 1 (الصفا إلى المروة)');
      expect(completeBtn, findsOneWidget);

      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // Now on lap 2 (Marwah -> Safa)
      expect(find.text('إتمام الشوط 2 (المروة إلى الصفا)'), findsOneWidget);
    });
  });

  group('Umrah Accessibility & Responsive Tests (320dp & TextScaler 2.0)', () {
    testWidgets('TawafCounterView renders without overflow at 320dp and 2.0 text scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(
          child: const TawafCounterView(),
          width: 320,
          height: 640,
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('عدّاد طواف الكعبة المشرفة'), findsOneWidget);
    });

    testWidgets('SaiCounterView renders without overflow at 320dp and 2.0 text scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(
          child: const SaiCounterView(),
          width: 320,
          height: 640,
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('عدّاد السعي (الصفا والمروة)'), findsOneWidget);
    });

    testWidgets('UmrahHubView renders without overflow at 320dp in Elderly Mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final prefs = Get.find<UmrahPreferencesController>();
      prefs.isElderlyMode.value = true;

      await tester.pumpWidget(
        buildTestApp(
          child: const UmrahHubView(),
          width: 320,
          height: 640,
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('رفيق المعتمر والحاج'), findsOneWidget);
    });

    testWidgets('UmrahHubView renders Hajj and Umrah guide tiles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestApp(
          child: const UmrahHubView(),
          width: 360,
          height: 1000,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('رفيق المعتمر والحاج'), findsOneWidget);
      expect(find.text('دليل مناسك الحج خطوة بخطوة'), findsOneWidget);
      expect(find.text('دليل مناسك العمرة خطوة بخطوة'), findsOneWidget);
    });
  });
}
