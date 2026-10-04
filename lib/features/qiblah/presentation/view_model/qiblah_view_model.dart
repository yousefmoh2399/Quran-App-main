import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/permissions/app_permission_type.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../adhan/presentation/view_model/adhan_view_model.dart';

class QiblahViewModel extends GetxController {
  final RxBool isDone = false.obs;
  final RxDouble userLatitude = 0.0.obs;
  final RxDouble userLongitude = 0.0.obs;
  final RxDouble qiblaDirection = 0.0.obs;
  final RxBool hasLocation = false.obs;
  final RxBool isRefreshingLocation = false.obs;
  final RxString locationSource = ''.obs;

  final RxBool isLocationServiceEnabled = true.obs;
  final RxBool isPermanentlyDenied = false.obs;

  @override
  void onInit() {
    super.onInit();
    initLocationAndQibla();
  }

  /// Instantly checks location state without silent Cairo fallback
  Future<void> initLocationAndQibla() async {
    // 1. Check known saved or Adhan coordinates first
    final hasKnown = await _resolveKnownLocation();
    if (hasKnown) {
      hasLocation.value = true;
      isDone.value = true;
      update();
    }

    // 2. Refresh actual GPS / permission state
    await refreshLocationState();
  }

  Future<void> refreshLocationState() async {
    // Check if device Location Services are turned on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    isLocationServiceEnabled.value = serviceEnabled;
    if (!serviceEnabled) {
      update();
      return;
    }

    // Check permission status
    final service = PermissionService.instance;
    final currentStatus = service.getStatus(AppPermissionType.location);

    if (currentStatus.isGranted) {
      isDone.value = true;
      isPermanentlyDenied.value = false;
      await _fetchGpsLocation();
    } else if (currentStatus.isPermanentlyDenied) {
      isDone.value = false;
      isPermanentlyDenied.value = true;
    } else {
      isDone.value = false;
      isPermanentlyDenied.value = false;
      // Auto-prompt contextually if user just opened
      await requestLocationPermission();
    }
    update();
  }

  Future<bool> _resolveKnownLocation() async {
    // Check in-memory AdhanViewModel if available and non-zero
    if (Get.isRegistered<AdhanViewModel>()) {
      final adhanVM = Get.find<AdhanViewModel>();
      if (adhanVM.latitude != null &&
          adhanVM.longitude != null &&
          adhanVM.latitude != 0.0 &&
          adhanVM.longitude != 0.0) {
        _setCoordinates(adhanVM.latitude!, adhanVM.longitude!, adhanVM.cityName.isNotEmpty ? adhanVM.cityName : 'أوقات الصلاة');
        return true;
      }
    }

    // Check SharedPreferences for previously saved user location
    final prefs = await SharedPreferences.getInstance();
    final savedLat = prefs.getDouble('lat');
    final savedLng = prefs.getDouble('lng');
    final savedCity = prefs.getString('cityName') ?? '';
    if (savedLat != null && savedLng != null && savedLat != 0.0 && savedLng != 0.0) {
      _setCoordinates(savedLat, savedLng, savedCity.isNotEmpty ? savedCity : 'الموقع المحفوظ');
      return true;
    }

    return false;
  }

  Future<void> _fetchGpsLocation() async {
    try {
      isRefreshingLocation.value = true;
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && !hasLocation.value) {
        _setCoordinates(lastPos.latitude, lastPos.longitude, 'آخر موقع معروف');
      }

      Position? freshPos;
      try {
        freshPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {}

      if (freshPos != null) {
        _setCoordinates(freshPos.latitude, freshPos.longitude, 'GPS مباشر');
      }
    } catch (_) {
    } finally {
      isRefreshingLocation.value = false;
      update();
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

  void setManualCity(String name, double lat, double lng) {
    _setCoordinates(lat, lng, name);
    isDone.value = true;
    update();
  }

  Future<void> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    isLocationServiceEnabled.value = serviceEnabled;
    if (!serviceEnabled) {
      update();
      return;
    }

    final service = PermissionService.instance;
    final currentStatus = service.getStatus(AppPermissionType.location);
    if (currentStatus.isGranted) {
      isDone.value = true;
      isPermanentlyDenied.value = false;
      await _fetchGpsLocation();
      update();
      return;
    }

    final res = await service.requestPermission(AppPermissionType.location);
    isDone.value = res.isGranted;
    isPermanentlyDenied.value = res.isPermanentlyDenied;
    if (res.isGranted) {
      await _fetchGpsLocation();
    }
    update();
  }
}
