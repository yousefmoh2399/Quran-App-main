import 'package:flutter/services.dart';

/// Dart bridge to communicate with the Native Kotlin Unified Reminders Engine.
class NativeRemindersBridge {
  static const MethodChannel _channel = MethodChannel('com.taqarrab.quran/native_reminders');

  /// Fetches all reminders stored in SQLite.
  static Future<List<Map<String, dynamic>>> getAllReminders() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getAllReminders');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches a single reminder by ID.
  static Future<Map<String, dynamic>?> getReminder(String id) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getReminder', {'id': id});
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  /// Inserts or updates a reminder and recalculates the single closest alarm.
  static Future<bool> saveReminder(Map<String, dynamic> reminder) async {
    try {
      final success = await _channel.invokeMethod<bool>('saveReminder', {'reminder': reminder});
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Toggles the enabled state of a reminder.
  static Future<bool> toggleReminder(String id, bool enabled) async {
    try {
      final success = await _channel.invokeMethod<bool>('toggleReminder', {
        'id': id,
        'enabled': enabled,
      });
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a reminder.
  static Future<bool> deleteReminder(String id) async {
    try {
      final success = await _channel.invokeMethod<bool>('deleteReminder', {'id': id});
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Forces recalculation and scheduling of the next closest alarm.
  static Future<bool> rescheduleAll() async {
    try {
      final success = await _channel.invokeMethod<bool>('rescheduleAll');
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Immediately triggers a reminder notification for testing.
  static Future<bool> testTriggerReminder(String id) async {
    try {
      final success = await _channel.invokeMethod<bool>('testTriggerReminder', {'id': id});
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Retrieves list of upcoming alarms and cancellation statuses for debug view.
  static Future<List<Map<String, dynamic>>> getUpcomingAlarms() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getUpcomingAlarms');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Marks today's daily wird as completed so the reminder is cancelled/suppressed.
  static Future<bool> markWirdCompleted({String? date}) async {
    try {
      final success = await _channel.invokeMethod<bool>('markWirdCompleted', {'date': date});
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Marks a specific commute wird slot as completed.
  static Future<bool> markCommuteCompleted({required String slotId, String? date}) async {
    try {
      final success = await _channel.invokeMethod<bool>('markCommuteCompleted', {
        'slotId': slotId,
        'date': date,
      });
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Records a donation for monthly charity reminder.
  static Future<bool> markSadaqahDonated({String? date, double? amount, String? note}) async {
    try {
      final success = await _channel.invokeMethod<bool>('markSadaqahDonated', {
        'date': date,
        'amount': amount,
        'note': note,
      });
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Fetches local charity logs.
  static Future<List<Map<String, dynamic>>> getSadaqahLogs() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getSadaqahLogs');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Previews/plays an audio sound natively without third-party dependencies.
  static Future<bool> previewSound(String soundKey) async {
    try {
      final success = await _channel.invokeMethod<bool>('previewSound', {'soundKey': soundKey});
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Stops any currently playing preview sound.
  static Future<bool> stopSound() async {
    try {
      final success = await _channel.invokeMethod<bool>('stopSound');
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Saves notification sound configuration (custom per category, unified, or system default).
  static Future<bool> saveSoundSettings({
    required String mode,
    required String unifiedSound,
    required String wirdSound,
    required String commuteSound,
    required String sadaqahSound,
    required String azkarSound,
  }) async {
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
    } catch (e) {
      return false;
    }
  }

  /// Retrieves current notification sound settings from native preferences.
  static Future<Map<String, String>> getSoundSettings() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getSoundSettings');
      if (result == null) return {};
      return result.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (e) {
      return {};
    }
  }
}
