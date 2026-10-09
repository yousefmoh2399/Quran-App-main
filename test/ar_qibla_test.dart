import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/features/qiblah/presentation/view_model/qiblah_view_model.dart';
import 'package:quran_app_android/features/qiblah/presentation/views/ar_qibla_camera_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lat': 30.0444,
      'lng': 31.2357,
      'cityName': 'القاهرة',
    });
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('AR Qibla Angular Calculations Tests', () {
    double calculateDeltaAngle(double targetAngle, double currentHeading) {
      double diff = (targetAngle - currentHeading) % 360;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      return diff;
    }

    test('delta is zero when heading matches target', () {
      final delta = calculateDeltaAngle(136.0, 136.0);
      expect(delta, equals(0.0));
    });

    test('delta is positive when target is to the right of camera lens', () {
      final delta = calculateDeltaAngle(136.0, 100.0);
      expect(delta, equals(36.0));
    });

    test('delta is negative when target is to the left of camera lens', () {
      final delta = calculateDeltaAngle(136.0, 160.0);
      expect(delta, equals(-24.0));
    });

    test('wraps smoothly across North 0/360 boundary', () {
      // Target is 10°, heading is 350° -> delta is +20°
      final deltaRight = calculateDeltaAngle(10.0, 350.0);
      expect(deltaRight, equals(20.0));

      // Target is 350°, heading is 10° -> delta is -20°
      final deltaLeft = calculateDeltaAngle(350.0, 10.0);
      expect(deltaLeft, equals(-20.0));
    });

    test('alignment window check (within 6 degrees)', () {
      const target = 136.0;
      bool isAligned(double heading) => calculateDeltaAngle(target, heading).abs() <= 6.0;

      expect(isAligned(136.0), isTrue);
      expect(isAligned(134.0), isTrue);
      expect(isAligned(140.0), isTrue);
      expect(isAligned(144.0), isFalse);
      expect(isAligned(125.0), isFalse);
    });
  });

  group('ArQiblaCameraView Widget Fallback Tests', () {
    testWidgets('renders gracefully with interactive fallback when camera hardware is absent', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final vm = QiblahViewModel();
      vm.setManualCity('القاهرة', 30.0444, 31.2357);
      Get.put(vm);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ArQiblaCameraView(
            qiblaDirection: 136.0,
            userLatitude: 30.0444,
            userLongitude: 31.2357,
          ),
        ),
      );

      // Give time for initial async camera probe to complete gracefully
      await tester.pump(const Duration(milliseconds: 300));

      // Title in top bar
      expect(find.text('بوصلة الواقع المعزز (AR)'), findsOneWidget);

      // Return to classic compass button
      expect(find.text('العودة للبوصلة الكلاسيكية'), findsOneWidget);

      // Qiblah degree badge
      expect(find.textContaining('136°'), findsWidgets);

      // Unmount widget and dispose active animation controller
      await tester.pumpWidget(const SizedBox());
    });
  });
}
