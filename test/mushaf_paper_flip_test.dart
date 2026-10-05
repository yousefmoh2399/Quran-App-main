import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/models/mushaf_models.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/mushaf/presentation/controllers/mushaf_controller.dart';
import 'package:quran_app_android/features/mushaf/presentation/models/mushaf_theme_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/widgets/mushaf_paper_flip_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final pref = await SharedPreferences.getInstance();
    final settings = SettingsServices();
    settings.sharedPref = pref;
    Get.put(settings);
  });

  tearDownAll(() {
    Get.reset();
  });

  MushafPage createDummyPage(int pageNum) {
    return MushafPage(
      pageNumber: pageNum,
      lines: [
        MushafLine(
          id: pageNum * 100,
          pageNumber: pageNum,
          lineNumber: 1,
          lineType: MushafLineType.ayah,
          text: 'صفحة $pageNum سطر ١',
          words: [
            MushafWord(
              pageNumber: pageNum,
              lineNumber: 1,
              wordIndex: 1,
              surahNumber: 1,
              ayahNumber: 1,
              location: '1:1:1',
              textUthmani: 'صفحة $pageNum',
              glyphCode: 'ﭑ',
            ),
          ],
        ),
      ],
      surahNumber: 1,
      surahNameAr: 'الفاتحة',
      juzNumber: 1,
    );
  }

  group('MushafPaperFlipView Tests', () {
    testWidgets('renders current page cleanly and binds to controller', (tester) async {
      final controller = Get.put(MushafController());
      final page1 = createDummyPage(1);
      final pagesCache = <int, MushafPage>{1: page1};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPaperFlipView(
              currentPage: 1,
              theme: MushafThemeConfig.light,
              pagesCache: pagesCache,
              getPage: (p) async => createDummyPage(p),
              onPageChanged: (_) {},
              onAyahTapped: (_, __) {},
              onTapPage: () {},
              getPageBookmarkColor: (_) => null,
              getPageMemorizeStatus: (_) => null,
              getAyahBookmarkColors: () => {},
              getAyahMemorizeStatuses: () => {},
              controller: controller,
              enablePrewarm: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MushafPaperFlipView), findsOneWidget);
      expect(controller.paperFlipState, isNotNull);
      expect(find.text('ﭑ'), findsOneWidget);

      Get.delete<MushafController>();
    });

    testWidgets('turnNext triggers smooth paper flip animation to exact page + 1', (tester) async {
      final controller = Get.put(MushafController());
      final page1 = createDummyPage(1);
      final page2 = createDummyPage(2);
      final pagesCache = <int, MushafPage>{1: page1, 2: page2};

      int? changedTo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPaperFlipView(
              currentPage: 1,
              theme: MushafThemeConfig.light,
              pagesCache: pagesCache,
              getPage: (p) async => createDummyPage(p),
              onPageChanged: (newPage) {
                changedTo = newPage;
              },
              onAyahTapped: (_, __) {},
              onTapPage: () {},
              getPageBookmarkColor: (_) => null,
              getPageMemorizeStatus: (_) => null,
              getAyahBookmarkColors: () => {},
              getAyahMemorizeStatuses: () => {},
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger programmatic next turn
      await controller.paperFlipState!.turnNext();
      await tester.pump();
      expect(controller.isPageTurning.value, isTrue);

      // Advance animation to completion
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(changedTo, equals(2));
      expect(controller.isPageTurning.value, isFalse);

      Get.delete<MushafController>();
    });

    testWidgets('turnPrevious triggers smooth paper flip animation to exact page - 1', (tester) async {
      final controller = Get.put(MushafController());
      final page2 = createDummyPage(2);
      final page1 = createDummyPage(1);
      final pagesCache = <int, MushafPage>{2: page2, 1: page1};

      int? changedTo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPaperFlipView(
              currentPage: 2,
              theme: MushafThemeConfig.light,
              pagesCache: pagesCache,
              getPage: (p) async => createDummyPage(p),
              onPageChanged: (newPage) {
                changedTo = newPage;
              },
              onAyahTapped: (_, __) {},
              onTapPage: () {},
              getPageBookmarkColor: (_) => null,
              getPageMemorizeStatus: (_) => null,
              getAyahBookmarkColors: () => {},
              getAyahMemorizeStatuses: () => {},
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger programmatic previous turn
      await controller.paperFlipState!.turnPrevious();
      await tester.pump();
      expect(controller.isPageTurning.value, isTrue);

      // Advance animation to completion
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(changedTo, equals(1));
      expect(controller.isPageTurning.value, isFalse);

      Get.delete<MushafController>();
    });

    testWidgets('horizontal swipe right in Arabic turns forward to next page + 1', (tester) async {
      final controller = Get.put(MushafController());
      final page1 = createDummyPage(1);
      final page2 = createDummyPage(2);
      final pagesCache = <int, MushafPage>{1: page1, 2: page2};

      int? changedTo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPaperFlipView(
              currentPage: 1,
              theme: MushafThemeConfig.light,
              pagesCache: pagesCache,
              getPage: (p) async => createDummyPage(p),
              onPageChanged: (newPage) {
                changedTo = newPage;
              },
              onAyahTapped: (_, __) {},
              onTapPage: () {},
              getPageBookmarkColor: (_) => null,
              getPageMemorizeStatus: (_) => null,
              getAyahBookmarkColors: () => {},
              getAyahMemorizeStatuses: () => {},
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Swipe right across the screen (drag by +300px in Arabic RTL to turn forward)
      await tester.drag(find.byType(MushafPaperFlipView), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(changedTo, equals(2));

      Get.delete<MushafController>();
    });

    testWidgets('horizontal swipe left in Arabic turns backward to previous page - 1', (tester) async {
      final controller = Get.put(MushafController());
      final page2 = createDummyPage(2);
      final page1 = createDummyPage(1);
      final pagesCache = <int, MushafPage>{2: page2, 1: page1};

      int? changedTo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPaperFlipView(
              currentPage: 2,
              theme: MushafThemeConfig.light,
              pagesCache: pagesCache,
              getPage: (p) async => createDummyPage(p),
              onPageChanged: (newPage) {
                changedTo = newPage;
              },
              onAyahTapped: (_, __) {},
              onTapPage: () {},
              getPageBookmarkColor: (_) => null,
              getPageMemorizeStatus: (_) => null,
              getAyahBookmarkColors: () => {},
              getAyahMemorizeStatuses: () => {},
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Swipe left across the screen (drag by -300px in Arabic RTL to turn backward)
      await tester.drag(find.byType(MushafPaperFlipView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(changedTo, equals(1));

      Get.delete<MushafController>();
    });

    testWidgets('tapping page toggles overlay', (tester) async {
      final controller = Get.put(MushafController());
      final page1 = createDummyPage(1);
      final pagesCache = <int, MushafPage>{1: page1};

      bool overlayToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MushafPaperFlipView(
              currentPage: 1,
              theme: MushafThemeConfig.light,
              pagesCache: pagesCache,
              getPage: (p) async => createDummyPage(p),
              onPageChanged: (newPage) {},
              onAyahTapped: (_, __) {},
              onTapPage: () {
                overlayToggled = true;
              },
              getPageBookmarkColor: (_) => null,
              getPageMemorizeStatus: (_) => null,
              getAyahBookmarkColors: () => {},
              getAyahMemorizeStatuses: () => {},
              controller: controller,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(MushafPaperFlipView));
      await tester.pumpAndSettle();
      expect(overlayToggled, isTrue);

      Get.delete<MushafController>();
    });
  });
}
