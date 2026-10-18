import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';

class AdhanReliabilityStatus {
  final bool isBatteryIgnored;
  final bool canExactAlarm;
  final bool areNotificationsEnabled;

  const AdhanReliabilityStatus({
    required this.isBatteryIgnored,
    required this.canExactAlarm,
    required this.areNotificationsEnabled,
  });

  bool get isFullyConfigured => isBatteryIgnored && canExactAlarm && areNotificationsEnabled;
}

class AdhanBatteryPermissionService {
  static bool hasDismissedNoticeInSession = false;

  /// Evaluates background execution reliability on Android (Battery Whitelist + Exact Alarms + Notifications)
  static Future<AdhanReliabilityStatus> checkStatus() async {
    if (!Platform.isAndroid) {
      return const AdhanReliabilityStatus(
        isBatteryIgnored: true,
        canExactAlarm: true,
        areNotificationsEnabled: true,
      );
    }

    final isBatteryIgnored = await NativeAdhanBridge.isIgnoringBatteryOptimizations();
    final canExactAlarm = await NativeAdhanBridge.canScheduleExactAlarms();
    final notificationsStatus = await Permission.notification.status;
    final areNotificationsEnabled = notificationsStatus.isGranted || !notificationsStatus.isDenied;

    return AdhanReliabilityStatus(
      isBatteryIgnored: isBatteryIgnored,
      canExactAlarm: canExactAlarm,
      areNotificationsEnabled: areNotificationsEnabled,
    );
  }

  /// Triggers the optimal settings flow for Android background Adhan execution
  static Future<void> requestOptimalSettings() async {
    if (!Platform.isAndroid) return;

    final status = await checkStatus();

    // 1. If battery optimization is active (not ignored), request exemption
    if (!status.isBatteryIgnored) {
      final success = await NativeAdhanBridge.requestIgnoreBatteryOptimizations();
      if (!success) {
        await openAppSettings();
      }
      return;
    }

    // 2. If exact alarm permission is missing on Android 12+, open exact alarm settings
    if (!status.canExactAlarm) {
      await NativeAdhanBridge.openExactAlarmSettings();
      return;
    }

    // 3. If notifications are disabled, open app notification settings
    if (!status.areNotificationsEnabled) {
      await openAppSettings();
    }
  }
}
