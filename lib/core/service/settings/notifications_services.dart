import 'dart:async';
import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:get/get.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
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
          requestCriticalPermission: true,
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
    await ensureSchedulingPermissions(requestIfNeeded: true);
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
  }

  Future<void> displayNotification() async {
    final List<String> adhkar = StaticVars().smallDo3a2;
    if (adhkar.isEmpty) {
      debugPrint('Azkar list is empty, skipping instant notification.');
      return;
    }
    final int randomIndex = Random().nextInt(adhkar.length);
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _azkarChannel.id,
          _azkarChannel.name,
          channelDescription: _azkarChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'adhkar_reminder',
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

    await flutterLocalNotificationsPlugin.show(
      20,
      'فَذَكِّرْ',
      adhkar[randomIndex],
      NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      ),
      payload: 'adhkar|instant',
    );
  }

  Future<void> scheduleAzkar({TimeOfDay? timeOfDay}) async {
    if (!await ensureSchedulingPermissions()) {
      debugPrint(
        'Unable to schedule azkar notification because required permissions are missing.',
      );
      return;
    }

    final List<String> adhkar = StaticVars().smallDo3a2;
    if (adhkar.isEmpty) {
      debugPrint('Azkar list is empty, skipping scheduled notification.');
      return;
    }
    final int randomIndex = Random().nextInt(adhkar.length);
    final TimeOfDay reminderTime =
        timeOfDay ?? const TimeOfDay(hour: 10, minute: 10);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _azkarChannel.id,
          _azkarChannel.name,
          channelDescription: _azkarChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          showWhen: false,
          sound: RawResourceAndroidNotificationSound(
            _stripExtension(soundAzkar2),
          ),
        );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: soundAzkar2,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'أذكار الصباح',
      adhkar[randomIndex],
      _nextDailyInstance(timeOfDay: reminderTime),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'adhkar|daily',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextDailyInstance({required TimeOfDay timeOfDay}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedules daily Wird reminders (primary reminder + smart late reminder).
  Future<void> scheduleDailyWirdNotification({
    TimeOfDay? reminderTime,
    TimeOfDay? lateReminderTime,
  }) async {
    if (!await ensureSchedulingPermissions()) {
      debugPrint('Cannot schedule wird: missing scheduling permissions.');
      return;
    }

    final userRepo = UserRepository();
    final plan = await userRepo.getWirdPlan();
    if (plan == null || !plan.enabled) {
      return;
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final isCompletedToday = plan.lastCompletedDate == today;
    if (isCompletedToday) {
      debugPrint('Today wird is already completed; skipping reminder notifications.');
      await cancelWirdNotifications();
      return;
    }

    // Parse reminder time from plan string "HH:MM"
    TimeOfDay primaryTime = const TimeOfDay(hour: 8, minute: 0);
    if (reminderTime != null) {
      primaryTime = reminderTime;
    } else {
      final parts = plan.reminderTime.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 8;
        final m = int.tryParse(parts[1]) ?? 0;
        primaryTime = TimeOfDay(hour: h, minute: m);
      }
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _wirdChannel.id,
      _wirdChannel.name,
      channelDescription: _wirdChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    // 1. Primary reminder
    await flutterLocalNotificationsPlugin.zonedSchedule(
      900,
      'الورد اليومي للقرآن',
      'حان موعد وردك اليومي المبارك (من صـ ${plan.startPage} إلى صـ ${plan.endPage})',
      _nextDailyInstance(timeOfDay: primaryTime),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'mushaf|wird|${plan.startPage}',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 2. Smart late reminder: Reminds user if not finished yet
    final lateTime = lateReminderTime ??
        TimeOfDay(
          hour: (primaryTime.hour + 3) % 24,
          minute: primaryTime.minute,
        );

    final todayLog = await userRepo.getTodayReadingLog();
    final readSoFar = todayLog?.pagesRead ?? 0;
    final target = (plan.endPage - plan.startPage + 1).clamp(1, 604);
    final remaining = (target - readSoFar).clamp(1, target);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      901,
      'تذكير بالورد اليومي',
      'باقي لك $remaining صفحات من وردك اليومي، داوم على ختمتك المباركة',
      _nextDailyInstance(timeOfDay: lateTime),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'mushaf|wird|${plan.startPage}',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelWirdNotifications() async {
    await flutterLocalNotificationsPlugin.cancel(900);
    await flutterLocalNotificationsPlugin.cancel(901);
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
    }

    Future<bool> ensureExactAlarmPermission() async {
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
    }

    final bool notificationsOk = await ensureNotificationPermission();
    final bool exactOk = await ensureExactAlarmPermission();

    if (requestIfNeeded) {
      await androidPlugin.requestFullScreenIntentPermission();
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
    if (payload.startsWith('adhkar')) {
      await Get.toNamed(AppRoutes.azkar);
      return;
    }
    if (payload.startsWith('mushaf|wird')) {
      final parts = payload.split('|');
      final page = parts.length > 2 ? int.tryParse(parts[2]) : null;
      await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': page ?? 1});
      return;
    }
    await Get.toNamed(payload);
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
          critical: true,
          sound: true,
        );
  }

  String _stripExtension(String fileName) =>
      fileName.contains('.') ? fileName.split('.').first : fileName;
}
