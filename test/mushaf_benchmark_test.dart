import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/data/models/mushaf_models.dart';
import 'package:quran_app_android/core/mushaf/mushaf_font_manager.dart';
import 'package:quran_app_android/features/mushaf/presentation/models/mushaf_theme_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/widgets/mushaf_page_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async => null,
    );
  });

  group('Mushaf Performance & Frame Timing Baseline', () {
    test('Measure individual TTF font loading from assets', () async {
      final samplePages = [1, 77, 250, 400, 586];
      final loadTimes = <int, int>{};

      for (final page in samplePages) {
        final file = File('assets/fonts/qpc_v2/p$page.ttf');
        expect(file.existsSync(), isTrue);

        final sw = Stopwatch()..start();
        final bytes = await file.readAsBytes();
        final fontLoader = FontLoader(MushafFontManager.pageFontFamily(page));
        fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await fontLoader.load();
        sw.stop();
        loadTimes[page] = sw.elapsedMicroseconds;
      }

      final avgMicros = loadTimes.values.reduce((a, b) => a + b) / loadTimes.length;
      final avgMs = avgMicros / 1000.0;
      debugPrint('📊 [Font Load Baseline] Avg font load time: ${avgMs.toStringAsFixed(2)} ms per page font');
      for (final e in loadTimes.entries) {
        debugPrint('   Page ${e.key}: ${(e.value / 1000.0).toStringAsFixed(2)} ms (${(File("assets/fonts/qpc_v2/p${e.key}.ttf").lengthSync() / 1024).toStringAsFixed(1)} KB)');
      }
    });

    testWidgets('Measure Page Widget build and layout duration during page flips', (tester) async {
      // Mock page data for 5 consecutive pages
      final pages = List.generate(5, (pIdx) {
        final pageNum = pIdx + 1;
        return MushafPage(
          pageNumber: pageNum,
          surahNumber: 1,
          surahNameAr: 'الفاتحة',
          juzNumber: 1,
          lines: List.generate(15, (lIdx) {
            final lineNum = lIdx + 1;
            return MushafLine(
              id: (pageNum * 100) + lineNum,
              pageNumber: pageNum,
              lineNumber: lineNum,
              lineType: lineNum == 1 ? MushafLineType.surahHeader : (lineNum == 2 ? MushafLineType.basmalah : MushafLineType.ayah),
              surahNumber: 1,
              words: List.generate(8, (wIdx) => MushafWord(
                pageNumber: pageNum,
                lineNumber: lineNum,
                wordIndex: wIdx + 1,
                surahNumber: 1,
                ayahNumber: 1,
                location: '$pageNum:$lineNum:${wIdx + 1}',
                textUthmani: 'ﱁ',
                glyphCode: 'ﱁ',
              )),
            );
          }),
        );
      });

      final theme = MushafThemeConfig.light;
      final buildDurations = <int>[];
      int jankFrames = 0; // frames taking > 16.6 ms (target 60fps)

      for (int i = 0; i < pages.length; i++) {
        final sw = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 900,
                child: MushafPageWidget(
                  page: pages[i],
                  theme: theme,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        sw.stop();

        final elapsedMs = sw.elapsedMilliseconds;
        buildDurations.add(elapsedMs);
        if (elapsedMs > 16) {
          jankFrames++;
        }
      }

      final avgBuildMs = buildDurations.reduce((a, b) => a + b) / buildDurations.length;
      debugPrint('📊 [Page Build Baseline] Avg page build + layout time: ${avgBuildMs.toStringAsFixed(2)} ms');
      debugPrint('📊 [Frame Drop Baseline] Frames > 16.6ms: $jankFrames / ${buildDurations.length} (${(jankFrames / buildDurations.length * 100).toStringAsFixed(1)}%)');
      for (int i = 0; i < buildDurations.length; i++) {
        debugPrint('   Page ${i + 1} render time: ${buildDurations[i]} ms');
      }
    });
  });
}
