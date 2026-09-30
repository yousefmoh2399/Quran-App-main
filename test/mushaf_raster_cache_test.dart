import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/mushaf/mushaf_raster_cache.dart';
import 'package:quran_app_android/features/mushaf/presentation/models/mushaf_theme_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MushafRasterCache Tests', () {
    late MushafRasterCache cache;

    setUp(() {
      cache = MushafRasterCache.instance;
      cache.clear();
    });

    tearDown(() {
      cache.clear();
    });

    test('put and get store and retrieve image correctly', () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
      final picture = recorder.endRecording();
      final image = await picture.toImage(10, 10);

      cache.put(1, MushafThemeMode.light, image);
      expect(cache.has(1, MushafThemeMode.light), isTrue);
      expect(cache.has(2, MushafThemeMode.light), isFalse);
      expect(cache.length, equals(1));

      final retrieved = cache.get(1, MushafThemeMode.light);
      expect(retrieved, isNotNull);
      expect(retrieved, equals(image));
    });

    test('evicts oldest entry when maxCapacity (5) is exceeded', () async {
      final images = <ui.Image>[];
      for (int i = 1; i <= 6; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
        final picture = recorder.endRecording();
        final img = await picture.toImage(10, 10);
        images.add(img);
        cache.put(i, MushafThemeMode.light, img);
      }

      expect(cache.length, equals(MushafRasterCache.maxCapacity));
      expect(cache.has(1, MushafThemeMode.light), isFalse); // Evicted!
      expect(cache.has(2, MushafThemeMode.light), isTrue);
      expect(cache.has(6, MushafThemeMode.light), isTrue);
    });

    test('clear disposes all cached images', () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
      final picture = recorder.endRecording();
      final img = await picture.toImage(10, 10);

      cache.put(10, MushafThemeMode.dark, img);
      expect(cache.length, equals(1));

      cache.clear();
      expect(cache.length, equals(0));
      expect(cache.has(10, MushafThemeMode.dark), isFalse);
    });
  });
}
