import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/features/card_studio/presentation/controllers/card_studio_controller.dart';
import 'package:quran_app_android/features/qiblah/presentation/view_model/qiblah_view_model.dart';
import 'package:quran_app_android/features/qiblah/presentation/views/ar_qibla_camera_view.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('Card Studio & AR Qibla Safety Tests', () {
    testWidgets('CardStudioController copyText runs without Overlay exception', (tester) async {
      final controller = CardStudioController();
      Get.put(controller);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Card Studio Test'),
            ),
          ),
        ),
      );

      // Trigger copyText which used to crash with "No Overlay widget found"
      expect(() => controller.copyText(), returnsNormally);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('ArQiblaCameraView renders fallback safely when camera is unavailable (simulator)', (tester) async {
      final qiblahVm = QiblahViewModel();
      qiblahVm.qiblaDirection.value = 136.5;
      Get.put(qiblahVm);

      await tester.pumpWidget(
        const MaterialApp(
          home: ArQiblaCameraView(
            qiblaDirection: 136.5,
            userLatitude: 30.0444,
            userLongitude: 31.2357,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(ArQiblaCameraView), findsOneWidget);
    });
  });
}
