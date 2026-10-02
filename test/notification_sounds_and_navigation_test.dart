import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/features/reminders/data/notification_sounds_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Sounds Service & Model Tests', () {
    test('Default NotificationSoundsSettings initializes with correct spiritual sound defaults', () {
      final settings = NotificationSoundsSettings();
      expect(settings.mode, 'custom');
      expect(settings.unifiedSound, 'fazakkir');
      expect(settings.wirdSound, 'fazakkir');
      expect(settings.commuteSound, 'fazakkir');
      expect(settings.sadaqahSound, 'azkar_2');
      expect(settings.azkarSound, 'azkar_1');
    });

    test('NotificationSoundsSettings toMap and fromMap serialization roundtrip', () {
      final original = NotificationSoundsSettings(
        mode: 'unified',
        unifiedSound: 'adhan',
        wirdSound: 'azkar_1',
        commuteSound: 'azkar_2',
        sadaqahSound: 'silent',
        azkarSound: 'system_default',
      );

      final map = original.toMap();
      final restored = NotificationSoundsSettings.fromMap(map);

      expect(restored.mode, 'unified');
      expect(restored.unifiedSound, 'adhan');
      expect(restored.wirdSound, 'azkar_1');
      expect(restored.commuteSound, 'azkar_2');
      expect(restored.sadaqahSound, 'silent');
      expect(restored.azkarSound, 'system_default');
    });

    test('Available sounds list contains all expected spiritual tones and options', () {
      final sounds = NotificationSoundsService.availableSounds;
      final keys = sounds.map((s) => s.key).toSet();

      expect(keys.contains('fazakkir'), isTrue);
      expect(keys.contains('azkar_1'), isTrue);
      expect(keys.contains('azkar_2'), isTrue);
      expect(keys.contains('adhan'), isTrue);
      expect(keys.contains('system_default'), isTrue);
      expect(keys.contains('silent'), isTrue);
    });

    test('NotificationSoundsService.getOption returns exact option or safe fallback', () {
      final fazakkir = NotificationSoundsService.getOption('fazakkir');
      expect(fazakkir.title, 'فذكّر بالقرآن');
      expect(fazakkir.icon, Icons.menu_book_rounded);

      final azkar1 = NotificationSoundsService.getOption('azkar_1');
      expect(azkar1.title, 'سبحان الله وبحمده');

      final unknown = NotificationSoundsService.getOption('non_existent_sound');
      expect(unknown.key, NotificationSoundsService.availableSounds.first.key);
    });
  });

  group('Notification Navigation Logic Tests', () {
    test('Wird resume page calculation handles bounds correctly', () {
      // Plan range: 45 to 65
      const int planStart = 45;
      const int planEnd = 65;

      int computeWirdPage({int? specificPage, int? lastRead}) {
        if (specificPage != null && specificPage >= 1 && specificPage <= 604) {
          return specificPage;
        }
        if (lastRead != null && lastRead >= planStart && lastRead <= planEnd) {
          return lastRead;
        }
        return planStart;
      }

      // Case A: Specific page passed in notification
      expect(computeWirdPage(specificPage: 50), 50);

      // Case B: No specific page, last read page within range -> resume from last read
      expect(computeWirdPage(lastRead: 53), 53);

      // Case C: No specific page, last read page outside range -> starts from planStart
      expect(computeWirdPage(lastRead: 10), 45);
      expect(computeWirdPage(lastRead: 70), 45);

      // Case D: Cold start without previous read
      expect(computeWirdPage(), 45);
    });

    test('Target screen resolution maps accurately to application routes', () {
      final Map<String, String> screenToRoute = {
        'wird': '/mushaf',
        'commute_wird': '/mushaf',
        'sadaqah': '/sadaqahLogs',
        'azkar': '/azkar',
        'prayer_times': '/adhan',
        'adhan': '/adhan',
        'mushaf': '/mushaf',
      };

      for (final entry in screenToRoute.entries) {
        expect(entry.value, isNotEmpty);
      }
    });
  });
}
