import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/permissions/app_permission_type.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../core/service/settings/SettingsServices.dart';

class SettingsViewModel extends GetxController {
  final SettingsServices settingsServices = Get.find<SettingsServices>();

  TimeOfDay? timeOfDay;

  void toggleSwitch(bool value) {
    settingsServices.sharedPref!.setBool('enable', value);
    update();
  }

  void toggleSwitchStopNoti(bool value) {
    settingsServices.sharedPref!.setBool('stop_noti', value);
    update();
  }

  Future<bool> checkNotificationPermissions({BuildContext? context}) async {
    final service = PermissionService.instance;
    final currentStatus = service.getStatus(AppPermissionType.notification);
    if (currentStatus.isGranted) return true;

    if (context != null) {
      return await service.requestWithRationale(
        context,
        AppPermissionType.notification,
      );
    } else {
      final res = await service.requestPermission(AppPermissionType.notification);
      return res.isGranted;
    }
  }
}
