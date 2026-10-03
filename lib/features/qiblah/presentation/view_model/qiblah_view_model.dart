import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/permissions/app_permission_type.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../adhan/presentation/view_model/adhan_view_model.dart';

class QiblahViewModel extends GetxController {
  final RxBool isDone = false.obs;
  final RxDouble userLatitude = 30.0444.obs;
  final RxDouble userLongitude = 31.2357.obs;
  final RxDouble qiblaDirection = 136.0.obs;
  final RxBool hasLocation = true.obs;
  final RxBool isRefreshingLocation = false.obs;
  final RxString locationSource = 'افتراضي'.obs;

  @override
  void onInit() {
    super.onInit();
    initLocationAndQibla();
  }

  /// Instantly resolves the best available location and initiates non-blocking GPS refinement.
  Future<void> initLocationAndQibla({BuildContext? context}) async {
    // 1. Instant Synchronous/Fast In-Memory Resolution (< 5ms)
    _resolveFastLocation();

    // 2. Check & Request permission gracefully
    await requestLocationPermission(context: context);

    // 3. Fast non-blocking Cached & Background GPS Refinement
    _refineLocationInBackground();
  }

  void _resolveFastLocation() {
    // Check in-memory AdhanViewModel if available
    if (Get.isRegistered<AdhanViewModel>()) {
      final adhanVM = Get.find<AdhanViewModel>();
      if (adhanVM.latitude != null &&
          adhanVM.longitude != null &&
          adhanVM.latitude != 0.0) {
        _setCoordinates(adhanVM.latitude!, adhanVM.longitude!, 'أوقات الصلاة');
        return;
      }
    }

    // Default Cairo fallback coordinates
    _setCoordinates(30.0444, 31.2357, 'افتراضي');
  }

  Future<void> _refineLocationInBackground() async {
    try {
      // Step A: Check SharedPreferences (< 10ms)
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble('lat');
      final savedLng = prefs.getDouble('lng');
      if (savedLat != null && savedLng != null && savedLat != 0.0) {
        _setCoordinates(savedLat, savedLng, 'الموقع المحفوظ');
      }

      // Step B: Check System Last Known Location (~10ms, no GPS satellite spin-up needed)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        _setCoordinates(lastPos.latitude, lastPos.longitude, 'آخر موقع معروف');
      }

      // Step C: High-speed low-accuracy network/cell tower fix in background (max 3s)
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled && isDone.value) {
        isRefreshingLocation.value = true;
        final freshPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
        _setCoordinates(freshPos.latitude, freshPos.longitude, 'GPS مباشر');
      }
    } catch (_) {
      // Silently keep previous valid coordinates without disrupting user
    } finally {
      isRefreshingLocation.value = false;
    }
  }

  void _setCoordinates(double lat, double lng, String source) {
    userLatitude.value = lat;
    userLongitude.value = lng;
    locationSource.value = source;
    final coords = Coordinates(lat, lng);
    qiblaDirection.value = Qibla(coords).direction;
    hasLocation.value = true;
    update();
  }

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
