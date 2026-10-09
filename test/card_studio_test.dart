import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/card_studio/data/models/card_studio_theme_preset.dart';
import 'package:quran_app_android/features/card_studio/presentation/controllers/card_studio_controller.dart';
import 'package:quran_app_android/features/card_studio/presentation/widgets/card_canvas_widget.dart';
import 'package:quran_app_android/features/card_studio/presentation/widgets/islamic_frame_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final settings = SettingsServices();
    settings.sharedPref = sp;
    Get.put<SettingsServices>(settings, permanent: true);
  });

  group('Card Studio Model & Presets Tests', () {
    test('CardStudioThemePreset provides 5 authentic presets with rich colors', () {
      expect(CardStudioThemePreset.presets.length, 5);

      final parchment = CardStudioThemePreset.parchment;
      expect(parchment.id, 'parchment');
      expect(parchment.isDark, isFalse);
      expect(parchment.bgGradient.length, 2);

      final emerald = CardStudioThemePreset.emerald;
      expect(emerald.id, 'emerald');
      expect(emerald.isDark, isTrue);

      final midnight = CardStudioThemePreset.midnight;
      expect(midnight.id, 'midnight');
      expect(midnight.isDark, isTrue);

      final marble = CardStudioThemePreset.marble;
      expect(marble.id, 'marble');
      expect(marble.isDark, isFalse);

      final charcoal = CardStudioThemePreset.charcoal;
      expect(charcoal.id, 'charcoal');
      expect(charcoal.isDark, isTrue);
    });

    test('CardStudioThemePreset fromId resolves existing and falls back gracefully', () {
      expect(CardStudioThemePreset.fromId('emerald').id, 'emerald');
      expect(CardStudioThemePreset.fromId('non_existent').id, 'parchment');
    });

    test('CardAspectRatio defines correct dimensions for Stories and Posts', () {
      expect(CardAspectRatio.story.ratio, closeTo(9 / 16, 0.001));
      expect(CardAspectRatio.story.targetWidth, 1080);
      expect(CardAspectRatio.story.targetHeight, 1920);

      expect(CardAspectRatio.square.ratio, 1.0);
      expect(CardAspectRatio.square.targetWidth, 1080);
      expect(CardAspectRatio.square.targetHeight, 1080);

      expect(CardAspectRatio.card.ratio, closeTo(4 / 5, 0.001));
    });

    test('CardIslamicFrameStyle defines all architectural frame variants', () {
      expect(CardIslamicFrameStyle.values.length, 4);
      expect(CardIslamicFrameStyle.values.contains(CardIslamicFrameStyle.andalusian), isTrue);
      expect(CardIslamicFrameStyle.values.contains(CardIslamicFrameStyle.mihrab), isTrue);
      expect(CardIslamicFrameStyle.values.contains(CardIslamicFrameStyle.classic), isTrue);
      expect(CardIslamicFrameStyle.values.contains(CardIslamicFrameStyle.none), isTrue);
    });
  });

  group('CardStudioController Tests', () {
    late CardStudioController controller;

    setUp(() {
      Get.delete<CardStudioController>();
      controller = Get.put(CardStudioController());
    });

    test('Initializes with default Quran mode and allows initWithArguments', () {
      expect(controller.contentMode.value, CardContentMode.quran);

      controller.initWithArguments(
        text: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
        surahName: 'الشرح',
        ayahNumber: 6,
        tafsir: 'مع الشدة فرج ورخاء',
      );

      expect(controller.mainText.value, 'إِنَّ مَعَ الْعُسْرِ يُسْرًا');
      expect(controller.subtitleText.value, 'الشرح • آية 6');
      expect(controller.tafsirOrNote.value, 'مع الشدة فرج ورخاء');
    });

    test('Switching content mode updates formatting flags accordingly', () {
      controller.setContentMode(CardContentMode.zikr);
      expect(controller.contentMode.value, CardContentMode.zikr);
      expect(controller.showBismillah.value, isFalse);
      expect(controller.showBrackets.value, isFalse);
      expect(controller.mainText.value.isNotEmpty, isTrue);

      controller.setContentMode(CardContentMode.tadabbur);
      expect(controller.contentMode.value, CardContentMode.tadabbur);
      expect(controller.showBismillah.value, isTrue);
      expect(controller.showBrackets.value, isTrue);
    });

    test('Preset, Ratio, Frame, and Font setters update reactive states', () {
      controller.setPreset(CardStudioThemePreset.midnight);
      expect(controller.selectedPreset.value.id, 'midnight');

      controller.setRatio(CardAspectRatio.square);
      expect(controller.selectedRatio.value, CardAspectRatio.square);

      controller.setFrame(CardIslamicFrameStyle.mihrab);
      expect(controller.selectedFrame.value, CardIslamicFrameStyle.mihrab);

      controller.setFont(CardStudioFontFamily.cairo);
      expect(controller.selectedFont.value, CardStudioFontFamily.cairo);
    });
  });

  group('CardCanvasWidget Widget & CustomPainter Tests', () {
    testWidgets('CardCanvasWidget renders cleanly without overflow across ratios', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: CardCanvasWidget(
                  preset: CardStudioThemePreset.emerald,
                  frameStyle: CardIslamicFrameStyle.andalusian,
                  font: CardStudioFontFamily.uthman,
                  ratio: CardAspectRatio.story,
                  mainText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
                  subtitleText: 'سورة البقرة • آية 255',
                  tafsirOrNote: 'الله المتفرد بالألوهية، القائم بتدبير خلقه',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CardCanvasWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('سورة البقرة • آية 255'), findsOneWidget);
      expect(find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'), findsOneWidget);
      expect(find.text('تطبيق تقرّب • أوفلاين'), findsOneWidget);
    });

    testWidgets('IslamicFramePainter paints without errors for all 4 styles', (tester) async {
      for (final style in CardIslamicFrameStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(200, 300),
                painter: IslamicFramePainter(
                  style: style,
                  borderColor: const Color(0xFFD4AF37),
                  accentColor: const Color(0xFFE5C058),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
