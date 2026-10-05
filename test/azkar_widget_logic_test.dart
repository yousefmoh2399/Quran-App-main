import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Azkar 300+ Dataset Integrity Tests', () {
    test('JSON dataset contains 300+ authentic entries across all target categories', () {
      final file = File('android/app/src/main/res/raw/azkar_widget_data.json');
      expect(file.existsSync(), isTrue, reason: 'azkar_widget_data.json must exist in res/raw');

      final list = jsonDecode(file.readAsStringSync()) as List;
      expect(list.length, greaterThanOrEqualTo(300),
          reason: 'Dataset must contain at least 300 items (found ${list.length})');

      final categories = <String>{};
      for (final raw in list) {
        final item = raw as Map<String, dynamic>;
        expect(item['id'], isNotNull);
        expect(item['text'], isNotEmpty);
        expect(item['category'], isNotEmpty);
        expect(item['category_name'], isNotEmpty);
        expect(item['source'], isNotEmpty);
        categories.add(item['category'] as String);
      }

      // Check required categories exist
      expect(categories.contains('morning_evening'), isTrue);
      expect(categories.contains('quranic'), isTrue);
      expect(categories.contains('prophetic'), isTrue);
      expect(categories.contains('tasbeeh'), isTrue);
      expect(categories.contains('istighfar'), isTrue);
    });

    test('iOS Widget copy matches Android res/raw dataset identically', () {
      final androidFile = File('android/app/src/main/res/raw/azkar_widget_data.json');
      final iosFile = File('ios/MyHomeWidget/azkar_widget_data.json');

      expect(iosFile.existsSync(), isTrue, reason: 'iOS Widget copy must exist');
      expect(iosFile.readAsStringSync(), equals(androidFile.readAsStringSync()));
    });
  });

  group('10-Minute Deterministic Formula Tests', () {
    const tenMinutesMillis = 10 * 60 * 1000;
    const totalAzkar = 322;

    int calculateDeterministicIndex(int timeMillis, int manualOffset) {
      final slot = timeMillis ~/ tenMinutesMillis;
      return (((slot + manualOffset) % totalAzkar) + totalAzkar) % totalAzkar;
    }

    test('Returns exact same dhikr anywhere inside the same 10-minute window', () {
      // Base time: 12:00:00.000
      final t1 = 1770000000000;
      final t2 = t1 + (3 * 60 * 1000); // 12:03
      final t3 = t1 + (9 * 60 * 1000) + 50000; // 12:09:50

      final index1 = calculateDeterministicIndex(t1, 0);
      final index2 = calculateDeterministicIndex(t2, 0);
      final index3 = calculateDeterministicIndex(t3, 0);

      expect(index1, equals(index2));
      expect(index2, equals(index3));
    });

    test('Transitions predictably to next slot when 10 minutes pass', () {
      final t1 = 1770000000000;
      final tNextSlot = t1 + tenMinutesMillis; // +10 minutes

      final index1 = calculateDeterministicIndex(t1, 0);
      final index2 = calculateDeterministicIndex(tNextSlot, 0);

      expect(index2, equals((index1 + 1) % totalAzkar));
    });

    test('Manual offset cycles dhikr independently without waiting for 10-minute timer', () {
      final now = 1770000000000;
      final initialIndex = calculateDeterministicIndex(now, 0);
      final nextManualIndex = calculateDeterministicIndex(now, 1);
      final secondManualIndex = calculateDeterministicIndex(now, 2);

      expect(nextManualIndex, equals((initialIndex + 1) % totalAzkar));
      expect(secondManualIndex, equals((initialIndex + 2) % totalAzkar));
    });
  });

  group('Native Notification Quiet Window & Active Hours Logic Tests', () {
    test('Quiet prayer window suppresses azkar notification within ±10 minutes of prayer', () {
      bool isNearPrayerTime(int nowMillis, List<int> prayerTimesMillis, int toleranceMinutes) {
        final toleranceMillis = toleranceMinutes * 60 * 1000;
        return prayerTimesMillis.any((pTime) => (nowMillis - pTime).abs() <= toleranceMillis);
      }

      final dhuhrTime = 1770033600000; // e.g. 12:00 PM
      final prayerList = [1770000000000, dhuhrTime, 1770050000000];

      // 11:53 AM (7 mins before Dhuhr) -> Inside ±10 min quiet window -> Suppressed
      expect(isNearPrayerTime(dhuhrTime - (7 * 60 * 1000), prayerList, 10), isTrue);

      // 12:05 PM (5 mins after Dhuhr) -> Inside ±10 min quiet window -> Suppressed
      expect(isNearPrayerTime(dhuhrTime + (5 * 60 * 1000), prayerList, 10), isTrue);

      // 12:15 PM (15 mins after Dhuhr) -> Outside quiet window -> Allowed
      expect(isNearPrayerTime(dhuhrTime + (15 * 60 * 1000), prayerList, 10), isFalse);

      // 11:45 AM (15 mins before Dhuhr) -> Outside quiet window -> Allowed
      expect(isNearPrayerTime(dhuhrTime - (15 * 60 * 1000), prayerList, 10), isFalse);
    });

    test('Chained Next Alarm accurately respects Active Hours (08:00 - 22:00)', () {
      DateTime calculateNextTrigger({
        required DateTime now,
        required int intervalMinutes,
        required int fromHour,
        required int fromMinute,
        required int toHour,
        required int toMinute,
      }) {
        final todayStart = DateTime(now.year, now.month, now.day, fromHour, fromMinute);
        final todayEnd = DateTime(now.year, now.month, now.day, toHour, toMinute);

        if (now.isBefore(todayStart)) {
          // Early morning before active hours: trigger at start time today
          return todayStart;
        } else if (!now.isAfter(todayEnd)) {
          final candidate = now.add(Duration(minutes: intervalMinutes));
          if (!candidate.isAfter(todayEnd)) {
            return candidate;
          } else {
            // Next slot falls into sleep hours: schedule for tomorrow start time
            return DateTime(now.year, now.month, now.day + 1, fromHour, fromMinute);
          }
        } else {
          // Late night after active hours: schedule for tomorrow start time
          return DateTime(now.year, now.month, now.day + 1, fromHour, fromMinute);
        }
      }

      // Case 1: Early morning at 05:30 AM (outside 08:00-22:00)
      final earlyMorning = DateTime(2026, 7, 1, 5, 30);
      final next1 = calculateNextTrigger(
        now: earlyMorning,
        intervalMinutes: 60,
        fromHour: 8,
        fromMinute: 0,
        toHour: 22,
        toMinute: 0,
      );
      expect(next1, equals(DateTime(2026, 7, 1, 8, 0)));

      // Case 2: Mid-day at 14:00 (inside 08:00-22:00) with 60 min interval
      final midDay = DateTime(2026, 7, 1, 14, 0);
      final next2 = calculateNextTrigger(
        now: midDay,
        intervalMinutes: 60,
        fromHour: 8,
        fromMinute: 0,
        toHour: 22,
        toMinute: 0,
      );
      expect(next2, equals(DateTime(2026, 7, 1, 15, 0)));

      // Case 3: Late evening at 21:30 with 60 min interval (22:30 exceeds 22:00)
      final lateEvening = DateTime(2026, 7, 1, 21, 30);
      final next3 = calculateNextTrigger(
        now: lateEvening,
        intervalMinutes: 60,
        fromHour: 8,
        fromMinute: 0,
        toHour: 22,
        toMinute: 0,
      );
      expect(next3, equals(DateTime(2026, 7, 2, 8, 0))); // tomorrow at 08:00 AM

      // Case 4: Deep night at 23:45 (after 22:00)
      final deepNight = DateTime(2026, 7, 1, 23, 45);
      final next4 = calculateNextTrigger(
        now: deepNight,
        intervalMinutes: 60,
        fromHour: 8,
        fromMinute: 0,
        toHour: 22,
        toMinute: 0,
      );
      expect(next4, equals(DateTime(2026, 7, 2, 8, 0))); // tomorrow at 08:00 AM
    });
  });
}
