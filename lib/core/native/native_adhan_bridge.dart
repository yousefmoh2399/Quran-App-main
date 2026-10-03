import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeAdhanBridge {
  static const _channel = MethodChannel('native_adhan_bridge');

  /// Saves native settings (location, calculation method, madhab, offsets, audio, toggles)
  /// and automatically triggers 7-day rolling window calculation & scheduling in Kotlin.
  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final result = await _channel.invokeMethod('saveSettings', settings);
      debugPrint('NativeAdhanBridge.saveSettings result: $result');
      return true;
    } catch (e) {
      debugPrint('NativeAdhanBridge.saveSettings error: $e');
      return false;
    }
  }

  /// Retrieves the current settings stored in Native SharedPreferences.
  static Future<Map<String, dynamic>?> getSettings() async {
    try {
      final res = await _channel.invokeMethod<Map>('getSettings');
      return res != null ? Map<String, dynamic>.from(res) : null;
    } catch (e) {
      debugPrint('NativeAdhanBridge.getSettings error: $e');
      return null;
    }
  }

  /// Retrieves the list of scheduled prayers in the 7-day rolling window for debug/verification.
  static Future<List<Map<String, dynamic>>> getUpcomingPrayers() async {
    try {
      final res = await _channel.invokeMethod<List>('getUpcomingPrayers');
      if (res == null) return [];
      return res.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      debugPrint('NativeAdhanBridge.getUpcomingPrayers error: $e');
      return [];
    }
  }

  /// Triggers a test Adhan alert after [delaySeconds] (default 10s).
  static Future<bool> scheduleTestAdhan({
    int delaySeconds = 10,
    String prayerName = 'الفجر',
  }) async {
    try {
      await _channel.invokeMethod('scheduleTestAdhan', {
        'delaySeconds': delaySeconds,
        'prayerName': prayerName,
      });
      debugPrint('Scheduled test Adhan in $delaySeconds seconds ($prayerName)');
      return true;
    } catch (e) {
      debugPrint('NativeAdhanBridge.scheduleTestAdhan error: $e');
      return false;
    }
  }

  /// Forces recalculation and rescheduling of the 7-day rolling window.
  static Future<int> recalculateAndSchedule() async {
    try {
      final count = await _channel.invokeMethod<int>('recalculateAndSchedule');
      return count ?? 0;
    } catch (e) {
      debugPrint('NativeAdhanBridge.recalculateAndSchedule error: $e');
      return 0;
    }
  }

  /// Checks if Native side has a valid saved location.
  static Future<bool> hasLocation() async {
    try {
      final has = await _channel.invokeMethod<bool>('hasLocation');
      return has ?? false;
    } catch (e) {
      debugPrint('NativeAdhanBridge.hasLocation error: $e');
      return false;
    }
  }

  // Backward compatibility
  static Future<bool> schedulePrayerTimes(Map<String, int> prayerTimes) async {
    try {
      await _channel.invokeMethod('schedulePrayerTimes', prayerTimes);
      return true;
    } catch (e) {
      debugPrint('schedulePrayerTimes error: $e');
      return false;
    }
  }

  static Future<void> saveLocationToNative(double lat, double lng) async {
    try {
      await _channel.invokeMethod('saveLocation', {'lat': lat, 'lng': lng});
    } catch (e) {
      debugPrint('saveLocation error: $e');
    }
  }

  static Future<void> scheduleDailyReset() async {
    try {
      await _channel.invokeMethod('scheduleDailyReset');
    } catch (e) {
      debugPrint('scheduleDailyReset error: $e');
    }
  }

  static Future<void> scheduleTestReset() async {
    try {
      await _channel.invokeMethod('scheduleTestAdhan', {'delaySeconds': 10, 'prayerName': 'تجربة'});
    } catch (e) {
      debugPrint('scheduleTestReset error: $e');
    }
  }

  /// Retrieves any prayer marked as completed via the native lockscreen or notification.
  static Future<List<Map<String, dynamic>>> getPendingPrayedLogs() async {
    try {
      final res = await _channel.invokeMethod<List>('getPendingPrayedLogs');
      if (res == null) return [];
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('getPendingPrayedLogs error: $e');
      return [];
    }
  }

  /// Clears synced prayer log entries from native SharedPreferences.
  static Future<void> clearPendingPrayedLogs(List<String> keys) async {
    try {
      await _channel.invokeMethod('clearPendingPrayedLogs', keys);
    } catch (e) {
      debugPrint('clearPendingPrayedLogs error: $e');
    }
  }

  /// Manually marks a prayer as completed on the native side.
  static Future<bool> markPrayerAsPrayed(String prayerKey, {String status = 'on_time'}) async {
    try {
      await _channel.invokeMethod('markPrayerAsPrayed', {
        'prayerKey': prayerKey,
        'status': status,
      });
      return true;
    } catch (e) {
      debugPrint('markPrayerAsPrayed error: $e');
      return false;
    }
  }
}
