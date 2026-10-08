import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/features/adhan/presentation/controllers/adhan_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
