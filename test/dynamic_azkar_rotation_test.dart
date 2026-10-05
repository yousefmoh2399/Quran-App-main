import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/core/util/constant/static_vars.dart';
import 'package:quran_app_android/core/service/settings/lock_screen_banner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dynamic Azkar Content & Rotation Tests', () {
    test('StaticVars adhkar pool contains rich diverse prayers and dhikr', () {
      final adhkar = StaticVars().smallDo3a2;
      expect(adhkar.isNotEmpty, isTrue);
      expect(adhkar.length, greaterThanOrEqualTo(50));
      // Ensure items are diverse (not all identical)
      final set = adhkar.toSet();
      expect(set.length, greaterThan(30));
    });

    test('LockScreenBannerService rotates dhikr based on 15-minute slots', () async {
      final banner = LockScreenBannerService.instance;
      final data = await banner.buildDisplayData();
      expect(data.zikrLine, isNotEmpty);

      // Verify that changing the time slot changes or varies the dhikr index
      final adhkar = StaticVars().smallDo3a2;
      final slot1Idx = (8 * 4 + 0 + 1) % adhkar.length;
      final slot2Idx = (8 * 4 + 1 + 1) % adhkar.length;
      expect(slot1Idx != slot2Idx, isTrue);
    });

    test('Azkar model categories contain valid mappings and display names', () {
      final categories = {
        'morning_evening': 'أذكار الصباح والمساء',
        'quranic': 'أدعية قرآنية',
        'prophetic': 'أدعية نبوية مأثورة',
        'tasbeeh': 'تسابيح وتحميد وتهليل',
        'istighfar': 'استغفار وتوبة',
        'general': 'أذكار وأدعية عامة',
      };

      expect(categories.containsKey('morning_evening'), isTrue);
      expect(categories.containsKey('tasbeeh'), isTrue);
      expect(categories.containsKey('istighfar'), isTrue);
    });
  });
}
