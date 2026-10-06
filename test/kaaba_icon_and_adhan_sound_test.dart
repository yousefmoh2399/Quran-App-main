import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/util/widgets/kaaba_icon.dart';
import 'package:quran_app_android/features/adhan/presentation/controllers/adhan_settings_controller.dart';

void main() {
  group('KaabaIcon Widget & Vector Painter Tests', () {
    testWidgets('KaabaIcon renders correctly with different sizes without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KaabaIcon(size: 16),
                KaabaIcon(size: 24),
                KaabaIcon(size: 32, hasGlow: true),
                KaabaIcon(size: 48),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(KaabaIcon), findsNWidgets(4));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('KaabaPainter executes paint without throwing any exceptions', () {
      final painter = KaabaPainter();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(100, 100);

      expect(() => painter.paint(canvas, size), returnsNormally);
      expect(painter.shouldRepaint(KaabaPainter()), isFalse);
    });
  });

  group('AdhanSettingsController Audio Playback State Tests', () {
    test('testAdhanSound and stopTestAdhan correctly toggle isPlayingTestAdhan', () async {
      final controller = AdhanSettingsController();

      expect(controller.isPlayingTestAdhan.value, isFalse);
      
      // Stop resets state
      await controller.stopTestAdhan();
      expect(controller.isPlayingTestAdhan.value, isFalse);
    });
  });
}
