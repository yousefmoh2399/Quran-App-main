import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/ios_reminder_scheduler.dart';

/// Dart bridge to communicate with the Native Unified Reminders Engine on Android
/// and [IosReminderNotificationScheduler] on iOS.
class NativeRemindersBridge {
  static const MethodChannel _channel = MethodChannel('com.taqarrab.quran/native_reminders');

  /// Indicates whether iOS reminders engine should be used.
  static bool get isIOS => Platform.isIOS || !Platform.isAndroid;

  /// Fetches all reminders stored in SQLite (Android) or SharedPreferences (iOS).
  static Future<List<Map<String, dynamic>>> getAllReminders() async {
    if (isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] getAllReminders called.');
      return IosReminderNotificationScheduler.instance.getAllReminders();
    }
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getAllReminders');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] getAllReminders error: $e\n$st');
      return [];
    }
  }

  /// Fetches a single reminder by ID.
  static Future<Map<String, dynamic>?> getReminder(String id) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] getReminder($id) called.');
      return IosReminderNotificationScheduler.instance.getReminder(id);
    }
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getReminder', {'id': id});
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] getReminder error: $e\n$st');
      return null;
    }
  }

  /// Inserts or updates a reminder and recalculates schedule.
  static Future<bool> saveReminder(Map<String, dynamic> reminder) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] saveReminder called.');
      return IosReminderNotificationScheduler.instance.saveReminder(reminder);
    }
    try {
      final success = await _channel.invokeMethod<bool>('saveReminder', {'reminder': reminder});
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] saveReminder error: $e\n$st');
      return false;
    }
  }

  /// Toggles the enabled state of a reminder.
  static Future<bool> toggleReminder(String id, bool enabled) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] toggleReminder($id, $enabled) called.');
      return IosReminderNotificationScheduler.instance.toggleReminder(id, enabled);
    }
    try {
      final success = await _channel.invokeMethod<bool>('toggleReminder', {
        'id': id,
        'enabled': enabled,
      });
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] toggleReminder error: $e\n$st');
      return false;
    }
  }

  /// Deletes a reminder.
  static Future<bool> deleteReminder(String id) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] deleteReminder($id) called.');
      return IosReminderNotificationScheduler.instance.deleteReminder(id);
    }
    try {
      final success = await _channel.invokeMethod<bool>('deleteReminder', {'id': id});
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] deleteReminder error: $e\n$st');
      return false;
    }
  }

  /// Forces recalculation and scheduling of reminders.
  static Future<bool> rescheduleAll() async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] rescheduleAll called.');
      return IosReminderNotificationScheduler.instance.rescheduleAll();
    }
    try {
      final success = await _channel.invokeMethod<bool>('rescheduleAll');
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] rescheduleAll error: $e\n$st');
      return false;
    }
  }

  /// Immediately triggers a reminder notification for testing.
  static Future<bool> testTriggerReminder(String id) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] testTriggerReminder($id) called.');
      return IosReminderNotificationScheduler.instance.testTriggerReminder(id);
    }
    try {
      final success = await _channel.invokeMethod<bool>('testTriggerReminder', {'id': id});
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] testTriggerReminder error: $e\n$st');
      return false;
    }
  }

  /// Retrieves list of upcoming alarms and cancellation statuses for debug view.
  static Future<List<Map<String, dynamic>>> getUpcomingAlarms() async {
    if (Platform.isIOS) {
      return [];
    }
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getUpcomingAlarms');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] getUpcomingAlarms error: $e\n$st');
      return [];
    }
  }

  /// Marks today's daily wird as completed so the reminder is cancelled/suppressed.
  static Future<bool> markWirdCompleted({String? date}) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] markWirdCompleted called.');
      return IosReminderNotificationScheduler.instance.markWirdCompleted(date: date);
    }
    try {
      final success = await _channel.invokeMethod<bool>('markWirdCompleted', {'date': date});
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] markWirdCompleted error: $e\n$st');
      return false;
    }
  }

  /// Marks a specific commute wird slot as completed.
  static Future<bool> markCommuteCompleted({required String slotId, String? date}) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] markCommuteCompleted called.');
      return IosReminderNotificationScheduler.instance.markCommuteCompleted(slotId: slotId, date: date);
    }
    try {
      final success = await _channel.invokeMethod<bool>('markCommuteCompleted', {
        'slotId': slotId,
        'date': date,
      });
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] markCommuteCompleted error: $e\n$st');
      return false;
    }
  }

  /// Records a donation for monthly charity reminder.
  static Future<bool> markSadaqahDonated({String? date, double? amount, String? note}) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeRemindersBridge] markSadaqahDonated called.');
      return IosReminderNotificationScheduler.instance.markSadaqahDonated(
        date: date,
        amount: amount,
        note: note,
      );
    }
    try {
      final success = await _channel.invokeMethod<bool>('markSadaqahDonated', {
        'date': date,
        'amount': amount,
        'note': note,
      });
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] markSadaqahDonated error: $e\n$st');
      return false;
    }
  }

  /// Fetches local charity logs.
  static Future<List<Map<String, dynamic>>> getSadaqahLogs() async {
    if (Platform.isIOS) {
      return IosReminderNotificationScheduler.instance.getSadaqahLogs();
    }
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getSadaqahLogs');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] getSadaqahLogs error: $e\n$st');
      return [];
    }
  }

  static const String prefsSoundsKey = 'reminder_sound_settings';

  /// Previews/plays an audio sound natively without third-party dependencies.
  static Future<bool> previewSound(String soundKey) async {
    try {
      final success = await _channel.invokeMethod<bool>('previewSound', {'soundKey': soundKey});
      return success ?? false;
    } on MissingPluginException {
      return true;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] previewSound error: $e\n$st');
      return false;
    }
  }

  /// Stops any currently playing preview sound.
  static Future<bool> stopSound() async {
    try {
      final success = await _channel.invokeMethod<bool>('stopSound');
      return success ?? false;
    } on MissingPluginException {
      return true;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] stopSound error: $e\n$st');
      return false;
    }
  }

  /// Saves notification sound configuration.
  static Future<bool> saveSoundSettings({
    required String mode,
    required String unifiedSound,
    required String wirdSound,
    required String commuteSound,
    required String sadaqahSound,
    required String azkarSound,
  }) async {
    if (isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final map = {
          'mode': mode,
          'unifiedSound': unifiedSound,
          'wirdSound': wirdSound,
          'commuteSound': commuteSound,
          'sadaqahSound': sadaqahSound,
          'azkarSound': azkarSound,
        };
        await prefs.setString(prefsSoundsKey, jsonEncode(map));
        debugPrint('📱 [iOS NativeRemindersBridge] Saved sound settings: $map');
        try {
          await IosReminderNotificationScheduler.instance.rescheduleAll();
        } catch (_) {}
        return true;
      } catch (e, st) {
        debugPrint('❌ [iOS NativeRemindersBridge] saveSoundSettings error: $e\n$st');
        return false;
      }
    }
    try {
      final success = await _channel.invokeMethod<bool>('saveSoundSettings', {
        'mode': mode,
        'unifiedSound': unifiedSound,
        'wirdSound': wirdSound,
        'commuteSound': commuteSound,
        'sadaqahSound': sadaqahSound,
        'azkarSound': azkarSound,
      });
      return success ?? false;
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] saveSoundSettings error: $e\n$st');
      return false;
    }
  }

  /// Retrieves current notification sound settings from native preferences.
  static Future<Map<String, String>> getSoundSettings() async {
    if (isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final str = prefs.getString(prefsSoundsKey);
        if (str == null || str.isEmpty) return {};
        final decoded = jsonDecode(str) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      } catch (e, st) {
        debugPrint('❌ [iOS NativeRemindersBridge] getSoundSettings error: $e\n$st');
        return {};
      }
    }
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSoundSettings');
      if (result == null) return {};
      return result.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (e, st) {
      debugPrint('❌ [NativeRemindersBridge] getSoundSettings error: $e\n$st');
      return {};
    }
  }
}
