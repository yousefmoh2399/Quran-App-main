import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:get/get.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/service/navigation/app_navigation_service.dart';
import 'package:quran_app_android/core/util/constant/static_vars.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotifyHelper {
  NotifyHelper._internal();

  static final NotifyHelper _instance = NotifyHelper._internal();

  factory NotifyHelper() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _azkarChannelId = 'azkar_channel';
  static const String _prayerChannelId = 'prayer_channel';
  static const String _wirdChannelId = 'wird_channel';
  static const String _prayerBannerChannelId = 'prayer_banner_channel_v2';

  static final AndroidNotificationChannel _prayerBannerChannel =
      AndroidNotificationChannel(
        _prayerBannerChannelId,
        'شريط مواقيت الصلاة وشاشة القفل',
        description: 'عرض مستمر وأنيق لمواقيت الصلاة، الورد القرآني، والأذكار على شاشة القفل',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

  static final AndroidNotificationChannel _wirdChannel =
      AndroidNotificationChannel(
        _wirdChannelId,
        'الورد اليومي للقرآن',
        description: 'تنبيهات ميعاد ورد القرآن الكريم ومتابعة الختمة',
        importance: Importance.high,
        playSound: true,
      );

  static final AndroidNotificationChannel _azkarChannel =
      AndroidNotificationChannel(
        _azkarChannelId,
        'تنبيهات الأذكار',
        description: 'تذكير بالأذكار اليومية والورد اليومي',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('azkar_1'),
      );

  static final AndroidNotificationChannel _prayerChannel =
      AndroidNotificationChannel(
        _prayerChannelId,
        'تنبيهات الأذان',
        description: 'إشعارات مواقيت الصلاة مع تشغيل كامل للأذان',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
        enableVibration: true,
      );

  final String soundAzkar1 = 'azkar_1.ogg';
  final String soundAzkar2 = 'azkar_2.ogg';
  final String soundAdhan = 'adhan.ogg';

  bool _initialized = false;

  Future<void> initializeNotification() async {
    if (_initialized) return;
    await _configureTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('icon');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          requestCriticalPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              'prayer_category',
              actions: <DarwinNotificationAction>[
                DarwinNotificationAction.plain(
                  'action_prayed',
                  'صلّيت',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
                DarwinNotificationAction.plain(
                  'action_stop',
                  'إيقاف',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.destructive,
                  },
                ),
              ],
            ),
          ],
          onDidReceiveLocalNotification: onDidReceiveLocalNotification,
        );
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
    await _configureAndroidChannels();
    // Cancel any legacy scheduled local notifications with static text
    try {
      await flutterLocalNotificationsPlugin.cancel(1);
      await flutterLocalNotificationsPlugin.cancel(20);
      await flutterLocalNotificationsPlugin.cancel(900);
      await flutterLocalNotificationsPlugin.cancel(901);
    } catch (_) {}
    try {
      await ensureSchedulingPermissions(requestIfNeeded: false);
    } catch (e) {
      debugPrint('⚠️ ensureSchedulingPermissions check: $e');
    }
    requestIOSPermissions();
    _initialized = true;
  }

  Future<void> _configureTimeZone() async {
    tz.initializeTimeZones();
    try {
      final TimezoneInfo timeZoneInfo =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e, st) {
      debugPrint("⚠️ Could not load local timezone, defaulting to UTC: $e\n$st");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _configureAndroidChannels() async {
    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin == null) return;
    await androidPlugin.createNotificationChannel(_azkarChannel);
    await androidPlugin.createNotificationChannel(_prayerChannel);
    await androidPlugin.createNotificationChannel(_wirdChannel);
    await androidPlugin.createNotificationChannel(_prayerBannerChannel);
  }

  static const int prayerBannerNotificationId = 99901;

  Future<void> showOngoingPrayerBanner({
    required String nextPrayerName,
    required String nextPrayerTime,
    required String countdownStr,
    required String allPrayersLine,
    required String cityName,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _prayerBannerChannel.id,
      _prayerBannerChannel.name,
      channelDescription: _prayerBannerChannel.description,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      icon: 'icon',
      largeIcon: const DrawableResourceAndroidBitmap('icon'),
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        '$allPrayersLine\n📍 المدينة: $cityName',
        contentTitle: '🕌 الصلاة القادمة: $nextPrayerName $nextPrayerTime ($countdownStr)',
        summaryText: 'مواقيت الصلاة',
      ),
      color: const Color(0xFF0F5C4A),
    );

    await flutterLocalNotificationsPlugin.show(
      prayerBannerNotificationId,
      '🕌 $nextPrayerName $nextPrayerTime • $countdownStr',
      allPrayersLine,
      NotificationDetails(android: androidDetails),
      payload: 'taqarrab://prayer_times',
    );
  }

  Future<void> cancelOngoingPrayerBanner() async {
    await flutterLocalNotificationsPlugin.cancel(prayerBannerNotificationId);
  }

  Future<void> displayNotification() async {
    final List<String> adhkar = StaticVars().smallDo3a2;
    if (adhkar.isEmpty) {
      debugPrint('Azkar list is empty, skipping instant notification.');
      return;
    }
    final int randomIndex = Random().nextInt(adhkar.length);
    final hour = DateTime.now().hour;
    final String dynamicTitle = (hour >= 5 && hour < 12)
        ? '☀️ أذكار الصباح'
        : (hour >= 15 && hour < 21)
            ? '🌙 أذكار المساء'
            : (hour >= 21 || hour < 5)
                ? '🌙 أذكار الليل والسكينة'
                : '📿 ذكر وتذكير';

    final text = adhkar[randomIndex];

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _azkarChannel.id,
          _azkarChannel.name,
          channelDescription: _azkarChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'icon',
          largeIcon: const DrawableResourceAndroidBitmap('icon'),
          playSound: true,
          enableVibration: true,
          onlyAlertOnce: false,
          ticker: 'adhkar_reminder',
          styleInformation: BigTextStyleInformation(
            text,
            contentTitle: dynamicTitle,
            summaryText: 'حصن المسلم والأذكار',
          ),
          sound: RawResourceAndroidNotificationSound(
            _stripExtension(soundAzkar1),
          ),
        );
    final DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          sound: soundAzkar1,
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

    final notificationId = 20 + Random().nextInt(10);
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      dynamicTitle,
      text,
      NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      ),
      payload: 'adhkar|instant',
    );
  }

  /// Schedules Azkar notifications via the Unified Native Reminders Engine.
  /// Legacy zonedSchedule calls have been removed to avoid duplicate alarms.
  Future<void> scheduleAzkar({TimeOfDay? timeOfDay}) async {
    try {
      await NativeRemindersBridge.rescheduleAll();
      debugPrint('Azkar scheduled via Unified Native Reminders Engine.');
    } catch (e) {
      debugPrint('Error triggering unified reminder for azkar: $e');
    }
  }

  /// Schedules daily Wird reminders via the Unified Native Reminders Engine.
  /// Legacy zonedSchedule calls have been removed to prevent duplicate alerts.
  Future<void> scheduleDailyWirdNotification({
    TimeOfDay? reminderTime,
    TimeOfDay? lateReminderTime,
  }) async {
    try {
      await NativeRemindersBridge.rescheduleAll();
      debugPrint('Daily Wird scheduled via Unified Native Reminders Engine.');
    } catch (e) {
      debugPrint('Error triggering unified reminder for wird: $e');
    }
  }

  Future<void> cancelWirdNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(900);
      await flutterLocalNotificationsPlugin.cancel(901);
      await NativeRemindersBridge.markWirdCompleted();
    } catch (e) {
      debugPrint('Error cancelling wird notification: $e');
    }
  }

  Future<void> schedulePrayerTimeNotification({
    required PrayerTimes prayerTimes,
  }) async {
    if (!await ensureSchedulingPermissions()) {
      debugPrint(
        'Skipping prayer time scheduling because required permissions are missing.',
      );
      return;
    }

    await _scheduleSinglePrayer(
      id: 2,
      body: 'حان الآن وقت صلاة الفجر',
      scheduledDate: _nextInstanceOfPrayerTime(prayerTimes.fajr),
      prayerKey: 'fajr',
    );
    await _scheduleSinglePrayer(
      id: 3,
      body: 'حان الآن وقت صلاة الظهر',
      scheduledDate: _nextInstanceOfPrayerTime(prayerTimes.dhuhr),
      prayerKey: 'dhuhr',
    );
    await _scheduleSinglePrayer(
      id: 4,
      body: 'حان الآن وقت صلاة العصر',
      scheduledDate: _nextInstanceOfPrayerTime(prayerTimes.asr),
      prayerKey: 'asr',
    );
    await _scheduleSinglePrayer(
      id: 5,
      body: 'حان الآن وقت صلاة المغرب',
      scheduledDate: _nextInstanceOfPrayerTime(prayerTimes.maghrib),
      prayerKey: 'maghrib',
    );
    await _scheduleSinglePrayer(
      id: 6,
      body: 'حان الآن وقت صلاة العشاء',
      scheduledDate: _nextInstanceOfPrayerTime(prayerTimes.isha),
      prayerKey: 'isha',
    );
  }

  Future<void> _scheduleSinglePrayer({
    required int id,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String prayerKey,
  }) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _prayerChannel.id,
          _prayerChannel.name,
          channelDescription: _prayerChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: 'icon',
          largeIcon: const DrawableResourceAndroidBitmap('icon'),
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          sound: RawResourceAndroidNotificationSound(
            _stripExtension(soundAdhan),
          ),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ticker: 'prayer_time',
        );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: soundAdhan,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'وقت الصلاة',
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'adhan|$prayerKey|${scheduledDate.millisecondsSinceEpoch}|$id',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<bool> ensureSchedulingPermissions({
    bool requestIfNeeded = false,
  }) async {
    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin == null) {
      return true;
    }

    Future<bool> ensureNotificationPermission() async {
      try {
        final bool? enabled = await androidPlugin.areNotificationsEnabled();
        if (enabled == null || enabled) {
          return true;
        }
        if (!requestIfNeeded) {
          debugPrint(
            'Notification permission not granted; skipping scheduled notifications.',
          );
          return false;
        }
        final bool granted =
            await androidPlugin.requestNotificationsPermission() ?? false;
        if (!granted) {
          debugPrint(
            'Notification permission request denied by the user.',
          );
          return false;
        }
        final bool? afterRequest = await androidPlugin.areNotificationsEnabled();
        return afterRequest == null || afterRequest;
      } on PlatformException catch (e) {
        debugPrint('⚠️ ensureNotificationPermission PlatformException (${e.code}): ${e.message}');
        return false;
      } catch (e) {
        debugPrint('⚠️ ensureNotificationPermission unexpected error: $e');
        return false;
      }
    }

    Future<bool> ensureExactAlarmPermission() async {
      try {
        final bool? canSchedule =
            await androidPlugin.canScheduleExactNotifications();
        if (canSchedule == null || canSchedule) {
          return true;
        }
        if (!requestIfNeeded) {
          debugPrint(
            'Exact alarm permission not granted; skipping scheduled notifications.',
          );
          return false;
        }
        final bool granted =
            await androidPlugin.requestExactAlarmsPermission() ?? false;
        if (!granted) {
          debugPrint(
            'Exact alarm permission request denied by the user.',
          );
          return false;
        }
        final bool? afterRequest =
            await androidPlugin.canScheduleExactNotifications();
        return afterRequest == null || afterRequest;
      } on PlatformException catch (e) {
        debugPrint('⚠️ ensureExactAlarmPermission PlatformException (${e.code}): ${e.message}');
        return false;
      } catch (e) {
        debugPrint('⚠️ ensureExactAlarmPermission unexpected error: $e');
        return false;
      }
    }

    final bool notificationsOk = await ensureNotificationPermission();
    final bool exactOk = await ensureExactAlarmPermission();

    if (requestIfNeeded) {
      try {
        await androidPlugin.requestFullScreenIntentPermission();
      } catch (e) {
        debugPrint('⚠️ requestFullScreenIntentPermission warning: $e');
      }
    }

    return notificationsOk && exactOk;
  }

  tz.TZDateTime _nextInstanceOfPrayerTime(DateTime prayerTime) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      prayerTime.hour,
      prayerTime.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final actionId = notificationResponse.actionId;
    if (actionId != null && actionId.isNotEmpty) {
      if (actionId == 'action_prayed') {
        debugPrint('🕌 User tapped "صلّيت" from iOS notification action');
        if (notificationResponse.payload != null) {
          try {
            final data = jsonDecode(notificationResponse.payload!) as Map;
            final prayerKey = data['prayerKey']?.toString() ?? '';
            if (prayerKey.isNotEmpty) {
              await NativeAdhanBridge.markPrayerAsPrayed(prayerKey, status: 'on_time');
            }
          } catch (_) {}
        }
        return;
      } else if (actionId == 'action_stop') {
        debugPrint('🛑 User tapped "إيقاف" from iOS notification action');
        await NativeAdhanBridge.stopAdhan();
        return;
      } else if (actionId == 'action_mushaf') {
        await AppNavigationService.instance.handleNavigation({'target_screen': 'wird'});
        return;
      } else if (actionId == 'action_azkar') {
        await AppNavigationService.instance.handleNavigation({'target_screen': 'azkar'});
        return;
      } else if (actionId == 'action_prayer') {
        await AppNavigationService.instance.handleNavigation({'target_screen': 'prayer_times'});
        return;
      }
    }
    await handleNotificationPayload(notificationResponse.payload);
  }

  Future<void> handleNotificationPayload(String? payload) async {
    if (payload == null || payload.isEmpty) {
      return;
    }
    if (payload.startsWith('adhan|')) {
      final parts = payload.split('|');
      final String prayerKey = parts.length > 1 ? parts[1] : '';
      DateTime? scheduledAt;
      int? notificationId;
      if (parts.length > 2) {
        final int? millis = int.tryParse(parts[2]);
        if (millis != null) {
          scheduledAt = DateTime.fromMillisecondsSinceEpoch(millis);
        }
      }
      if (parts.length > 3) {
        notificationId = int.tryParse(parts[3]);
      }
      final arguments = {
        'prayerKey': prayerKey,
        'scheduledAt': scheduledAt,
        'notificationId': notificationId,
      };
      Future.microtask(() {
        if (Get.currentRoute == AppRoutes.adhanAlert) {
          Get.back(closeOverlays: true);
        }
        Get.toNamed(
          AppRoutes.adhanAlert,
          arguments: arguments,
          preventDuplicates: true,
        );
      });
      return;
    }
    if (payload == 'taqarrab://prayer_times' || payload.startsWith('taqarrab://prayer_times')) {
      await Get.toNamed(AppRoutes.adhan);
      return;
    }
    if (payload.startsWith('adhkar')) {
      await Get.toNamed(AppRoutes.azkar);
      return;
    }
    if (payload.startsWith('mushaf|wird')) {
      final parts = payload.split('|');
      final page = parts.length > 2 ? int.tryParse(parts[2]) : null;
      if (page != null) {
        await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': page});
      } else {
        await Get.toNamed(AppRoutes.mushaf);
      }
      return;
    }
    if (payload.startsWith('ramadan|')) {
      final parts = payload.split('|');
      final sub = parts.length > 1 ? parts[1] : '';
      if (sub == 'cannon' || sub == 'suhoor') {
        await Get.toNamed(AppRoutes.ramadanCannonSuhoor);
      } else if (sub == 'khatma') {
        await Get.toNamed(AppRoutes.ramadanKhatma);
      } else if (sub == 'imsakia') {
        await Get.toNamed(AppRoutes.ramadanImsakia);
      } else {
        await Get.toNamed(AppRoutes.ramadanHub);
      }
      return;
    }
    try {
      await Get.toNamed(payload);
    } catch (e) {
      debugPrint('⚠️ Could not navigate to notification payload route "$payload": $e');
    }
  }

  void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    if (body == null) return;
    Get.dialog(
      AlertDialog(
        title: Text(title ?? 'تنبيه'),
        content: Text(body),
        actions: [TextButton(onPressed: Get.back, child: const Text('حسناً'))],
      ),
    );
  }

  void requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(
          alert: true,
          badge: true,
          critical: false,
          sound: true,
        );
  }

  String _stripExtension(String fileName) =>
      fileName.contains('.') ? fileName.split('.').first : fileName;
}
