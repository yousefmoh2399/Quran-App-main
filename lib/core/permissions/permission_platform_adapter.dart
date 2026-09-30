import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_permission_status.dart';
import 'app_permission_type.dart';

abstract class PermissionPlatformAdapter {
  Future<AppPermissionStatus> checkStatus(AppPermissionType type);
  Future<AppPermissionStatus> request(AppPermissionType type);
  Future<bool> openSettings(AppPermissionType type);
  bool isApplicable(AppPermissionType type);
}

class LivePermissionPlatformAdapter implements PermissionPlatformAdapter {
  static const MethodChannel _bridge = MethodChannel('permissions_bridge');

  @override
  bool isApplicable(AppPermissionType type) {
    if (kIsWeb) return type == AppPermissionType.location;
    if (Platform.isAndroid) return true;
    if (Platform.isIOS) {
      return type == AppPermissionType.location ||
          type == AppPermissionType.notification;
    }
    return false;
  }

  @override
  Future<AppPermissionStatus> checkStatus(AppPermissionType type) async {
    if (!isApplicable(type)) {
      return AppPermissionStatus.notApplicable;
    }

    try {
      switch (type) {
        case AppPermissionType.location:
          final status = await Permission.location.status;
          return _mapPermissionHandlerStatus(status);

        case AppPermissionType.notification:
          if (!kIsWeb && Platform.isAndroid) {
            final enabled =
                await _bridge.invokeMethod<bool>('areNotificationsEnabled') ??
                    false;
            return enabled
                ? AppPermissionStatus.granted
                : AppPermissionStatus.denied;
          }
          final status = await Permission.notification.status;
          return _mapPermissionHandlerStatus(status);

        case AppPermissionType.exactAlarm:
          if (!kIsWeb && Platform.isAndroid) {
            final canSchedule =
                await _bridge.invokeMethod<bool>('canScheduleExactAlarms') ??
                    true;
            return canSchedule
                ? AppPermissionStatus.granted
                : AppPermissionStatus.denied;
          }
          return AppPermissionStatus.notApplicable;

        case AppPermissionType.batteryOptimization:
          if (!kIsWeb && Platform.isAndroid) {
            final isIgnoring = await _bridge.invokeMethod<bool>(
                    'isIgnoringBatteryOptimizations') ??
                false;
            return isIgnoring
                ? AppPermissionStatus.granted
                : AppPermissionStatus.denied;
          }
          return AppPermissionStatus.notApplicable;

        case AppPermissionType.fullScreenIntent:
          if (!kIsWeb && Platform.isAndroid) {
            final canUse =
                await _bridge.invokeMethod<bool>('canUseFullScreenIntent') ??
                    true;
            return canUse
                ? AppPermissionStatus.granted
                : AppPermissionStatus.denied;
          }
          return AppPermissionStatus.notApplicable;
      }
    } catch (e) {
      debugPrint('⚠️ [PermissionAdapter] error checking status for $type: $e');
      return AppPermissionStatus.denied;
    }
  }

  @override
  Future<AppPermissionStatus> request(AppPermissionType type) async {
    if (!isApplicable(type)) {
      return AppPermissionStatus.notApplicable;
    }

    try {
      switch (type) {
        case AppPermissionType.location:
          final status = await Permission.location.request();
          return _mapPermissionHandlerStatus(status);

        case AppPermissionType.notification:
          if (!kIsWeb && Platform.isAndroid) {
            await _bridge.invokeMethod('requestPostNotifications');
            final enabled =
                await _bridge.invokeMethod<bool>('areNotificationsEnabled') ??
                    false;
            return enabled
                ? AppPermissionStatus.granted
                : AppPermissionStatus.denied;
          }
          final status = await Permission.notification.request();
          return _mapPermissionHandlerStatus(status);

        case AppPermissionType.exactAlarm:
          if (!kIsWeb && Platform.isAndroid) {
            await _bridge.invokeMethod('requestScheduleExactAlarm');
            final canSchedule =
                await _bridge.invokeMethod<bool>('canScheduleExactAlarms') ??
                    true;
            return canSchedule
                ? AppPermissionStatus.granted
                : AppPermissionStatus.denied;
          }
          return AppPermissionStatus.notApplicable;

        case AppPermissionType.batteryOptimization:
          if (!kIsWeb && Platform.isAndroid) {
            await _bridge.invokeMethod('requestIgnoreBatteryOptimizations');
            final isIgnoring = await _bridge.invokeMethod<bool>(
                    'isIgnoringBatteryOptimizations') ??
                false;
            return isIgnoring
                ? AppPermissionStatus.granted
                : AppPermissionStatus.denied;
          }
          return AppPermissionStatus.notApplicable;

        case AppPermissionType.fullScreenIntent:
          if (!kIsWeb && Platform.isAndroid) {
            await _bridge.invokeMethod('openFullScreenIntentSettings');
            final canUse =
                await _bridge.invokeMethod<bool>('canUseFullScreenIntent') ??
                    true;
            return canUse
                ? AppPermissionStatus.granted
                : AppPermissionStatus.denied;
          }
          return AppPermissionStatus.notApplicable;
      }
    } catch (e) {
      debugPrint('⚠️ [PermissionAdapter] error requesting $type: $e');
      return AppPermissionStatus.denied;
    }
  }

  @override
  Future<bool> openSettings(AppPermissionType type) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        switch (type) {
          case AppPermissionType.location:
            await _bridge.invokeMethod('openLocationSettings');
            return true;
          case AppPermissionType.notification:
            await _bridge.invokeMethod('openAppNotificationSettings');
            return true;
          case AppPermissionType.exactAlarm:
            await _bridge.invokeMethod('requestScheduleExactAlarm');
            return true;
          case AppPermissionType.batteryOptimization:
            await _bridge.invokeMethod('openAppBatterySettings');
            return true;
          case AppPermissionType.fullScreenIntent:
            await _bridge.invokeMethod('openFullScreenIntentSettings');
            return true;
        }
      }
      return await openAppSettings();
    } catch (e) {
      debugPrint('⚠️ [PermissionAdapter] error opening settings: $e');
      return await openAppSettings();
    }
  }

  AppPermissionStatus _mapPermissionHandlerStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        return AppPermissionStatus.granted;
      case PermissionStatus.denied:
        return AppPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionStatus.restricted;
    }
  }
}
