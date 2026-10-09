import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/features/reading_analytics/data/models/reading_analytics_models.dart';
import 'package:quran_app_android/features/reading_analytics/data/services/reading_analytics_service.dart';
import 'package:quran_app_android/features/reading_analytics/presentation/controllers/reading_analytics_controller.dart';
import 'package:quran_app_android/features/reading_analytics/presentation/views/reading_analytics_view.dart';

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
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Reading Analytics Models Unit Tests', () {
    test('ReadingHeatmapDay creates properly and calculates intensity correctly', () {
      final now = DateTime(2026, 10, 9);
      final day = ReadingHeatmapDay(
        date: now,
        pagesRead: 15,
        minutesSpent: 33,
        intensity: 3,
        isToday: true,
      );

      expect(day.date, equals(now));
      expect(day.pagesRead, equals(15));
      expect(day.minutesSpent, equals(33));
      expect(day.intensity, equals(3));
      expect(day.isToday, isTrue);
    });

    test('ReadingStreakData calculations and values', () {
      const streak = ReadingStreakData(
        currentStreak: 7,
        longestStreak: 21,
        totalActiveDays: 45,
      );

      expect(streak.currentStreak, equals(7));
      expect(streak.longestStreak, equals(21));
      expect(streak.totalActiveDays, equals(45));
    });

    test('ReadingPeakHourBucket properties', () {
      const bucket = ReadingPeakHourBucket(
        id: 'fajr',
        titleAr: 'بعد الفجر',
        timeRange: '4:00 ص - 7:59 ص',
        pagesRead: 40,
        percentage: 0.4,
        icon: Icons.wb_twilight_rounded,
      );

      expect(bucket.id, equals('fajr'));
      expect(bucket.titleAr, equals('بعد الفجر'));
      expect(bucket.pagesRead, equals(40));
      expect(bucket.percentage, equals(0.4));
    });
  });

  group('ReadingAnalyticsService Logic Tests', () {
    test('getAnalyticsSummary returns 112 days of heatmap and valid metrics', () async {
      final service = ReadingAnalyticsService();
      final summary = await service.getAnalyticsSummary(
        referenceDate: DateTime(2026, 10, 9),
      );

      expect(summary.heatmapDays.length, equals(112));
      expect(summary.totalPagesRead, greaterThanOrEqualTo(0));
      expect(summary.khatmaProgress, inInclusiveRange(0.0, 1.0));
      expect(summary.weeklyGoalPages, greaterThan(0));
      expect(summary.peakHours.length, equals(5));
    });

    test('Weekly goal setting updates correctly in preferences', () async {
      final service = ReadingAnalyticsService();
      await service.setWeeklyGoal(140);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('reading_analytics_weekly_goal'), equals(140));
    });

    test('Record reading session records peak hour correctly', () async {
      final service = ReadingAnalyticsService();
      final fajrTime = DateTime(2026, 10, 9, 5, 30);
      await service.recordReadingSession(pagesRead: 5, timestamp: fajrTime);

      final prefs = await SharedPreferences.getInstance();
      final peakHoursRaw = prefs.getString('reading_analytics_peak_hours');
      expect(peakHoursRaw, isNotNull);
      expect(peakHoursRaw!.contains('fajr'), isTrue);
    });
  });

  group('ReadingAnalyticsController Tests', () {
    test('loads summary and updates reactive state', () async {
      final controller = ReadingAnalyticsController();
      await controller.loadAnalytics();

      expect(controller.isLoading.value, isFalse);
      expect(controller.summary.value, isNotNull);
      expect(controller.summary.value!.heatmapDays.length, equals(112));
    });

    test('selectDay updates selectedDay reactive value', () async {
      final controller = ReadingAnalyticsController();
      await controller.loadAnalytics();

      final dayToSelect = controller.summary.value!.heatmapDays.first;
      controller.selectDay(dayToSelect);
      expect(controller.selectedDay.value, equals(dayToSelect));

      final anotherDay = controller.summary.value!.heatmapDays[5];
      controller.selectDay(anotherDay);
      expect(controller.selectedDay.value, equals(anotherDay));
    });
  });

  group('ReadingAnalyticsView Widget Tests', () {
    testWidgets('renders all metric sections, heatmap grid and peak hours', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = ReadingAnalyticsController();
      await tester.runAsync(() async {
        await controller.loadAnalytics();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ReadingAnalyticsView(controller: controller),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // Check Scaffold title
      expect(find.text('إحصائيات التلاوة والنشاط'), findsOneWidget);

      // Check Top metric titles
      expect(find.text('سلسلة متواصلة'), findsOneWidget);
      expect(find.text('إجمالي المقروء'), findsOneWidget);
      expect(find.text('الختمة الحالية'), findsOneWidget);
      expect(find.text('زمن التلاوة'), findsOneWidget);

      // Check Heatmap section header
      expect(find.text('تقويم النشاط والقراءة التفاعلي'), findsOneWidget);

      // Check Peak Hours breakdown section
      expect(find.text('أوقات الذروة للقراءة وتوزيع اليوم'), findsOneWidget);

      // Check Weekly Goal section
      expect(find.text('الهدف القرآني الأسبوعي'), findsOneWidget);

      // Check Share button
      expect(find.text('مشاركة بطاقة إنجازي القرآني'), findsOneWidget);
    });
  });
}
