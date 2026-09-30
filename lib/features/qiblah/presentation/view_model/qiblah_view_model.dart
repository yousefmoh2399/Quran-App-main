import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/permissions/app_permission_type.dart';
import '../../../../core/permissions/permission_service.dart';

class QiblahViewModel extends GetxController {
  RxBool isDone = false.obs;

  Future<void> requestLocationPermission({BuildContext? context}) async {
    final service = PermissionService.instance;
    final currentStatus = service.getStatus(AppPermissionType.location);
    if (currentStatus.isGranted) {
      isDone.value = true;
      update();
      return;
    }

    if (context != null) {
      final granted = await service.requestWithRationale(
        context,
        AppPermissionType.location,
      );
      isDone.value = granted;
    } else {
      final res = await service.requestPermission(AppPermissionType.location);
      if (res.isPermanentlyDenied) {
        await service.openSettings(AppPermissionType.location);
      }
      isDone.value = res.isGranted;
    }
    update();
  }
}
