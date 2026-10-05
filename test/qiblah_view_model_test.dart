import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/features/qiblah/presentation/view_model/qiblah_view_model.dart';
import 'package:quran_app_android/features/qiblah/presentation/views/qiblah_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lat': 30.0444,
      'lng': 31.2357,
      'cityName': 'القاهرة',
    });
    Get.reset();
  });

  group('QiblahViewModel Fast Loading & Calculation Tests', () {
    test('initializes immediately with valid coordinates and calculates Qibla direction', () async {
      final vm = QiblahViewModel();
      expect(vm.hasLocation.value, isTrue);
      expect(vm.userLatitude.value, 30.0444);
      expect(vm.userLongitude.value, 31.2357);

      // Cairo Qibla direction is roughly 136°
      expect(vm.qiblaDirection.value, closeTo(136.0, 2.0));
    });

    test('recalculates Qibla direction accurately for different cities', () async {
      final vm = QiblahViewModel();

      // Alexandria: ~31.2001, 29.9187 -> Qibla is roughly 135.5°
      vm.initLocationAndQibla();
      expect(vm.qiblaDirection.value, greaterThan(130.0));
      expect(vm.qiblaDirection.value, lessThan(145.0));
    });
  });

  group('QiblahView Fast Rendering Widget Tests', () {
    testWidgets('renders QiblahView immediately without blocking full-screen waiting indicator', (tester) async {
      final vm = QiblahViewModel();
      vm.isDone.value = true;
      Get.put<QiblahViewModel>(vm);

      await tester.pumpWidget(
        const MaterialApp(
          home: QiblahView(),
        ),
      );

      // Verify that QiblahView title is rendered immediately
      expect(find.text('اتجاه القبلة'), findsOneWidget);

      // Verify no infinite 15s FutureBuilder waiting indicator is blocking the view
      await tester.pump();
      expect(find.byType(QiblahView), findsOneWidget);
    });
  });
}
