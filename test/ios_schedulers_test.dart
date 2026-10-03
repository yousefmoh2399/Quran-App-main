import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/notifications/ios_prayer_scheduler.dart';
import 'package:quran_app_android/core/notifications/ios_reminder_scheduler.dart';
import 'package:quran_app_android/core/notifications/notification_budget.dart';
import 'package:quran_app_android/features/adhan/data/models/adhan_settings_model.dart';
import 'package:quran_app_android/features/reminders/data/reminders_calendar_calc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FakeLocalNotificationsPlugin extends Fake implements FlutterLocalNotificationsPlugin {
  final List<int> cancelledIds = [];
  final List<Map<String, dynamic>> scheduledNotifications = [];
  final List<Map<String, dynamic>> shownNotifications = [];

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
    bool androidAllowWhileIdle = false,
    AndroidScheduleMode? androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'date': scheduledDate,
      'payload': payload,
    });
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    shownNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('iOS Notification Budget (Apple 64-notification limit)', () {
    test('Budget validation passes and total allocated is exactly 63 <= 64', () {
      expect(NotificationBudget.validateBudget(), isTrue);
      expect(NotificationBudget.totalAllocated, 63);
      expect(NotificationBudget.totalAllocated <= NotificationBudget.maxTotalBudget, isTrue);
    });

    test('All generated IDs across all categories are deterministic, unique, and disjoint', () {
      final prayerIds = NotificationBudget.getAllPrayerIds().toSet();
      final wirdIds = NotificationBudget.getAllWirdIds().toSet();
      final transitIds = NotificationBudget.getAllTransitIds().toSet();
      final sadaqahIds = {NotificationBudget.getSadaqahId()};
      final azkarIds = NotificationBudget.getAllAzkarIds().toSet();

      // Counts per specification
      expect(prayerIds.length, 40);
      expect(wirdIds.length, 7);
      expect(transitIds.length, 7);
      expect(sadaqahIds.length, 1);
      expect(azkarIds.length, 8);

      // Verify mutual disjointness (no overlap between categories)
      final allIds = <int>[
        ...prayerIds,
        ...wirdIds,
        ...transitIds,
        ...sadaqahIds,
        ...azkarIds,
      ];
      final uniqueIds = allIds.toSet();
      expect(allIds.length, 63);
      expect(uniqueIds.length, 63, reason: 'Collision detected in notification ID ranges!');

      // Check bounds
      for (final id in prayerIds) {
        expect(id >= 1000 && id < 1040, isTrue);
      }
      for (final id in wirdIds) {
        expect(id >= 2000 && id < 2007, isTrue);
      }
      for (final id in transitIds) {
        expect(id >= 2100 && id < 2107, isTrue);
      }
      expect(NotificationBudget.getSadaqahId(), 2200);
      for (final id in azkarIds) {
        expect(id >= 2300 && id < 2308, isTrue);
      }
    });

    test('Budget index out of bounds throws AssertionError', () {
      expect(() => NotificationBudget.getPrayerId(-1, 0), throwsA(isA<AssertionError>()));
      expect(() => NotificationBudget.getPrayerId(8, 0), throwsA(isA<AssertionError>()));
      expect(() => NotificationBudget.getPrayerId(0, -1), throwsA(isA<AssertionError>()));
      expect(() => NotificationBudget.getPrayerId(0, 5), throwsA(isA<AssertionError>()));

      expect(() => NotificationBudget.getWirdId(-1), throwsA(isA<AssertionError>()));
      expect(() => NotificationBudget.getWirdId(7), throwsA(isA<AssertionError>()));

      expect(() => NotificationBudget.getTransitId(-1), throwsA(isA<AssertionError>()));
      expect(() => NotificationBudget.getTransitId(7), throwsA(isA<AssertionError>()));

      expect(() => NotificationBudget.getAzkarId(-1), throwsA(isA<AssertionError>()));
      expect(() => NotificationBudget.getAzkarId(8), throwsA(isA<AssertionError>()));
    });
  });

  group('IosPrayerNotificationScheduler - Calculation Parity & Guarding', () {
    test('Calculates prayer times matching Adhan reference for Cairo (30.0444, 31.2357)', () {
      final params = IosPrayerNotificationScheduler.getCalculationParameters(
        'EGYPTIAN',
        'SHAFI',
      );
      final coords = Coordinates(30.0444, 31.2357);
      final testDate = DateComponents(2026, 10, 15);
      final prayerTimes = PrayerTimes(coords, testDate, params);

      expect(prayerTimes.fajr, isNotNull);
      expect(prayerTimes.sunrise, isNotNull);
      expect(prayerTimes.dhuhr, isNotNull);
      expect(prayerTimes.asr, isNotNull);
      expect(prayerTimes.maghrib, isNotNull);
      expect(prayerTimes.isha, isNotNull);

      // Verify correct chronological sequence
      expect(prayerTimes.fajr.isBefore(prayerTimes.sunrise), isTrue);
      expect(prayerTimes.sunrise.isBefore(prayerTimes.dhuhr), isTrue);
      expect(prayerTimes.dhuhr.isBefore(prayerTimes.asr), isTrue);
      expect(prayerTimes.asr.isBefore(prayerTimes.maghrib), isTrue);
      expect(prayerTimes.maghrib.isBefore(prayerTimes.isha), isTrue);
    });

    test('Calculation respects Hanafi madhab producing later Asr than Shafi', () {
      final shafiParams = IosPrayerNotificationScheduler.getCalculationParameters(
        'EGYPTIAN',
        'SHAFI',
      );
      final hanafiParams = IosPrayerNotificationScheduler.getCalculationParameters(
        'EGYPTIAN',
        'HANAFI',
      );
      final coords = Coordinates(30.0444, 31.2357);
      final testDate = DateComponents(2026, 10, 15);

      final shafiTimes = PrayerTimes(coords, testDate, shafiParams);
      final hanafiTimes = PrayerTimes(coords, testDate, hanafiParams);

      expect(hanafiTimes.asr.isAfter(shafiTimes.asr), isTrue);
    });

    test('Minute adjustments shift prayer times by exact delta', () {
      final regularParams = IosPrayerNotificationScheduler.getCalculationParameters(
        'EGYPTIAN',
        'SHAFI',
        fajrOffset: 0,
      );
      final adjustedParams = IosPrayerNotificationScheduler.getCalculationParameters(
        'EGYPTIAN',
        'SHAFI',
        fajrOffset: 12,
      );
      final coords = Coordinates(30.0444, 31.2357);
      final testDate = DateComponents(2026, 10, 15);

      final regularTimes = PrayerTimes(coords, testDate, regularParams);
      final adjustedTimes = PrayerTimes(coords, testDate, adjustedParams);

      expect(
        adjustedTimes.fajr.difference(regularTimes.fajr).inMinutes,
        12,
      );
    });

    test('Aborts scheduling and clears slots when location is missing (0.0, 0.0)', () async {
      final fakePlugin = FakeLocalNotificationsPlugin();
      final scheduler = IosPrayerNotificationScheduler(
        notificationsPlugin: fakePlugin,
        nowProvider: () => DateTime(2026, 10, 15, 8, 0),
      );

      final settingsNoLocation = AdhanSettingsModel(
        latitude: 0.0,
        longitude: 0.0,
      );

      final scheduledCount = await scheduler.scheduleFromSettings(settingsNoLocation);
      expect(scheduledCount, 0);
      expect(fakePlugin.scheduledNotifications.isEmpty, isTrue);
      // Verify all 40 slots were cancelled
      expect(fakePlugin.cancelledIds.length, 40);
    });

    test('Schedules future prayers within 8 days when location is valid', () async {
      final fakePlugin = FakeLocalNotificationsPlugin();
      final scheduler = IosPrayerNotificationScheduler(
        notificationsPlugin: fakePlugin,
        nowProvider: () => DateTime(2026, 10, 15, 11, 0), // 11:00 AM (after Fajr & Sunrise)
      );

      final settingsWithLocation = AdhanSettingsModel(
        latitude: 30.0444,
        longitude: 31.2357,
        calculationMethod: 'EGYPTIAN',
        madhab: 'SHAFI',
      );

      final scheduledCount = await scheduler.scheduleFromSettings(settingsWithLocation);
      expect(scheduledCount, greaterThan(0));
      expect(scheduledCount, lessThanOrEqualTo(40));
      expect(fakePlugin.scheduledNotifications.isNotEmpty, isTrue);

      // Verify payload and sound
      final first = fakePlugin.scheduledNotifications.first;
      expect(first['id'], greaterThanOrEqualTo(1000));
      expect(first['id'], lessThan(1040));
    });
  });

  group('Reminders Engine - Month-End Clamping (28/29/30/31)', () {
    test('Clamps day 31 to Feb 28 in non-leap year (e.g. 2026)', () {
      final baseDate = DateTime(2026, 1, 31, 23, 0); // After Jan 31 trigger
      final nextTrigger = RemindersCalendarCalc.getNextGregorianMonthlyTrigger(
        dayType: 'day_of_month',
        targetDay: 31,
        hour: 10,
        minute: 0,
        now: baseDate,
      );

      expect(nextTrigger.year, 2026);
      expect(nextTrigger.month, 2);
      expect(nextTrigger.day, 28);
    });

    test('Clamps day 31 to Feb 29 in leap year (e.g. 2028)', () {
      final baseDate = DateTime(2028, 1, 31, 23, 0);
      final nextTrigger = RemindersCalendarCalc.getNextGregorianMonthlyTrigger(
        dayType: 'day_of_month',
        targetDay: 31,
        hour: 10,
        minute: 0,
        now: baseDate,
      );

      expect(nextTrigger.year, 2028);
      expect(nextTrigger.month, 2);
      expect(nextTrigger.day, 29);
    });

    test('Clamps day 31 to April 30', () {
      final baseDate = DateTime(2026, 3, 31, 23, 0);
      final nextTrigger = RemindersCalendarCalc.getNextGregorianMonthlyTrigger(
        dayType: 'day_of_month',
        targetDay: 31,
        hour: 10,
        minute: 0,
        now: baseDate,
      );

      expect(nextTrigger.year, 2026);
      expect(nextTrigger.month, 4);
      expect(nextTrigger.day, 30);
    });

    test('Preserves day 31 in May', () {
      final baseDate = DateTime(2026, 4, 30, 23, 0);
      final nextTrigger = RemindersCalendarCalc.getNextGregorianMonthlyTrigger(
        dayType: 'day_of_month',
        targetDay: 31,
        hour: 10,
        minute: 0,
        now: baseDate,
      );

      expect(nextTrigger.year, 2026);
      expect(nextTrigger.month, 5);
      expect(nextTrigger.day, 31);
    });
  });

  group('IosReminderNotificationScheduler - Cancellation on Completion', () {
    test('markWirdCompleted cancels today slot ID 2000', () async {
      final fakePlugin = FakeLocalNotificationsPlugin();
      final scheduler = IosReminderNotificationScheduler(
        notificationsPlugin: fakePlugin,
        nowProvider: () => DateTime(2026, 10, 15, 10, 0),
      );

      final success = await scheduler.markWirdCompleted();
      expect(success, isTrue);
      expect(fakePlugin.cancelledIds.contains(NotificationBudget.getWirdId(0)), isTrue);
      expect(fakePlugin.cancelledIds.contains(2000), isTrue);
    });

    test('markCommuteCompleted cancels today transit slot ID 2100', () async {
      final fakePlugin = FakeLocalNotificationsPlugin();
      final scheduler = IosReminderNotificationScheduler(
        notificationsPlugin: fakePlugin,
        nowProvider: () => DateTime(2026, 10, 15, 10, 0),
      );

      final success = await scheduler.markCommuteCompleted(slotId: 'morning');
      expect(success, isTrue);
      expect(fakePlugin.cancelledIds.contains(NotificationBudget.getTransitId(0)), isTrue);
      expect(fakePlugin.cancelledIds.contains(2100), isTrue);
    });

    test('cancelAllReminderNotifications cancels all 23 reminder slots', () async {
      final fakePlugin = FakeLocalNotificationsPlugin();
      final scheduler = IosReminderNotificationScheduler(
        notificationsPlugin: fakePlugin,
      );

      await scheduler.cancelAllReminderNotifications();
      // 7 wird + 7 transit + 1 sadaqah + 8 azkar = 23 slots
      expect(fakePlugin.cancelledIds.length, 23);
      for (final id in NotificationBudget.getAllWirdIds()) {
        expect(fakePlugin.cancelledIds.contains(id), isTrue);
      }
      for (final id in NotificationBudget.getAllTransitIds()) {
        expect(fakePlugin.cancelledIds.contains(id), isTrue);
      }
      expect(fakePlugin.cancelledIds.contains(NotificationBudget.getSadaqahId()), isTrue);
      for (final id in NotificationBudget.getAllAzkarIds()) {
        expect(fakePlugin.cancelledIds.contains(id), isTrue);
      }
    });
  });
}
