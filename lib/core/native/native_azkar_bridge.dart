import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeAzkarBridge {
  static const MethodChannel _channel = MethodChannel('native_azkar_bridge');

  /// 📿 جدولة الأذكار من 10 صباحًا إلى 10 مساءً
  static Future<void> scheduleDailyAzkar(int intervalHours) async {
    try {
      await _channel.invokeMethod('scheduleAzkar', {'interval': intervalHours});
      debugPrint("✅ Azkar scheduled every $intervalHours hour(s)");
    } catch (e, st) {
      debugPrint("❌ Error sending azkar schedule: $e\n$st");
    }
  }

  /// ❌ إلغاء الجدولة
  static Future<void> cancelAzkar() async {
    try {
      await _channel.invokeMethod('cancelAzkar');
      debugPrint("🛑 Azkar schedule cancelled");
    } catch (e, st) {
      debugPrint("❌ Error cancelling azkar: $e\n$st");
    }
  }
}
