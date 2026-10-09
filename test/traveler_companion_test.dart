import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/features/traveler_companion/data/models/travel_dua_model.dart';
import 'package:quran_app_android/features/traveler_companion/data/models/travel_rule_model.dart';
import 'package:quran_app_android/features/traveler_companion/data/models/wiping_timer_model.dart';
import 'package:quran_app_android/features/traveler_companion/data/repositories/traveler_repository.dart';
import 'package:quran_app_android/features/traveler_companion/presentation/controllers/traveler_companion_controller.dart';
import 'package:quran_app_android/features/traveler_companion/presentation/views/traveler_companion_view.dart';
import 'package:quran_app_android/features/traveler_companion/presentation/widgets/wiping_timer_tab.dart';
import 'package:quran_app_android/features/traveler_companion/presentation/widgets/travel_fiqh_guide_tab.dart';
import 'package:quran_app_android/features/traveler_companion/presentation/widgets/travel_duas_tab.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('WipingTimerState Unit Tests', () {
    test('start factory creates 72h for traveler and 24h for resident', () {
      final now = DateTime(2026, 10, 9, 12, 0);

      final traveler = WipingTimerState.start(isTraveler: true, startTime: now);
      expect(traveler.isTraveler, isTrue);
      expect(traveler.durationHours, equals(72));
      expect(traveler.expiresAt, equals(now.add(const Duration(hours: 72))));

      final resident = WipingTimerState.start(isTraveler: false, startTime: now);
      expect(resident.isTraveler, isFalse);
      expect(resident.durationHours, equals(24));
      expect(resident.expiresAt, equals(now.add(const Duration(hours: 24))));
    });

    test('remaining and progress calculation', () {
      final start = DateTime(2026, 10, 9, 10, 0);
      final timer = WipingTimerState.start(isTraveler: false, startTime: start);

      // Halfway (12 hours elapsed)
      final mid = start.add(const Duration(hours: 12));
      expect(timer.remaining(mid), equals(const Duration(hours: 12)));
      expect(timer.progress(mid), closeTo(0.5, 0.01));
      expect(timer.isExpired(mid), isFalse);
      expect(timer.isWarning(mid), isFalse);

      // 1 hour left (warning)
      final nearEnd = start.add(const Duration(hours: 23));
      expect(timer.isWarning(nearEnd), isTrue);
      expect(timer.isExpired(nearEnd), isFalse);

      // Expired (25 hours elapsed)
      final after = start.add(const Duration(hours: 25));
      expect(timer.isExpired(after), isTrue);
      expect(timer.remaining(after), equals(Duration.zero));
      expect(timer.progress(after), equals(1.0));
    });

    test('toMap and fromMap serialization', () {
      final start = DateTime(2026, 10, 9, 14, 30);
      final timer = WipingTimerState.start(isTraveler: true, startTime: start, notes: 'سفر إلى مكة');

      final map = timer.toMap();
      final restored = WipingTimerState.fromMap(map);

      expect(restored.isActive, isTrue);
      expect(restored.isTraveler, isTrue);
      expect(restored.durationHours, equals(72));
      expect(restored.startedAt.toIso8601String(), equals(start.toIso8601String()));
      expect(restored.notes, equals('سفر إلى مكة'));
    });
  });

  group('TravelerRepository Unit Tests', () {
    final repo = TravelerRepository.instance;

    test('getRules returns comprehensive classical Fiqh dataset', () {
      final rules = repo.getRules();
      expect(rules.isNotEmpty, isTrue);
      expect(rules.length, greaterThanOrEqualTo(8));

      // Contains key topics
      expect(rules.any((r) => r.category == TravelRuleCategory.travelDistance), isTrue);
      expect(rules.any((r) => r.category == TravelRuleCategory.shorteningAndCombining), isTrue);
      expect(rules.any((r) => r.category == TravelRuleCategory.planeAndTrain), isTrue);
      expect(rules.any((r) => r.category == TravelRuleCategory.sunnahPrayers), isTrue);
      expect(rules.any((r) => r.category == TravelRuleCategory.fastingConcession), isTrue);
      expect(rules.any((r) => r.category == TravelRuleCategory.wipingKhuffain), isTrue);
    });

    test('getRulesByCategory filters properly', () {
      final prayerRules = repo.getRulesByCategory(TravelRuleCategory.shorteningAndCombining);
      expect(prayerRules.isNotEmpty, isTrue);
      expect(prayerRules.every((r) => r.category == TravelRuleCategory.shorteningAndCombining), isTrue);
    });

    test('getDuas returns authentic travel supplications', () {
      final duas = repo.getDuas();
      expect(duas.isNotEmpty, isTrue);
      expect(duas.length, greaterThanOrEqualTo(6));

      expect(duas.any((d) => d.category == TravelDuaCategory.mounting), isTrue);
      expect(duas.any((d) => d.category == TravelDuaCategory.journey), isTrue);
      expect(duas.any((d) => d.category == TravelDuaCategory.farewell), isTrue);
      expect(duas.any((d) => d.category == TravelDuaCategory.takbeer), isTrue);
    });

    test('timer persistence save, get, and clear', () async {
      final timer = WipingTimerState.start(isTraveler: true);
      await repo.saveTimerState(timer);

      final loaded = await repo.getTimerState();
      expect(loaded, isNotNull);
      expect(loaded!.isTraveler, isTrue);
      expect(loaded.durationHours, equals(72));

      await repo.clearTimerState();
      final afterClear = await repo.getTimerState();
      expect(afterClear, isNull);
    });
  });

  group('TravelerCompanionController Unit Tests', () {
    test('startTimer, resetTimer, and stopTimer update reactive state', () async {
      final controller = TravelerCompanionController();
      expect(controller.timerState.value, isNull);

      await controller.startTimer(isTraveler: true);
      expect(controller.timerState.value, isNotNull);
      expect(controller.timerState.value!.isTraveler, isTrue);
      expect(controller.timerState.value!.durationHours, equals(72));

      await controller.resetTimer();
      expect(controller.timerState.value, isNotNull);

      await controller.stopTimer();
      expect(controller.timerState.value, isNull);
    });

    test('dua counter increment and reset', () {
      final controller = TravelerCompanionController();
      const duaId = 'dua_test_1';

      expect(controller.getDuaCount(duaId), equals(0));
      controller.incrementDua(duaId, 3);
      expect(controller.getDuaCount(duaId), equals(1));
      controller.incrementDua(duaId, 3);
      expect(controller.getDuaCount(duaId), equals(2));

      controller.resetDua(duaId);
      expect(controller.getDuaCount(duaId), equals(0));
    });
  });

  group('Traveler Companion Presentation Widget Tests', () {
    testWidgets('TravelerCompanionView renders cleanly with 3 tabs', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: TravelerCompanionView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('مساعد المسافر ورخص السفر'), findsOneWidget);
      expect(find.text('مؤقت المسح'), findsOneWidget);
      expect(find.text('دليل الرخص'), findsOneWidget);
      expect(find.text('أدعية السفر'), findsOneWidget);
      expect(find.byType(WipingTimerTab), findsOneWidget);
    });

    testWidgets('WipingTimerTab shows start options when inactive', (tester) async {
      final controller = Get.put(TravelerCompanionController());
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: WipingTimerTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أنا مسافر'), findsOneWidget);
      expect(find.text('أنا مقيم'), findsOneWidget);
      expect(find.textContaining('شروط وضوابط المسح'), findsOneWidget);
    });

    testWidgets('TravelFiqhGuideTab renders filter chips and rules', (tester) async {
      final controller = Get.put(TravelerCompanionController());
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: TravelFiqhGuideTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('الجمع والقصر'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('TravelDuasTab renders travel Dhikr cards', (tester) async {
      final controller = Get.put(TravelerCompanionController());
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: TravelDuasTab(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('دعاء السفر العام'), findsWidgets);
      expect(find.byType(TravelDuasTab), findsOneWidget);
    });
  });
}
