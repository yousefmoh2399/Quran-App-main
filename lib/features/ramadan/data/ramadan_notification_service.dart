import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/service/settings/notifications_services.dart';
import '../../../core/services/widget_sync_service.dart';
import 'ramadan_service.dart';

class RamadanNotificationService {
  RamadanNotificationService._();
  static final RamadanNotificationService instance = RamadanNotificationService._();

  static const String channelId = 'ramadan_channel_v1';
  static const String channelName = 'إشعارات وتنبيهات رمضان المبارك';
  static const String channelDesc = 'تنبيهات مدفع الإفطار، السحور المبروك، الإمساك، وختمة القرآن';

  // Reserved Notification IDs
  static const int idSuhoor = 7001;
  static const int idImsak = 7002;
  static const int idIftarCannon = 7003;
  static const int idKhatma = 7004;

  FlutterLocalNotificationsPlugin get _plugin => NotifyHelper().flutterLocalNotificationsPlugin;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initializes the Ramadan notification channel on Android.
  Future<void> initChannel() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
      }
    } catch (e) {
      debugPrint('Error initializing Ramadan notification channel: $e');
    }
  }

  /// Recalculates and schedules all active Ramadan notifications.
  Future<void> scheduleAll() async {
    try {
      await initChannel();

      final hasPermission = await NotifyHelper().ensureSchedulingPermissions();
      if (!hasPermission) {
        debugPrint('Ramadan scheduling skipped: notification permissions not granted.');
        return;
      }

      final ramadanService = RamadanService.instance;
      final isCannonOn = await ramadanService.isIftarCannonEnabled();
      final isSuhoorOn = await ramadanService.isSuhoorAlertEnabled();
      final suhoorMinutes = await ramadanService.getSuhoorMinutesBeforeFajr();

      final days = ramadanService.calculate30DaysImsakia(imsakMinutesBeforeFajr: 15);
      if (days.isEmpty) return;

      final now = DateTime.now();

      // Find the upcoming day info (today or tomorrow)
      final todayInfo = days.firstWhere(
        (d) => d.isToday,
        orElse: () => days.first,
      );

      // 1. Schedule Suhoor Alert
      if (isSuhoorOn) {
        DateTime suhoorTime = todayInfo.fajrDateTime.subtract(Duration(minutes: suhoorMinutes));
        if (suhoorTime.isBefore(now)) {
          // Move to tomorrow's fajr
          final tomorrowDay = todayInfo.dayNumber < 30 ? days[todayInfo.dayNumber] : days.first;
          suhoorTime = tomorrowDay.fajrDateTime.subtract(Duration(minutes: suhoorMinutes));
        }

        if (suhoorTime.isAfter(now)) {
          await _scheduleNotification(
            id: idSuhoor,
            title: '🌙 موعد السحور المبارك',
            body: 'قال رسول الله ﷺ: «تسحروا فإن في السحور بركة» - متبقي على الفجر $suhoorMinutes دقيقة.',
            scheduledDate: suhoorTime,
            payload: 'ramadan|suhoor',
            soundFile: 'azkar_1',
          );
        }
      } else {
        await _plugin.cancel(idSuhoor);
      }

      // 2. Schedule Imsak Alert (15 minutes before Fajr)
      DateTime imsakTime = todayInfo.imsakDateTime;
      if (imsakTime.isBefore(now)) {
        final tomorrowDay = todayInfo.dayNumber < 30 ? days[todayInfo.dayNumber] : days.first;
        imsakTime = tomorrowDay.imsakDateTime;
      }

      if (imsakTime.isAfter(now)) {
        await _scheduleNotification(
          id: idImsak,
          title: '⏳ حان وقت الإمساك',
          body: 'أمسك عن الطعام والشراب، وأقبل على ذكر الله والاستعداد لأذان الفجر.',
          scheduledDate: imsakTime,
          payload: 'ramadan|imsakia',
          soundFile: 'azkar_1',
        );
      }

      // 3. Schedule Iftar Cannon Alert (at Maghrib)
      if (isCannonOn) {
        DateTime iftarTime = todayInfo.maghribDateTime;
        if (iftarTime.isBefore(now)) {
          final tomorrowDay = todayInfo.dayNumber < 30 ? days[todayInfo.dayNumber] : days.first;
          iftarTime = tomorrowDay.maghribDateTime;
        }

        if (iftarTime.isAfter(now)) {
          await _scheduleNotification(
            id: idIftarCannon,
            title: '💥 مدفع الإفطار.. ذهب الظمأ!',
            body: '«ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ» 🌙 تقبل الله صيامكم.',
            scheduledDate: iftarTime,
            payload: 'ramadan|cannon',
            soundFile: 'cannon',
          );
        }
      } else {
        await _plugin.cancel(idIftarCannon);
      }

      // 4. Also trigger Home Widget Synchronization for Ramadan
      final nextEvent = ramadanService.getNextRamadanEvent();
      final diff = nextEvent['diff'] as Duration;
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      final countdownStr = '$h:$m:$s';

      await WidgetSyncService.syncRamadanData(
        dayNumber: todayInfo.dayNumber,
        dayTitle: 'اليوم ${todayInfo.dayNumber} من رمضان',
        eventTitle: nextEvent['title'] as String,
        countdownText: countdownStr,
        imsakTime: todayInfo.imsakTime,
        iftarTime: todayInfo.maghribTime,
        dailyDua: 'ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ.',
      );

      debugPrint('Ramadan notifications & widgets successfully scheduled.');
    } catch (e) {
      debugPrint('Error in scheduleAll Ramadan notifications: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
    String? soundFile,
  }) async {
    await _plugin.cancel(id);

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    AndroidNotificationDetails androidDetails;
    if (soundFile != null && soundFile.isNotEmpty) {
      androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundFile),
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        icon: 'icon',
        largeIcon: const DrawableResourceAndroidBitmap('icon'),
      );
    } else {
      androidDetails = const AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'icon',
        largeIcon: DrawableResourceAndroidBitmap('icon'),
      );
    }

    DarwinNotificationDetails iosDetails;
    if (soundFile != null && soundFile.isNotEmpty) {
      final iosSound = soundFile == 'adhan' ? 'adhan.wav' : '$soundFile.wav';
      iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: iosSound,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
    } else {
      iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Immediately triggers a test notification for Suhoor.
  Future<void> testTriggerSuhoor() async {
    await initChannel();
    final minutes = await RamadanService.instance.getSuhoorMinutesBeforeFajr();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('azkar_1'),
      enableVibration: true,
      icon: 'icon',
      largeIcon: const DrawableResourceAndroidBitmap('icon'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'azkar_1.wav',
    );

    await _plugin.show(
      idSuhoor,
      '🌙 تجربة تنبيه السحور المبارك',
      'قال رسول الله ﷺ: «تسحروا فإن في السحور بركة» - متبقي على الفجر $minutes دقيقة.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'ramadan|suhoor',
    );
  }

  /// Immediately triggers a test notification for Iftar Cannon.
  Future<void> testTriggerIftarCannon() async {
    await initChannel();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('adhan'),
      enableVibration: true,
      icon: 'icon',
      largeIcon: const DrawableResourceAndroidBitmap('icon'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'adhan.wav',
    );

    await _plugin.show(
      idIftarCannon,
      '💥 تجربة مدفع الإفطار.. ذهب الظمأ!',
      '«ذَهَبَ الظَّمَأُ، وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ» 🌙 تقبل الله صيامكم.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'ramadan|cannon',
    );
  }

  /// Immediately triggers a test notification for Imsak.
  Future<void> testTriggerImsak() async {
    await initChannel();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('azkar_1'),
      enableVibration: true,
      icon: 'icon',
      largeIcon: const DrawableResourceAndroidBitmap('icon'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'azkar_1.wav',
    );

    await _plugin.show(
      idImsak,
      '⏳ تجربة تنبيه الإمساك',
      'أمسك عن الطعام والشراب، وأقبل على ذكر الله والاستعداد لأذان الفجر.',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'ramadan|imsakia',
    );
  }

  /// Immediately triggers a test notification for Khatma reminder.
  Future<void> testTriggerKhatma() async {
    await initChannel();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('azkar_1'),
      enableVibration: true,
      icon: 'icon',
      largeIcon: const DrawableResourceAndroidBitmap('icon'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'azkar_1.wav',
    );

    await _plugin.show(
      idKhatma,
      '📖 تجربة ورد ختمة رمضان',
      'لا تنسَ قراءة وردك القرآني اليومي ومتابعة صفحاتك نحو ختم كتاب الله 🤲',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'ramadan|khatma',
    );
  }

  /// Cancels all scheduled Ramadan notifications.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancel(idSuhoor);
      await _plugin.cancel(idImsak);
      await _plugin.cancel(idIftarCannon);
      await _plugin.cancel(idKhatma);
      debugPrint('All Ramadan notifications cancelled.');
    } catch (e) {
      debugPrint('Error cancelling Ramadan notifications: $e');
    }
  }
}
