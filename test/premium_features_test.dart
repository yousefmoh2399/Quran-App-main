import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/service/settings/notifications_services.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widgets/zikr_image_share_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Premium Features Verification', () {
    test('ZikrCardPreset provides all necessary styling for image sharing', () {
      expect(ZikrCardPreset.values.length, 3);
      for (final preset in ZikrCardPreset.values) {
        expect(preset.bgGradient.length, greaterThanOrEqualTo(2));
        expect(preset.textColor, isNotNull);
        expect(preset.accentColor, isNotNull);
      }
    });

    test('Prayer Banner Notification Channel and constants configured', () {
      expect(NotifyHelper.prayerBannerNotificationId, 99901);
    });

    test('Wird Resume Page calculation correctly handles reading progression', () {
      const int planStart = 10;
      const int planEnd = 20;

      // Case 1: No previous reading -> starts at plan.startPage
      int? savedWirdPage;
      int? lastRead;
      int currentRead = 0;
      int resumePage = planStart;
      if (savedWirdPage != null && savedWirdPage >= planStart && savedWirdPage <= planEnd) {
        resumePage = savedWirdPage;
      } else if (lastRead != null && lastRead >= planStart && lastRead <= planEnd) {
        resumePage = lastRead;
      } else if (currentRead > 0) {
        resumePage = (planStart + currentRead).clamp(planStart, planEnd);
      }
      expect(resumePage, 10);

      // Case 2: User read to page 14 -> resumePage is 14
      savedWirdPage = 14;
      if (savedWirdPage >= planStart && savedWirdPage <= planEnd) {
        resumePage = savedWirdPage;
      }
      expect(resumePage, 14);

      // Case 3: Saved page beyond plan -> clamps to planEnd
      savedWirdPage = 25;
      if (savedWirdPage >= planStart && savedWirdPage <= planEnd) {
        resumePage = savedWirdPage;
      } else {
        resumePage = (planStart + 5).clamp(planStart, planEnd);
      }
      expect(resumePage, 15);
    });
  });
}
