import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/mushaf/mushaf_raster_cache.dart';
import 'package:quran_app_android/features/mushaf/presentation/models/mushaf_theme_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/widgets/mushaf_page_curl_painter.dart';

void main() {
  group('MushafRasterCache Tests', () {
    setUp(() {
      MushafRasterCache.instance.clear();
    });

    test('Hit and miss tracking works accurately', () {
      final cache = MushafRasterCache.instance;
      expect(cache.hits, 0);
      expect(cache.misses, 0);
      expect(cache.hitRatio, 0.0);

      // Miss on non-existent page
      final result1 = cache.get(100, MushafThemeMode.light);
      expect(result1, isNull);
      expect(cache.misses, 1);
      expect(cache.hits, 0);
      expect(cache.hitRatio, 0.0);
    });

    test('Memory estimation computes correctly (RGBA 4 bytes/pixel)', () async {
      final cache = MushafRasterCache.instance;

      // Create a test 100x200 pixel image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(Colors.amber, BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(100, 200);

      cache.put(1, MushafThemeMode.light, image);
      expect(cache.length, 1);

      // 100 * 200 * 4 = 80,000 bytes
      expect(cache.estimatedMemoryBytes, 80000);
      expect(cache.estimatedMemoryMB, closeTo(80000 / (1024 * 1024), 0.001));

      // Hit retrieval
      final retrieved = cache.get(1, MushafThemeMode.light);
      expect(retrieved, isNotNull);
      expect(cache.hits, 1);
      expect(cache.hitRatio, 1.0);

      cache.clear();
      expect(cache.length, 0);
      expect(cache.estimatedMemoryBytes, 0);
    });

    test('LRU capacity enforces max 5 pages and evicts oldest', () async {
      final cache = MushafRasterCache.instance;

      for (int i = 1; i <= 6; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(Colors.white, BlendMode.src);
        final pic = recorder.endRecording();
        final img = await pic.toImage(50, 50);
        cache.put(i, MushafThemeMode.light, img);
      }

      // Max capacity is 5, so page 1 should have been evicted
      expect(cache.length, 5);
      expect(cache.has(1, MushafThemeMode.light), isFalse);
      expect(cache.has(6, MushafThemeMode.light), isTrue);

      cache.clear();
    });
  });

  group('MushafPageCurlPainter Tests', () {
    test('Paints cleanly across all progress stages without throwing exceptions', () {
      final theme = MushafThemeConfig.light;
      const size = Size(360, 800);

      final stages = [0.0, 0.15, 0.25, 0.50, 0.75, 0.90, 1.0];

      for (final t in stages) {
        // Forward turn (100 -> 101)
        final painterForward = MushafPageCurlPainter(
          frontImage: null,
          backImage: null,
          progress: t,
          isForward: true,
          theme: theme,
          isRightPage: false,
        );

        final recorderForward = ui.PictureRecorder();
        final canvasForward = Canvas(recorderForward);
        expect(() => painterForward.paint(canvasForward, size), returnsNormally);

        // Backward turn (101 -> 100)
        final painterBackward = MushafPageCurlPainter(
          frontImage: null,
          backImage: null,
          progress: t,
          isForward: false,
          theme: theme,
          isRightPage: true,
        );

        final recorderBackward = ui.PictureRecorder();
        final canvasBackward = Canvas(recorderBackward);
        expect(() => painterBackward.paint(canvasBackward, size), returnsNormally);
      }
    });

    test('Paints cleanly with real ui.Image textures', () async {
      final theme = MushafThemeConfig.light;
      const size = Size(360, 800);

      // Create dummy front and back textures
      final r1 = ui.PictureRecorder();
      final c1 = Canvas(r1);
      c1.drawColor(Colors.amber.shade100, BlendMode.src);
      final frontImg = await r1.endRecording().toImage(360, 800);

      final r2 = ui.PictureRecorder();
      final c2 = Canvas(r2);
      c2.drawColor(Colors.teal.shade100, BlendMode.src);
      final backImg = await r2.endRecording().toImage(360, 800);

      final painter = MushafPageCurlPainter(
        frontImage: frontImg,
        backImage: backImg,
        progress: 0.50, // Peak cylinder curl
        isForward: true,
        theme: theme,
        isRightPage: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, size), returnsNormally);

      frontImg.dispose();
      backImg.dispose();
    });

    test('shouldRepaint detects changes accurately', () {
      final theme = MushafThemeConfig.light;

      final p1 = MushafPageCurlPainter(
        frontImage: null,
        backImage: null,
        progress: 0.3,
        isForward: true,
        theme: theme,
        isRightPage: false,
      );

      final p2 = MushafPageCurlPainter(
        frontImage: null,
        backImage: null,
        progress: 0.3,
        isForward: true,
        theme: theme,
        isRightPage: false,
      );

      final p3 = MushafPageCurlPainter(
        frontImage: null,
        backImage: null,
        progress: 0.6,
        isForward: true,
        theme: theme,
        isRightPage: false,
      );

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p1.shouldRepaint(p3), isTrue);
    });
  });
}
