import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../permissions/app_permission_type.dart';
import '../permissions/permission_service.dart';

/// Legacy adapter for backward compatibility.
/// All new code should use [PermissionService] directly.
class PermissionsController extends GetxController {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Contextual rationale or status check via [PermissionService]
  static Future<void> showPermissionsDialog({BuildContext? context}) async {
    final ctx = context ?? Get.context;
    if (ctx == null) return;

    // Show contextual rationale for ungranted notifications if not in cooldown
    await PermissionService.instance.requestWithRationale(
      ctx,
      AppPermissionType.notification,
    );
  }

  /// Ensure all essential background permissions for Adhan
  static Future<void> ensureAll({BuildContext? context}) async {
    final service = PermissionService.instance;
    await service.requestPermission(AppPermissionType.notification);
    await service.requestPermission(AppPermissionType.exactAlarm);
    await service.requestPermission(AppPermissionType.batteryOptimization);
  }

  /// Check if essential permissions are satisfied
  static Future<bool> checkAllPermissions() async {
    final service = PermissionService.instance;
    final notif = service.isGranted(AppPermissionType.notification);
    final alarm = service.isGranted(AppPermissionType.exactAlarm);
    return notif && alarm;
  }
}
