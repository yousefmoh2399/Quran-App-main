import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/trip_diary_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/views/hajj_umrah_duas_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/ihram_prohibitions_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/pilgrim_checklist_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/sai_counter_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/tawaf_counter_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/trip_diary_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/umrah_hub_view.dart';
import 'package:quran_app_android/features/umrah/presentation/widgets/umrah_filter_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(UmrahPreferencesController());
    await testDb.delete('trip_diary');
    await testDb.delete('pilgrim_checklist');
    await testDb.delete('guide_progress');
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

  group('Filter Chips Selection and Interactivity Tests', () {
    testWidgets('HajjUmrahDuasView filter chips toggle and highlight on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(child: const HajjUmrahDuasView(), width: 500, height: 800));
      await tester.pumpAndSettle();

      final talbiyahChip = find.widgetWithText(UmrahFilterChip, 'التلبية والإحرام');
      expect(talbiyahChip, findsOneWidget);

      await tester.tap(talbiyahChip);
      await tester.pumpAndSettle();

      final selectedChip = tester.widget<UmrahFilterChip>(talbiyahChip);
      expect(selectedChip.isSelected, isTrue);
      expect(find.text('التلبية النبوية المأثورة'), findsOneWidget);
    });

    testWidgets('TripDiaryView seeds default notes and filter chips update on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(child: const TripDiaryView(), width: 500, height: 800));
      final controller = Get.find<TripDiaryController>();
      await tester.runAsync(() async {
        await controller.loadEntries();
      });
      await tester.pump();

      expect(find.text('الوقوف أمام الكعبة المشرفة لأول مرة'), findsOneWidget);

      final duaChip = find.widgetWithText(UmrahFilterChip, 'دعاء مستجاب');
      expect(duaChip, findsOneWidget);

      await tester.tap(duaChip);
      await tester.runAsync(() async {
        await controller.loadEntries();
      });
      await tester.pump();

      final selectedDuaChip = tester.widget<UmrahFilterChip>(duaChip);
      expect(selectedDuaChip.isSelected, isTrue);
      expect(find.text('الدعاء المستجاب عند الملتزم وتحت الميزاب'), findsOneWidget);
    });

    testWidgets('PilgrimChecklistView filter chips update and filter items on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(child: const PilgrimChecklistView(), width: 500, height: 800));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      final ihramClothesChip = find.widgetWithText(UmrahFilterChip, 'ملابس الإحرام');
      expect(ihramClothesChip, findsOneWidget);

      await tester.tap(ihramClothesChip);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      final selectedChip = tester.widget<UmrahFilterChip>(ihramClothesChip);
      expect(selectedChip.isSelected, isTrue);
      expect(find.text('إزار ورداء أبيضين قطنيين نظيفين'), findsOneWidget);
    });

    testWidgets('IhramProhibitionsView filter chips update on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestApp(child: const IhramProhibitionsView(), width: 500, height: 800));
      await tester.pumpAndSettle();

      final clothingChip = find.widgetWithText(UmrahFilterChip, 'خاصة بالرجال');
      expect(clothingChip, findsOneWidget);

      await tester.tap(clothingChip);
      await tester.pumpAndSettle();

      final selectedClothingChip = tester.widget<UmrahFilterChip>(clothingChip);
      expect(selectedClothingChip.isSelected, isTrue);
      expect(find.textContaining('لبس المخيط'), findsOneWidget);
    });
  });
}
