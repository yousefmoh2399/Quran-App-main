import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/service/theme_controller.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widgets/smart_zikr_card.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_nav_bar.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_quick_shortcuts.dart';
import 'package:quran_app_android/features/settings/presentation/views/settings_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'mushaf_last_page': 1,
      'theme_mode': 'light',
    });
    final sp = await SharedPreferences.getInstance();
    final settings = SettingsServices();
    settings.sharedPref = sp;
    Get.put<SettingsServices>(settings, permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
  });

  Widget buildTestApp({
    required Widget child,
    ThemeData? theme,
    double width = 320.0,
    double height = 640.0,
    double textScale = 1.0,
  }) {
    return GetMaterialApp(
      theme: theme ?? AppTheme.light,
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

  group('UX Simplification & Responsive Tests', () {
    testWidgets('HomeQuickShortcuts renders all 6 shortcuts cleanly at 320dp',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestApp(
          child: const SingleChildScrollView(
            child: HomeQuickShortcuts(),
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('اختصارات سريعة'), findsOneWidget);
      expect(find.text('القبلة'), findsOneWidget);
      expect(find.text('السبحة'), findsOneWidget);
      expect(find.text('أسماء الله'), findsOneWidget);
      expect(find.text('الحديث'), findsOneWidget);
      expect(find.text('التقويم'), findsOneWidget);
      expect(find.text('سجل الصلوات'), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeNavBar has 5 tabs with Bookmarks and More', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      int tappedIndex = -1;

      await tester.pumpWidget(
        buildTestApp(
          child: HomeNavBar(
            currentIndex: 0,
            onTap: (i) => tappedIndex = i,
          ),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('المصحف'), findsOneWidget);
      expect(find.text('الأذكار'), findsOneWidget);
      expect(find.text('علاماتي والورد'), findsOneWidget);
      expect(find.text('المزيد'), findsOneWidget);

      await tester.tap(find.text('المزيد'));
      await tester.pump();
      expect(tappedIndex, equals(4));
    });

    testWidgets('SmartZikrCard renders without overflow at 320dp and 1.5 text scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      await tester.pumpWidget(
        buildTestApp(
          child: const SingleChildScrollView(
            child: SmartZikrCard(),
          ),
          width: 320,
          textScale: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SmartZikrCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsView (المزيد) renders all sections cleanly in Light & Dark mode',
        (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        await tester.pumpWidget(
          buildTestApp(
            theme: theme,
            child: const SettingsView(),
            width: 320,
            textScale: 1.2,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('المزيد'), findsOneWidget);
        expect(find.text('عباداتي'), findsOneWidget);
        expect(find.text('التذكيرات والتنبيهات'), findsOneWidget);
        expect(find.text('الأذان ومواقيت الصلاة'), findsOneWidget);
        expect(find.text('المظهر والسمة'), findsOneWidget);
        expect(find.text('النسخ الاحتياطي واستعادة البيانات'), findsOneWidget);
        expect(find.text('عن التطبيق والمصادر'), findsOneWidget);

        expect(tester.takeException(), isNull);
      }
    });
  });
}
