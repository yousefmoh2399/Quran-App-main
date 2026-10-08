import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../features/adhan/data/models/adhan_settings_model.dart';
import 'notification_budget.dart';

/// Schedules local prayer notifications for iOS within the 64-notification budget.
///
/// Features:
/// - 8-day rolling window × 5 daily prayers = 40 deterministic slots (IDs: 1000..1039).
/// - Exact prayer time calculations using [adhan] with identical parameters (method, madhab, offsets).
/// - If location is missing or zero, scheduling is aborted and logged clearly.
/// - Sound: uses 'adhan_ios.wav' (duration <= 29s).
/// - Interruption level: [InterruptionLevel.timeSensitive].
/// - Notification actions: 'action_prayed' (صلّيت) and 'action_stop' (إيقاف).
class IosPrayerNotificationScheduler {
  static const String prefsSettingsKey = 'ios_adhan_settings';
  static const String categoryIdentifier = 'prayer_category';
  static const String soundFileName = 'adhan_ios.wav';

  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final DateTime Function() nowProvider;

  IosPrayerNotificationScheduler({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    DateTime Function()? nowProvider,
  })  : notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        nowProvider = nowProvider ?? DateTime.now;

  static final IosPrayerNotificationScheduler instance = IosPrayerNotificationScheduler();

  /// Converts stored calculation method string to [CalculationMethod] parameters.
  static CalculationParameters getCalculationParameters(
    String methodString,
    String madhabString, {
    int fajrOffset = 0,
    int sunriseOffset = 0,
    int dhuhrOffset = 0,
    int asrOffset = 0,
    int maghribOffset = 0,
    int ishaOffset = 0,
  }) {
    CalculationParameters params;
    switch (methodString.toUpperCase()) {
      case 'UMM_AL_QURA':
      case 'UMMALQURA':
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'MUSLIM_WORLD_LEAGUE':
      case 'MWL':
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'KARACHI':
        params = CalculationMethod.karachi.getParameters();
        break;
      case 'NORTH_AMERICA':
      case 'ISNA':
        params = CalculationMethod.north_america.getParameters();
        break;
      case 'DUBAI':
        params = CalculationMethod.dubai.getParameters();
        break;
      case 'KUWAIT':
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 'QATAR':
        params = CalculationMethod.qatar.getParameters();
        break;
      case 'SINGAPORE':
        params = CalculationMethod.singapore.getParameters();
        break;
      case 'MOON_SIGHTING_COMMITTEE':
        params = CalculationMethod.moon_sighting_committee.getParameters();
        break;
      case 'EGYPTIAN':
      default:
        params = CalculationMethod.egyptian.getParameters();
        break;
    }

    params.madhab = madhabString.toUpperCase() == 'HANAFI' ? Madhab.hanafi : Madhab.shafi;
    params.adjustments.fajr = fajrOffset;
    params.adjustments.sunrise = sunriseOffset;
    params.adjustments.dhuhr = dhuhrOffset;
    params.adjustments.asr = asrOffset;
    params.adjustments.maghrib = maghribOffset;
    params.adjustments.isha = ishaOffset;

    return params;
  }

  /// Cancels all 40 allocated prayer notification IDs in the budget.
  Future<void> cancelAllPrayerNotifications() async {
    debugPrint('📱 [IosPrayerScheduler] Cancelling all ${NotificationBudget.prayerSlotCount} prayer slots...');
    for (final id in NotificationBudget.getAllPrayerIds()) {
      try {
        await notificationsPlugin.cancel(id);
      } catch (e) {
        debugPrint('⚠️ [IosPrayerScheduler] Error cancelling notification ID $id: $e');
      }
    }
  }

  /// Saves settings to SharedPreferences and reschedules the 8-day rolling window.
  Future<bool> saveSettingsAndSchedule(Map<String, dynamic> settingsMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsSettingsKey, jsonEncode(settingsMap));
      final model = AdhanSettingsModel.fromMap(settingsMap);
      final count = await scheduleFromSettings(model);
      debugPrint('📱 [IosPrayerScheduler] Saved settings and scheduled $count prayers.');
      return count >= 0;
    } catch (e, st) {
      debugPrint('❌ [IosPrayerScheduler] Failed to save settings and schedule: $e\n$st');
      return false;
    }
  }

  /// Loads settings from SharedPreferences.
  Future<Map<String, dynamic>?> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(prefsSettingsKey);
      if (str == null || str.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(str) as Map);
    } catch (e) {
      debugPrint('⚠️ [IosPrayerScheduler] Error loading settings: $e');
      return null;
    }
  }

  /// Checks whether a valid location is stored.
  Future<bool> hasLocation() async {
    final settings = await loadSettings();
    if (settings == null) return false;
    final lat = (settings['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (settings['longitude'] as num?)?.toDouble() ?? 0.0;
    return lat != 0.0 && lng != 0.0;
  }

  /// Reschedules prayer notifications from currently saved settings.
  Future<int> recalculateAndSchedule() async {
    final map = await loadSettings();
    if (map == null) {
      debugPrint('⚠️ [IosPrayerScheduler] Cannot reschedule: No settings found.');
      return 0;
    }
    return scheduleFromSettings(AdhanSettingsModel.fromMap(map));
  }

  void _ensureTimezone() {
    try {
      if (tz.timeZoneDatabase.locations.isEmpty) {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (_) {}
  }

  /// Core scheduling routine.
  ///
  /// Calculates prayer times for the next 8 days (dayOffset 0..7).
  /// Schedules future prayers into deterministic IDs 1000..1039.
  /// Returns the number of successfully scheduled notifications.
  Future<int> scheduleFromSettings(AdhanSettingsModel settings) async {
    _ensureTimezone();
    NotificationBudget.validateBudget();

    // Check location validity
    if (settings.latitude == 0.0 && settings.longitude == 0.0) {
      debugPrint('⚠️ [IosPrayerScheduler] Aborted scheduling: Latitude & Longitude are 0.0 (no location).');
      await cancelAllPrayerNotifications();
      return 0;
    }

    // Cancel existing prayer notifications before rescheduling
    await cancelAllPrayerNotifications();

    final now = nowProvider();
    final coords = Coordinates(settings.latitude, settings.longitude);
    final params = getCalculationParameters(
      settings.calculationMethod,
      settings.madhab,
      fajrOffset: settings.fajrOffset,
      sunriseOffset: settings.sunriseOffset,
      dhuhrOffset: settings.dhuhrOffset,
      asrOffset: settings.asrOffset,
      maghribOffset: settings.maghribOffset,
      ishaOffset: settings.ishaOffset,
    );

    int scheduledCount = 0;

    for (int dayOffset = 0; dayOffset < NotificationBudget.prayerDays; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final dateComp = DateComponents(targetDate.year, targetDate.month, targetDate.day);
      final prayerTimes = PrayerTimes(coords, dateComp, params);

      // 5 daily prayers
      final prayers = [
        _PrayerSlot(
          prayerIndex: 0,
          nameAr: 'الفجر',
          key: 'fajr',
          time: prayerTimes.fajr,
          enabled: settings.fajrEnabled,
          mode: settings.fajrMode,
        ),
        _PrayerSlot(
          prayerIndex: 1,
          nameAr: 'الظهر',
          key: 'dhuhr',
          time: prayerTimes.dhuhr,
          enabled: settings.dhuhrEnabled,
          mode: settings.dhuhrMode,
        ),
        _PrayerSlot(
          prayerIndex: 2,
          nameAr: 'العصر',
          key: 'asr',
          time: prayerTimes.asr,
          enabled: settings.asrEnabled,
          mode: settings.asrMode,
        ),
        _PrayerSlot(
          prayerIndex: 3,
          nameAr: 'المغرب',
          key: 'maghrib',
          time: prayerTimes.maghrib,
          enabled: settings.maghribEnabled,
          mode: settings.maghribMode,
        ),
        _PrayerSlot(
          prayerIndex: 4,
          nameAr: 'العشاء',
          key: 'isha',
          time: prayerTimes.isha,
          enabled: settings.ishaEnabled,
          mode: settings.ishaMode,
        ),
      ];

      for (final slot in prayers) {
        if (!slot.enabled) continue;

        // Skip prayers that have already passed
        if (!slot.time.isAfter(now)) continue;

        final notificationId = NotificationBudget.getPrayerId(dayOffset, slot.prayerIndex);

        try {
          final tzTime = tz.TZDateTime.from(slot.time, tz.local);

          final isSilent = slot.mode == 'silent';
          final isNotificationOnly = slot.mode == 'notification_only';
          final soundToPlay = isSilent
              ? null
              : (isNotificationOnly ? null : soundFileName);

          final darwinDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: !isSilent,
            sound: soundToPlay,
            interruptionLevel: InterruptionLevel.timeSensitive,
            categoryIdentifier: categoryIdentifier,
          );

          final notificationDetails = NotificationDetails(iOS: darwinDetails);

          await notificationsPlugin.zonedSchedule(
            notificationId,
            'حان موعد أذان ${slot.nameAr}',
            'حي على الصلاة، حي على الفلاح — صلاة ${slot.nameAr}',
            tzTime,
            notificationDetails,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: jsonEncode({
              'type': 'adhan',
              'prayerKey': slot.key,
              'prayerName': slot.nameAr,
              'scheduledTime': slot.time.toIso8601String(),
            }),
          );

          scheduledCount++;
        } catch (e, st) {
          debugPrint('⚠️ [IosPrayerScheduler] Error scheduling prayer ${slot.nameAr} on day $dayOffset: $e\n$st');
        }
      }
    }

    debugPrint('✅ [IosPrayerScheduler] Successfully scheduled $scheduledCount prayer notifications across ${NotificationBudget.prayerDays} days.');
    return scheduledCount;
  }

  /// Immediately triggers a test Adhan notification on iOS for verification.
  Future<bool> scheduleTestAdhan({int delaySeconds = 10, String prayerName = 'الفجر'}) async {
    try {
      _ensureTimezone();
      final now = nowProvider();
      final triggerTime = now.add(Duration(seconds: delaySeconds));
      final tzTime = tz.TZDateTime.from(triggerTime, tz.local);

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: soundFileName,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: categoryIdentifier,
      );

      const details = NotificationDetails(iOS: darwinDetails);

      // Use safe test ID 999
      const testId = 999;
      await notificationsPlugin.zonedSchedule(
        testId,
        'تشغيل تجريبي للأذان: صلاة $prayerName',
        'صوت الأذان التجريبي — اختبار إشعار الأذان على نظام iOS',
        tzTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({
          'type': 'adhan_test',
          'prayerName': prayerName,
        }),
      );

      debugPrint('📱 [IosPrayerScheduler] Scheduled test adhan for $prayerName in $delaySeconds seconds.');
      return true;
    } catch (e, st) {
      debugPrint('❌ [IosPrayerScheduler] Failed to schedule test adhan: $e\n$st');
      return false;
    }
  }
}

class _PrayerSlot {
  final int prayerIndex;
  final String nameAr;
  final String key;
  final DateTime time;
  final bool enabled;
  final String mode;

  const _PrayerSlot({
    required this.prayerIndex,
    required this.nameAr,
    required this.key,
    required this.time,
    required this.enabled,
    required this.mode,
  });
}
