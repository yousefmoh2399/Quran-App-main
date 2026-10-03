import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../features/reminders/data/reminders_calendar_calc.dart';
import 'notification_budget.dart';

/// Pre-schedules reminder notifications on iOS within the remaining 24 slots of the 64-notification budget.
///
/// Features:
/// - Daily Wird: 7 slots (IDs 2000..2006).
/// - Commuting/Transit: 7 slots (IDs 2100..2106).
/// - Monthly Sadaqah: 1 slot (ID 2200).
/// - Periodic Rotating Azkar: 8 slots (IDs 2300..2307).
/// - Total reminder slots: 7 + 7 + 1 + 8 = 23 <= 24.
/// - Uses [RemindersCalendarCalc] for Gregorian/Hijri month lengths and day calculations.
/// - Cancels today's Wird notification upon marking wird completed.
class IosReminderNotificationScheduler {
  static const String prefsRemindersKey = 'ios_reminders_db';
  static const String prefsSadaqahLogsKey = 'ios_sadaqah_logs';

  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final DateTime Function() nowProvider;

  IosReminderNotificationScheduler({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    DateTime Function()? nowProvider,
  })  : notificationsPlugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin(),
        nowProvider = nowProvider ?? DateTime.now;

  static final IosReminderNotificationScheduler instance =
      IosReminderNotificationScheduler();

  // --- Rotating Azkar Templates ---
  static const List<String> _rotatingAzkar = [
    'سبحان الله وبحمده، سبحان الله العظيم',
    'لا حول ولا قوة إلا بالله العلي العظيم',
    'اللهم صلِّ وسلم وبارك على نبينا محمد',
    'أستغفر الله العظيم وأتوب إليه',
    'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير',
    'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر',
    'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله',
    'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم',
  ];

  // --- Storage Helpers ---
  Future<Map<String, Map<String, dynamic>>> _loadAllRemindersMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(prefsRemindersKey);
      if (str == null || str.isEmpty) return {};
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
      );
    } catch (e) {
      debugPrint('⚠️ [IosReminderScheduler] Error loading reminders: $e');
      return {};
    }
  }

  Future<void> _saveAllRemindersMap(Map<String, Map<String, dynamic>> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsRemindersKey, jsonEncode(map));
  }

  // --- CRUD API mirrored for NativeRemindersBridge ---

  Future<List<Map<String, dynamic>>> getAllReminders() async {
    final map = await _loadAllRemindersMap();
    return map.values.toList();
  }

  Future<Map<String, dynamic>?> getReminder(String id) async {
    final map = await _loadAllRemindersMap();
    return map[id];
  }

  Future<bool> saveReminder(Map<String, dynamic> reminder) async {
    try {
      final id = reminder['id']?.toString();
      if (id == null) return false;

      final map = await _loadAllRemindersMap();
      map[id] = reminder;
      await _saveAllRemindersMap(map);

      debugPrint('📱 [IosReminderScheduler] Saved reminder "$id". Rescheduling...');
      await rescheduleAll();
      return true;
    } catch (e, st) {
      debugPrint('❌ [IosReminderScheduler] Failed to save reminder: $e\n$st');
      return false;
    }
  }

  Future<bool> toggleReminder(String id, bool enabled) async {
    final map = await _loadAllRemindersMap();
    if (!map.containsKey(id)) return false;
    map[id]!['enabled'] = enabled ? 1 : 0;
    await _saveAllRemindersMap(map);
    await rescheduleAll();
    return true;
  }

  Future<bool> deleteReminder(String id) async {
    final map = await _loadAllRemindersMap();
    if (!map.containsKey(id)) return false;
    map.remove(id);
    await _saveAllRemindersMap(map);
    await rescheduleAll();
    return true;
  }

  void _ensureTimezone() {
    try {
      if (tz.timeZoneDatabase.locations.isEmpty) {
        tz_data.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (_) {}
  }

  /// Reschedules all reminder categories on iOS from currently saved reminders.
  Future<bool> rescheduleAll() async {
    _ensureTimezone();
    NotificationBudget.validateBudget();
    final reminders = await _loadAllRemindersMap();

    // 1. Cancel existing reminder notification IDs
    await cancelAllReminderNotifications();

    final now = nowProvider();

    // 2. Schedule Daily Wird
    final wirdReminder = reminders['wird_daily'] ?? reminders.values.firstWhere(
      (r) => r['type'] == 'wird_daily',
      orElse: () => {},
    );
    if (wirdReminder.isNotEmpty && (wirdReminder['enabled'] == 1 || wirdReminder['enabled'] == true)) {
      await _scheduleWird(wirdReminder, now);
    }

    // 3. Schedule Commuting/Transit
    final transitReminder = reminders['commute_morning'] ?? reminders.values.firstWhere(
      (r) => r['type'] == 'commute',
      orElse: () => {},
    );
    if (transitReminder.isNotEmpty && (transitReminder['enabled'] == 1 || transitReminder['enabled'] == true)) {
      await _scheduleTransit(transitReminder, now);
    }

    // 4. Schedule Monthly Sadaqah
    final sadaqahReminder = reminders['sadaqah_monthly'] ?? reminders.values.firstWhere(
      (r) => r['type'] == 'sadaqah_monthly',
      orElse: () => {},
    );
    if (sadaqahReminder.isNotEmpty && (sadaqahReminder['enabled'] == 1 || sadaqahReminder['enabled'] == true)) {
      await _scheduleSadaqah(sadaqahReminder, now);
    }

    // 5. Schedule Periodic Azkar
    final azkarReminder = reminders['azkar_periodic'] ?? reminders.values.firstWhere(
      (r) => r['type'] == 'azkar_periodic',
      orElse: () => {},
    );
    if (azkarReminder.isNotEmpty && (azkarReminder['enabled'] == 1 || azkarReminder['enabled'] == true)) {
      await _schedulePeriodicAzkar(azkarReminder, now);
    }

    debugPrint('✅ [IosReminderScheduler] Completed rescheduling all reminders on iOS.');
    return true;
  }

  /// Cancels all reminder notification IDs defined in the budget.
  Future<void> cancelAllReminderNotifications() async {
    for (final id in NotificationBudget.getAllWirdIds()) {
      try { await notificationsPlugin.cancel(id); } catch (_) {}
    }
    for (final id in NotificationBudget.getAllTransitIds()) {
      try { await notificationsPlugin.cancel(id); } catch (_) {}
    }
    try { await notificationsPlugin.cancel(NotificationBudget.getSadaqahId()); } catch (_) {}
    for (final id in NotificationBudget.getAllAzkarIds()) {
      try { await notificationsPlugin.cancel(id); } catch (_) {}
    }
  }

  /// Schedules next 7 days for Daily Wird (IDs 2000..2006).
  Future<void> _scheduleWird(Map<String, dynamic> reminder, DateTime now) async {
    Map<String, dynamic> sched = {};
    if (reminder['schedule_json'] is String) {
      sched = jsonDecode(reminder['schedule_json'] as String) as Map<String, dynamic>;
    } else if (reminder['schedule_json'] is Map) {
      sched = Map<String, dynamic>.from(reminder['schedule_json'] as Map);
    }
    final hour = (sched['hour'] as num?)?.toInt() ?? 9;
    final minute = (sched['minute'] as num?)?.toInt() ?? 0;

    for (int dayOffset = 0; dayOffset < NotificationBudget.wirdSlotCount; dayOffset++) {
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        hour,
        minute,
      );

      if (!scheduledDate.isAfter(now)) continue;

      final id = NotificationBudget.getWirdId(dayOffset);
      final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'azkar_1.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await notificationsPlugin.zonedSchedule(
        id,
        'ورد القرآن الكريم',
        'حان موعد وردك اليومي، تلاوة صفحة من كتاب الله تنير يومك وتزيد بركتك 📖',
        tzTime,
        const NotificationDetails(iOS: darwinDetails),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({'type': 'wird_daily', 'dayOffset': dayOffset}),
      );
    }
  }

  /// Schedules next 7 days for Commute reminder (IDs 2100..2106).
  Future<void> _scheduleTransit(Map<String, dynamic> reminder, DateTime now) async {
    Map<String, dynamic> sched = {};
    if (reminder['schedule_json'] is String) {
      sched = jsonDecode(reminder['schedule_json'] as String) as Map<String, dynamic>;
    } else if (reminder['schedule_json'] is Map) {
      sched = Map<String, dynamic>.from(reminder['schedule_json'] as Map);
    }

    final hour = (sched['hour'] as num?)?.toInt() ?? 7;
    final minute = (sched['minute'] as num?)?.toInt() ?? 30;

    for (int dayOffset = 0; dayOffset < NotificationBudget.transitSlotCount; dayOffset++) {
      final scheduledDate = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        hour,
        minute,
      );

      if (!scheduledDate.isAfter(now)) continue;

      final id = NotificationBudget.getTransitId(dayOffset);
      final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'azkar_1.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await notificationsPlugin.zonedSchedule(
        id,
        'أذكار وورد المواصلات',
        'استثمر وقت تنقلك في ذكر الله والاستماع للقرآن الكريم 🚗',
        tzTime,
        const NotificationDetails(iOS: darwinDetails),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({'type': 'transit', 'dayOffset': dayOffset}),
      );
    }
  }

  /// Schedules next monthly occurrence for Monthly Sadaqah (ID 2200).
  ///
  /// Uses [RemindersCalendarCalc.getNextGregorianMonthlyTrigger] to strictly
  /// guarantee correct month-end clamping (28/29/30/31).
  Future<void> _scheduleSadaqah(Map<String, dynamic> reminder, DateTime now) async {
    Map<String, dynamic> sched = {};
    if (reminder['schedule_json'] is String) {
      sched = jsonDecode(reminder['schedule_json'] as String) as Map<String, dynamic>;
    } else if (reminder['schedule_json'] is Map) {
      sched = Map<String, dynamic>.from(reminder['schedule_json'] as Map);
    }

    final dayType = sched['day_type']?.toString() ?? 'day_of_month';
    final targetDay = (sched['target_day'] as num?)?.toInt() ?? 25;
    final hour = (sched['hour'] as num?)?.toInt() ?? 10;
    final minute = (sched['minute'] as num?)?.toInt() ?? 0;

    final targetDate = RemindersCalendarCalc.getNextGregorianMonthlyTrigger(
      dayType: dayType,
      targetDay: targetDay,
      hour: hour,
      minute: minute,
      now: now,
    );

    final id = NotificationBudget.getSadaqahId();
    final tzTime = tz.TZDateTime.from(targetDate, tz.local);

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'azkar_1.wav',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await notificationsPlugin.zonedSchedule(
      id,
      'تذكير الصدقة الشهرية',
      'مانقص مال من صدقة — تذكير بإخراج صدقتك الشهرية المباركة 🤍',
      tzTime,
      const NotificationDetails(iOS: darwinDetails),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({'type': 'sadaqah_monthly'}),
    );
  }

  /// Schedules up to 8 periodic rotating daytime Azkar slots (IDs 2300..2307).
  Future<void> _schedulePeriodicAzkar(Map<String, dynamic> reminder, DateTime now) async {
    Map<String, dynamic> sched = {};
    if (reminder['schedule_json'] is String) {
      sched = jsonDecode(reminder['schedule_json'] as String) as Map<String, dynamic>;
    } else if (reminder['schedule_json'] is Map) {
      sched = Map<String, dynamic>.from(reminder['schedule_json'] as Map);
    }

    final intervalMinutes = (sched['interval_minutes'] as num?)?.toInt() ?? 60;
    final fromH = (sched['from_hour'] as num?)?.toInt() ?? 8;
    final fromM = (sched['from_minute'] as num?)?.toInt() ?? 0;
    final toH = (sched['to_hour'] as num?)?.toInt() ?? 22;
    final toM = (sched['to_minute'] as num?)?.toInt() ?? 0;

    var current = DateTime(now.year, now.month, now.day, fromH, fromM);
    final end = DateTime(now.year, now.month, now.day, toH, toM);

    int slotIndex = 0;
    while (current.isBefore(end) && slotIndex < NotificationBudget.azkarPeriodicSlotCount) {
      if (current.isAfter(now)) {
        final id = NotificationBudget.getAzkarId(slotIndex);
        final tzTime = tz.TZDateTime.from(current, tz.local);
        final zikrText = _rotatingAzkar[slotIndex % _rotatingAzkar.length];

        const darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'azkar_1.wav',
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

        await notificationsPlugin.zonedSchedule(
          id,
          'أذكار وتسابيح',
          zikrText,
          tzTime,
          const NotificationDetails(iOS: darwinDetails),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: jsonEncode({'type': 'azkar_periodic', 'slotIndex': slotIndex}),
        );
      }
      current = current.add(Duration(minutes: intervalMinutes));
      slotIndex++;
    }
  }

  // --- Cancellation / Mark as Completed ---

  /// Cancels today's Daily Wird notification when the user reads their wird with the app open,
  /// and reschedules future ones.
  Future<bool> markWirdCompleted({String? date}) async {
    try {
      final todayWirdId = NotificationBudget.getWirdId(0);
      await notificationsPlugin.cancel(todayWirdId);
      debugPrint('📱 [IosReminderScheduler] Cancelled today\'s wird notification (ID: $todayWirdId) upon reading.');
      return true;
    } catch (e, st) {
      debugPrint('⚠️ [IosReminderScheduler] Error cancelling today\'s wird: $e\n$st');
      return false;
    }
  }

  Future<bool> markCommuteCompleted({required String slotId, String? date}) async {
    try {
      final todayTransitId = NotificationBudget.getTransitId(0);
      await notificationsPlugin.cancel(todayTransitId);
      debugPrint('📱 [IosReminderScheduler] Cancelled today\'s transit notification (ID: $todayTransitId).');
      return true;
    } catch (e) {
      debugPrint('⚠️ [IosReminderScheduler] Error cancelling today\'s transit: $e');
      return false;
    }
  }

  Future<bool> markSadaqahDonated({String? date, double? amount, String? note}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsStr = prefs.getString(prefsSadaqahLogsKey) ?? '[]';
      final logs = List<Map<String, dynamic>>.from(jsonDecode(logsStr) as List);
      logs.add({
        'date': date ?? DateTime.now().toIso8601String(),
        'amount': amount ?? 0.0,
        'note': note ?? '',
      });
      await prefs.setString(prefsSadaqahLogsKey, jsonEncode(logs));

      // Reschedule next month
      await rescheduleAll();
      debugPrint('📱 [IosReminderScheduler] Marked sadaqah donated and rescheduled.');
      return true;
    } catch (e) {
      debugPrint('⚠️ [IosReminderScheduler] Error marking sadaqah: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSadaqahLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsStr = prefs.getString(prefsSadaqahLogsKey) ?? '[]';
      return List<Map<String, dynamic>>.from(jsonDecode(logsStr) as List);
    } catch (e) {
      debugPrint('⚠️ [IosReminderScheduler] Error getting sadaqah logs: $e');
      return [];
    }
  }

  Future<bool> testTriggerReminder(String id) async {
    try {
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'azkar_1.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const testId = 998;
      await notificationsPlugin.show(
        testId,
        'تجربة تذكير: $id',
        'هذا إشعار تجريبي فوري للتأكد من وصول التنبيه وصوته على iOS',
        const NotificationDetails(iOS: darwinDetails),
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ [IosReminderScheduler] Failed testTriggerReminder: $e');
      return false;
    }
  }
}
