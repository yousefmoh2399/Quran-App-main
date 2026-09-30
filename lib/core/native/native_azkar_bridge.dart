import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeAzkarBridge {
  static const MethodChannel _channel = MethodChannel('native_azkar_bridge');

  /// Saves settings and reschedules the chained alarm.
  static Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final res = await _channel.invokeMethod<bool>('saveSettings', settings);
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
    await saveSettings({
      'enabled': true,
      'interval': intervalHours * 60,
    });
  }
}
