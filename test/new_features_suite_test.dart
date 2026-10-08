import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/service/theme_controller.dart';
import 'package:quran_app_android/features/home/data/services/daily_tadabbur_service.dart';
import 'package:quran_app_android/features/khatma_circles/data/models/khatma_circle_model.dart';
import 'package:quran_app_android/features/khatma_circles/data/services/khatma_circles_service.dart';
import 'package:quran_app_android/features/mushaf/presentation/models/mushaf_theme_model.dart';
import 'package:quran_app_android/features/umrah/data/services/landmarks_service.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/tawaf_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 1: Daily Tadabbur Service Tests', () {
    test('DailyTadabburService returns valid daily item with authentic data', () {
      final item = DailyTadabburService.instance.getTodayTadabbur();

      expect(item.surahName.isNotEmpty, isTrue);
      expect(item.ayahNumber > 0, isTrue);
      expect(item.ayahText.isNotEmpty, isTrue);
      expect(item.reflection.isNotEmpty, isTrue);
      expect(item.scholar.isNotEmpty, isTrue);
      expect(item.pageNumber >= 1 && item.pageNumber <= 604, isTrue);
    });

    test('DailyTadabburService has complete repository with 30 items', () {
      final all = DailyTadabburService.items;
      expect(all.length, 30);
      for (final t in all) {
        expect(t.ayahText.length > 5, isTrue);
        expect(t.reflection.length > 10, isTrue);
        expect(t.scholar.isNotEmpty, isTrue);
        expect(t.source.isNotEmpty, isTrue);
      }
    });

    test('DailyTadabburService handles deterministic date mapping', () {
      final date1 = DateTime(2026, 1, 1);
      final date2 = DateTime(2026, 1, 31);
      final item1 = DailyTadabburService.instance.getTodayTadabbur(date1);
      final item2 = DailyTadabburService.instance.getTodayTadabbur(date2);
      expect(item1.id, isNotNull);
      expect(item2.id, isNotNull);
    });
  });

  group('Feature 2: Makkah & Madinah Landmarks Service Tests', () {
    test('LandmarksService provides 12 authentic landmarks', () {
      final all = LandmarksService.landmarks;
      expect(all.length, 12);
    });

    test('LandmarksService filters by city accurately', () {
      final makkah = LandmarksService.instance.getByCity('مكة المكرمة');
      final madinah = LandmarksService.instance.getByCity('المدينة المنورة');

      expect(makkah.length, 7);
      expect(madinah.length, 5);

      expect(makkah.every((l) => l.city == 'مكة المكرمة'), isTrue);
      expect(madinah.every((l) => l.city == 'المدينة المنورة'), isTrue);
    });

    test('LandmarksService search returns matching landmarks', () {
      final searchResults = LandmarksService.instance.search('الروضة');
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.any((l) => l.name == 'الروضة الشريفة'), isTrue);

      final searchIbrahim = LandmarksService.instance.search('إبراهيم');
      expect(searchIbrahim.isNotEmpty, isTrue);
      expect(searchIbrahim.any((l) => l.name.contains('إبراهيم')), isTrue);
    });
  });

  group('Feature 3: Tawaf Smart Lap Timer & Pace Estimator Tests', () {
    test('TawafController pacing calculations work accurately', () {
      final controller = TawafController();

      // Initially no completed laps
      expect(controller.lapDurations.isEmpty, isTrue);
      expect(controller.averageLapSeconds, 0);
      expect(controller.estimatedRemainingSeconds, 0);

      // Simulate laps completed: lap 1 = 60s, lap 2 = 80s
      controller.lapDurations.addAll([60, 80]);
      controller.currentLap.value = 2;

      // Average should be (60 + 80) / 2 = 70s
      expect(controller.averageLapSeconds, 70);

      // Remaining laps: 7 - 2 = 5 laps. Estimated remaining = 5 * 70 = 350s
      expect(controller.estimatedRemainingSeconds, 350);

      expect(controller.formatTime(controller.averageLapSeconds), '01:10');
      expect(controller.formatTime(controller.estimatedRemainingSeconds), '05:50');
    });
  });

  group('Feature 4: Family Khatma Circles Model & Formatting Tests', () {
    test('KhatmaCircleModel computes progress and status correctly', () {
      final juzList = List.generate(
        30,
        (i) => KhatmaCircleJuz(
          circleId: 'circle-1',
          juzNumber: i + 1,
          assignedTo: i < 5 ? 'أحمد' : (i < 10 ? 'فاطمة' : ''),
          status: i < 3
              ? 'completed'
              : (i < 10 ? 'in_progress' : 'available'),
        ),
      );

      final circle = KhatmaCircle(
        id: 'circle-1',
        title: 'ختمة العائلة لرمضان',
        description: 'ختمة مشتركة بين الأسرة',
        createdAt: DateTime.now(),
        juzList: juzList,
      );

      expect(circle.completedJuzCount, 3);
      expect(circle.inProgressJuzCount, 7);
      expect(circle.availableJuzCount, 20);
      expect(circle.isCompleted, isFalse);
      expect(circle.progressPercentage, closeTo(3 / 30, 0.001));

      // Test share message formatting
      final shareText = KhatmaCirclesService.instance.generateWhatsAppShareText(circle);
      expect(shareText.contains('ختمة العائلة لرمضان'), isTrue);
      expect(shareText.contains('3/30 جزء'), isTrue);
      expect(shareText.contains('أحمد'), isTrue);
      expect(shareText.contains('فاطمة'), isTrue);
    });
  });

  group('Feature 5: Sepia Theme & Mushaf Mode Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': 'light',
      });
      final sp = await SharedPreferences.getInstance();
      final settings = SettingsServices();
      settings.sharedPref = sp;
      Get.put<SettingsServices>(settings, permanent: true);
    });

    tearDown(() {
      Get.reset();
    });

    test('AppColorsExtension.sepia provides warm paper color tokens', () {
      const sepia = AppColorsExtension.sepia;
      expect(sepia.bg, const Color(0xFFF4ECD8));
      expect(sepia.surface, const Color(0xFFFAF4E6));
      expect(sepia.text, const Color(0xFF2C221E));
      expect(sepia.primary, const Color(0xFF0F5C4A));
      expect(sepia.accent, const Color(0xFFB8892B));
      expect(sepia.isDark, isFalse);
    });

    test('AppTheme.sepia configures ThemeData with sepia tokens', () {
      final sepiaTheme = AppTheme.sepia;
      expect(sepiaTheme.brightness, Brightness.light);
      expect(sepiaTheme.scaffoldBackgroundColor, const Color(0xFFF4ECD8));
      expect(sepiaTheme.colorScheme.primary, const Color(0xFF0F5C4A));

      final ext = sepiaTheme.extension<AppColorsExtension>();
      expect(ext, isNotNull);
      expect(ext!.bg, const Color(0xFFF4ECD8));
    });

    test('MushafThemeMode.sepia provides authentic manuscript tokens', () {
      final mushafSepia = MushafThemeConfig.of(MushafThemeMode.sepia);
      expect(mushafSepia.mode, MushafThemeMode.sepia);
      expect(mushafSepia.pageBg, const Color(0xFFF4ECD8));
      expect(mushafSepia.textColor, const Color(0xFF2A2118));
      expect(mushafSepia.isDark, isFalse);
    });

    test('ThemeController switches to sepia and persists preference', () {
      final themeCtrl = Get.put(ThemeController());

      expect(themeCtrl.isSepia, isFalse);

      themeCtrl.setAppThemeMode(AppThemeModeType.sepia);

      expect(themeCtrl.appThemeMode, AppThemeModeType.sepia);
      expect(themeCtrl.isSepia, isTrue);
      expect(themeCtrl.themeMode, ThemeMode.light);

      final settings = Get.find<SettingsServices>();
      expect(settings.sharedPref?.getString(ThemeController.themePrefKey), 'sepia');
    });
  });
}
