import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';
import 'package:quran_app_android/core/service/database/database_helper.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';
import 'package:quran_app_android/features/adhan/data/models/adhan_settings_model.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_screen_model_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdhanViewModel extends GetxController {
  double? latitude, longitude;
  String cityName = '';
  RxBool isLoading = false.obs;
  RxBool isLocationRequired = false.obs;

  SettingsServices settingsServices = Get.find<SettingsServices>();
  LocalStorageAdhanData localData = Get.find<LocalStorageAdhanData>();
  QuranScreenViewModel quranScreenViewModel = Get.find<QuranScreenViewModel>();

  PrayerTimes? prayerTimes;
  AdhanSettingsModel? currentSettings;

  bool get isDefaultLocation => isLocationRequired.value;

  Future<void> getCurrentLocation() async {
    isLoading.value = true;
    update();
    await checkAndRefreshLocation();
    isLoading.value = false;
    update();
  }

  @override
  void onInit() async {
    super.onInit();
    try {
      await initializeAdhan();
    } catch (e) {
      debugPrint('AdhanViewModel init error: $e');
      isLocationRequired.value = true;
    }
  }

  /// Initializes Adhan system: loads native settings or requests GPS location.
  Future<void> initializeAdhan() async {
    isLoading.value = true;
    update();

    final nativeMap = await NativeAdhanBridge.getSettings();
    if (nativeMap != null) {
      currentSettings = AdhanSettingsModel.fromMap(nativeMap);
      if (currentSettings!.latitude != 0.0 && currentSettings!.longitude != 0.0) {
        latitude = currentSettings!.latitude;
        longitude = currentSettings!.longitude;
        cityName = currentSettings!.cityName;
        isLocationRequired.value = false;
        await recalculatePrayerTimes();
      }
    }

    // Try refreshing GPS position and check if user moved > 50 km
    await checkAndRefreshLocation();

    isLoading.value = false;
    update();
  }

  /// Checks device location and if user moved > 50km, recalculates prayer times.
  Future<void> checkAndRefreshLocation() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final req = await Permission.location.request();
      if (!req.isGranted) {
        if (latitude == null || longitude == null) {
          isLocationRequired.value = true;
        }
        return;
      }
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (latitude == null || longitude == null) {
        isLocationRequired.value = true;
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      final prevLat = latitude;
      final prevLng = longitude;

      latitude = position.latitude;
      longitude = position.longitude;
      isLocationRequired.value = false;

      // Check distance moved (> 50 km = 50,000 meters)
      if (prevLat != null && prevLng != null && prevLat != 0.0 && prevLng != 0.0) {
        final distance = Geolocator.distanceBetween(prevLat, prevLng, position.latitude, position.longitude);
        if (distance > 50000) {
          debugPrint('User moved > 50km ($distance m). Updating location and rolling window!');
          AppSnackbar.show(
            'تحديث الموقع',
            'تم رصد انتقال جغرافي جديد وتحديث مواقيت الصلاة تلقائياً 🕌',
            backgroundColor: const Color(0xFF0F5C4A),
            duration: const Duration(seconds: 3),
          );
        }
      }

      await saveLocation(latitude!, longitude!, cityName);
    } catch (e) {
      debugPrint('Failed to get updated location: $e');
      if (latitude == null || longitude == null) {
        // Try last known position
        try {
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) {
            latitude = last.latitude;
            longitude = last.longitude;
            isLocationRequired.value = false;
            await saveLocation(latitude!, longitude!, cityName);
          } else {
            isLocationRequired.value = true;
          }
        } catch (_) {
          isLocationRequired.value = true;
        }
      }
    }
  }

  /// Sets location manually (e.g. from user city picker) without silent fallback.
  Future<void> setManualCity(String name, double lat, double lng) async {
    cityName = name;
    latitude = lat;
    longitude = lng;
    isLocationRequired.value = false;
    await saveLocation(lat, lng, name);
    update();
  }

  Future<void> saveLocation(double lat, double lng, String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lat', lat);
    await prefs.setDouble('lng', lng);
    await prefs.setString('cityName', city);

    final updated = (currentSettings ?? const AdhanSettingsModel(latitude: 0, longitude: 0)).copyWith(
      latitude: lat,
      longitude: lng,
      cityName: city,
    );
    currentSettings = updated;

    await NativeAdhanBridge.saveSettings(updated.toMap());
    await recalculatePrayerTimes();
  }

  Future<void> recalculateWithSettings(AdhanSettingsModel settings) async {
    currentSettings = settings;
    latitude = settings.latitude;
    longitude = settings.longitude;
    cityName = settings.cityName;
    await recalculatePrayerTimes();
  }

  Future<void> recalculatePrayerTimes() async {
    if (latitude == null || longitude == null || (latitude == 0.0 && longitude == 0.0)) {
      isLocationRequired.value = true;
      return;
    }

    final coords = Coordinates(latitude!, longitude!);
    final settings = currentSettings ?? const AdhanSettingsModel(latitude: 0, longitude: 0);

    CalculationParameters params;
    switch (settings.calculationMethod.toUpperCase()) {
      case 'UMM_AL_QURA':
      case 'UMMALQURA':
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'MUSLIM_WORLD_LEAGUE':
      case 'MWL':
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'KARACHI':
        params = CalculationMethod.karachi.getParameters();
        break;
      case 'NORTH_AMERICA':
      case 'ISNA':
        params = CalculationMethod.north_america.getParameters();
        break;
      case 'DUBAI':
        params = CalculationMethod.dubai.getParameters();
        break;
      case 'KUWAIT':
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 'QATAR':
        params = CalculationMethod.qatar.getParameters();
        break;
      case 'SINGAPORE':
        params = CalculationMethod.singapore.getParameters();
        break;
      case 'MOON_SIGHTING_COMMITTEE':
        params = CalculationMethod.moon_sighting_committee.getParameters();
        break;
      case 'EGYPTIAN':
      default:
        params = CalculationMethod.egyptian.getParameters();
        break;
    }

    params.madhab = settings.madhab.toUpperCase() == 'HANAFI' ? Madhab.hanafi : Madhab.shafi;

    // Apply manual minute adjustments
    params.adjustments.fajr = settings.fajrOffset;
    params.adjustments.sunrise = settings.sunriseOffset;
    params.adjustments.dhuhr = settings.dhuhrOffset;
    params.adjustments.asr = settings.asrOffset;
    params.adjustments.maghrib = settings.maghribOffset;
    params.adjustments.isha = settings.ishaOffset;

    prayerTimes = PrayerTimes.today(coords, params);
    update();
  }
}
