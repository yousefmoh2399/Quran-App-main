import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_permission_status.dart';
import 'app_permission_type.dart';

abstract class PermissionPlatformAdapter {
  Future<AppPermissionStatus> checkStatus(AppPermissionType type);
  Future<AppPermissionStatus> request(AppPermissionType type);
  Future<bool> openSettings(AppPermissionType type);
  Future<bool> openVendorAutoStart() async => false;
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
          type == AppPermissionType.notification ||
          type == AppPermissionType.camera;
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
          if (!kIsWeb && Platform.isIOS && status.isDenied) {
            final prefs = await SharedPreferences.getInstance();
            final wasRequested = prefs.getBool('$_requestedPrefix${type.name}') ?? false;
            if (wasRequested) {
              return AppPermissionStatus.permanentlyDenied;
            }
          }
          return _mapPermissionHandlerStatus(status, type: type);

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
          if (!kIsWeb && Platform.isIOS && status.isDenied) {
            final prefs = await SharedPreferences.getInstance();
            final wasRequested = prefs.getBool('$_requestedPrefix${type.name}') ?? false;
            if (wasRequested) {
              return AppPermissionStatus.permanentlyDenied;
            }
          }
          return _mapPermissionHandlerStatus(status, type: type);

        case AppPermissionType.camera:
          final status = await Permission.camera.status;
          if (!kIsWeb && Platform.isIOS && status.isDenied) {
            final prefs = await SharedPreferences.getInstance();
            final wasRequested = prefs.getBool('$_requestedPrefix${type.name}') ?? false;
            if (wasRequested) {
              return AppPermissionStatus.permanentlyDenied;
            }
          }
          return _mapPermissionHandlerStatus(status, type: type);

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

  static const String _requestedPrefix = 'permission_already_requested_ios_';

  @override
  Future<AppPermissionStatus> request(AppPermissionType type) async {
    if (!isApplicable(type)) {
      return AppPermissionStatus.notApplicable;
    }

    try {
      if (!kIsWeb && Platform.isIOS) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('$_requestedPrefix${type.name}', true);
      }

      switch (type) {
        case AppPermissionType.location:
          final status = await Permission.location.request();
          if (!kIsWeb && Platform.isIOS && status.isDenied) {
            return AppPermissionStatus.permanentlyDenied;
          }
          return _mapPermissionHandlerStatus(status, type: type);

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
          if (!kIsWeb && Platform.isIOS && status.isDenied) {
            return AppPermissionStatus.permanentlyDenied;
          }
          return _mapPermissionHandlerStatus(status, type: type);

        case AppPermissionType.camera:
          final status = await Permission.camera.request();
          if (!kIsWeb && Platform.isIOS && status.isDenied) {
            return AppPermissionStatus.permanentlyDenied;
          }
          return _mapPermissionHandlerStatus(status, type: type);

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
          case AppPermissionType.camera:
            return await openAppSettings();
        }
      }
      return await openAppSettings();
    } catch (e) {
      debugPrint('⚠️ [PermissionAdapter] error opening settings: $e');
      return await openAppSettings();
    }
  }

  @override
  Future<bool> openVendorAutoStart() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final success =
            await _bridge.invokeMethod<bool>('openVendorAutoStart') ?? true;
        return success;
      }
    } catch (e) {
      debugPrint('⚠️ [PermissionAdapter] error opening vendor auto start: $e');
    }
    return false;
  }

  AppPermissionStatus _mapPermissionHandlerStatus(
    PermissionStatus status, {
    AppPermissionType? type,
  }) {
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
