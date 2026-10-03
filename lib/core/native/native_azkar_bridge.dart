import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'native_reminders_bridge.dart';

class NativeAzkarBridge {
  static const MethodChannel _channel = MethodChannel('native_azkar_bridge');
  static const String _prefsKey = 'ios_azkar_settings';

  /// Saves settings and reschedules periodic azkar.
  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    if (Platform.isIOS) {
      debugPrint('📱 [iOS NativeAzkarBridge] saveSettings: $settings');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, jsonEncode(settings));

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
        return true;
      } catch (e, st) {
        debugPrint('❌ [iOS NativeAzkarBridge] Error saving settings: $e\n$st');
        return false;
      }
    }

    try {
      final res = await _channel.invokeMethod<bool>('saveSettings', settings);

      // Sync into Unified Reminders Engine on Android
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
      } catch (e, st) {
        debugPrint('⚠️ [NativeAzkarBridge] Sync to Unified Reminders failed: $e\n$st');
      }

      return res ?? true;
    } catch (e, st) {
      debugPrint('❌ [NativeAzkarBridge] saveSettings error: $e\n$st');
      return false;
    }
  }

  /// Retrieves current native azkar settings.
  static Future<Map<String, dynamic>?> getSettings() async {
    if (Platform.isIOS) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final str = prefs.getString(_prefsKey);
        if (str == null || str.isEmpty) return null;
        return Map<String, dynamic>.from(jsonDecode(str) as Map);
      } catch (e, st) {
        debugPrint('❌ [iOS NativeAzkarBridge] Error getting settings: $e\n$st');
        return null;
      }
    }
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('getSettings');
      return res;
    } catch (e, st) {
      debugPrint('❌ [NativeAzkarBridge] getSettings error: $e\n$st');
      return null;
    }
  }

  /// Triggers recalculation and next alarm scheduling.
  static Future<void> reschedule() async {
    if (Platform.isIOS) {
      await NativeRemindersBridge.rescheduleAll();
      return;
    }
    try {
      await _channel.invokeMethod('reschedule');
    } catch (e, st) {
      debugPrint('❌ [NativeAzkarBridge] reschedule error: $e\n$st');
    }
  }

  /// Cancels all scheduled azkar notifications.
  static Future<void> cancelAzkar() async {
    if (Platform.isIOS) {
      await NativeRemindersBridge.toggleReminder('azkar_periodic', false);
      return;
    }
    try {
      await _channel.invokeMethod('cancelAzkar');
    } catch (e, st) {
      debugPrint('❌ [NativeAzkarBridge] cancelAzkar error: $e\n$st');
    }
  }

  /// Sends an immediate test notification for preview.
  static Future<void> testNotification() async {
    if (Platform.isIOS) {
      await NativeRemindersBridge.testTriggerReminder('azkar_periodic');
      return;
    }
    try {
      await _channel.invokeMethod('testNotification');
    } catch (e, st) {
      debugPrint('❌ [NativeAzkarBridge] testNotification error: $e\n$st');
    }
  }

  /// Legacy compatibility helper
  static Future<void> scheduleDailyAzkar(int intervalHours) async {
    final existing = await getSettings();
    if (existing != null && existing['interval'] != null) {
      return;
    }
    await saveSettings({
      'enabled': true,
      'interval': intervalHours * 60,
    });
  }
}
