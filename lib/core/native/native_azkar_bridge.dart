import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'native_reminders_bridge.dart';

class NativeAzkarBridge {
  static const MethodChannel _channel = MethodChannel('native_azkar_bridge');

  /// Saves settings and reschedules the chained alarm.
  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final res = await _channel.invokeMethod<bool>('saveSettings', settings);

      // Sync into Unified Reminders Engine
      try {
        final interval = (settings['interval'] as num?)?.toInt() ?? 60;
        final enabled = (settings['enabled'] as bool?) ?? true;
        final fromH = (settings['activeFromHour'] as num?)?.toInt() ?? 8;
        final fromM = (settings['activeFromMinute'] as num?)?.toInt() ?? 0;
        final toH = (settings['activeToHour'] as num?)?.toInt() ?? 22;
        final toM = (settings['activeToMinute'] as num?)?.toInt() ?? 0;

        await NativeRemindersBridge.saveReminder({
          'id': 'azkar_periodic',
          'type': 'azkar_periodic',
          'schedule_json': jsonEncode({
            'interval_minutes': interval,
            'from_hour': fromH,
            'from_minute': fromM,
            'to_hour': toH,
            'to_minute': toM,
          }),
          'payload_json': jsonEncode({'title': 'أذكار وتسابيح'}),
          'enabled': enabled ? 1 : 0,
          'last_triggered': 0,
        });
      } catch (_) {}

      return res ?? true;
    } catch (e) {
      debugPrint('Error saving native azkar settings: $e');
      return false;
    }
  }

  /// Retrieves current native azkar settings.
  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getSettings');
      return res;
    } catch (e) {
      debugPrint('Error getting native azkar settings: $e');
      return null;
    }
  }

  /// Triggers recalculation and next alarm scheduling.
  static Future<void> reschedule() async {
    try {
      await _channel.invokeMethod('reschedule');
    } catch (e) {
      debugPrint('Error rescheduling azkar: $e');
    }
  }

  /// Cancels all scheduled azkar notifications.
  static Future<void> cancelAzkar() async {
    try {
      await _channel.invokeMethod('cancelAzkar');
    } catch (e) {
      debugPrint('Error cancelling azkar: $e');
    }
  }

  /// Sends an immediate test notification for preview.
  static Future<void> testNotification() async {
    try {
      await _channel.invokeMethod('testNotification');
    } catch (e) {
      debugPrint('Error sending test azkar notification: $e');
    }
  }

  /// Legacy compatibility helper
  static Future<void> scheduleDailyAzkar(int intervalHours) async {
    final existing = await getSettings();
    if (existing != null && existing['interval'] != null) {
      // Preserve user configured interval and categories
      return;
    }
    await saveSettings({
      'enabled': true,
      'interval': intervalHours * 60,
    });
  }
}
