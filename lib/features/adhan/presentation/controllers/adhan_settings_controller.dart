import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';
import 'package:quran_app_android/features/adhan/data/models/adhan_settings_model.dart';
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';

class AdhanSettingsController extends GetxController {
  final Rx<AdhanSettingsModel> settings = const AdhanSettingsModel(
    latitude: 0.0,
    longitude: 0.0,
  ).obs;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      final map = await NativeAdhanBridge.getSettings();
      if (map != null && map['latitude'] != null) {
        settings.value = AdhanSettingsModel.fromMap(map);
      } else {
        // Fetch from AdhanViewModel if available
        if (Get.isRegistered<AdhanViewModel>()) {
          final adhanVM = Get.find<AdhanViewModel>();
          if (adhanVM.latitude != null && adhanVM.longitude != null) {
            settings.value = settings.value.copyWith(
              latitude: adhanVM.latitude!,
              longitude: adhanVM.longitude!,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading adhan settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    isSaving.value = true;
    try {
      final success = await NativeAdhanBridge.saveSettings(settings.value.toMap());
      if (success) {
        if (Get.isRegistered<AdhanViewModel>()) {
          final adhanVM = Get.find<AdhanViewModel>();
          await adhanVM.recalculateWithSettings(settings.value);
        }
        AppSnackbar.show(
          'تم حفظ الإعدادات',
          'تم تحديث مواقيت الصلاة وجدولة الـ 7 أيام القادمة بنجاح',
          backgroundColor: const Color(0xFF0F5C4A),
        );
      }
    } catch (e) {
      debugPrint('Error saving adhan settings: $e');
    } finally {
      isSaving.value = false;
    }
  }

  void updateCalculationMethod(String method) {
    settings.value = settings.value.copyWith(calculationMethod: method);
    saveSettings();
  }

  void updateMadhab(String madhab) {
    settings.value = settings.value.copyWith(madhab: madhab);
    saveSettings();
  }

  void updateHighLatitudeRule(String rule) {
    settings.value = settings.value.copyWith(highLatitudeRule: rule);
    saveSettings();
  }

  void updateOffset(String prayerKey, int deltaMinutes) {
    switch (prayerKey) {
      case 'fajr':
        final newV = (settings.value.fajrOffset + deltaMinutes).clamp(-30, 30);
        settings.value = settings.value.copyWith(fajrOffset: newV);
        break;
      case 'dhuhr':
        final newV = (settings.value.dhuhrOffset + deltaMinutes).clamp(-30, 30);
        settings.value = settings.value.copyWith(dhuhrOffset: newV);
        break;
      case 'asr':
        final newV = (settings.value.asrOffset + deltaMinutes).clamp(-30, 30);
        settings.value = settings.value.copyWith(asrOffset: newV);
        break;
      case 'maghrib':
        final newV = (settings.value.maghribOffset + deltaMinutes).clamp(-30, 30);
        settings.value = settings.value.copyWith(maghribOffset: newV);
        break;
      case 'isha':
        final newV = (settings.value.ishaOffset + deltaMinutes).clamp(-30, 30);
        settings.value = settings.value.copyWith(ishaOffset: newV);
        break;
    }
    saveSettings();
  }

  void togglePrayer(String prayerKey, bool value) {
    switch (prayerKey) {
      case 'fajr':
        settings.value = settings.value.copyWith(fajrEnabled: value);
        break;
      case 'dhuhr':
        settings.value = settings.value.copyWith(dhuhrEnabled: value);
        break;
      case 'asr':
        settings.value = settings.value.copyWith(asrEnabled: value);
        break;
      case 'maghrib':
        settings.value = settings.value.copyWith(maghribEnabled: value);
        break;
      case 'isha':
        settings.value = settings.value.copyWith(ishaEnabled: value);
        break;
    }
    saveSettings();
  }

  void updateNotificationMode(String prayerKey, String mode) {
    switch (prayerKey) {
      case 'fajr':
        settings.value = settings.value.copyWith(fajrMode: mode);
        break;
      case 'dhuhr':
        settings.value = settings.value.copyWith(dhuhrMode: mode);
        break;
      case 'asr':
        settings.value = settings.value.copyWith(asrMode: mode);
        break;
      case 'maghrib':
        settings.value = settings.value.copyWith(maghribMode: mode);
        break;
      case 'isha':
        settings.value = settings.value.copyWith(ishaMode: mode);
        break;
    }
    saveSettings();
  }

  void updateAdhanSound(String sound) {
    settings.value = settings.value.copyWith(adhanSound: sound);
    saveSettings();
  }

  void updatePlayPostAdhanDua(bool value) {
    settings.value = settings.value.copyWith(playPostAdhanDua: value);
    saveSettings();
  }

  void setCity(String cityName, double lat, double lng) {
    settings.value = settings.value.copyWith(
      cityName: cityName,
      latitude: lat,
      longitude: lng,
    );
    saveSettings();
  }

  final isPlayingTestAdhan = false.obs;

  Future<void> testAdhanSound(String prayerName) async {
    if (isPlayingTestAdhan.value) {
      await stopTestAdhan();
      return;
    }

    isPlayingTestAdhan.value = true;
    await NativeAdhanBridge.scheduleTestAdhan(
      delaySeconds: 1,
      prayerName: prayerName,
    );
    AppSnackbar.show(
      'تشغيل تجريبي للأذان',
      'جاري تشغيل صوت الأذان وإطلاق الإشعار لصلاة $prayerName',
      backgroundColor: const Color(0xFF0F5C4A),
      duration: const Duration(seconds: 3),
    );

    // Automatically reset playback state after 29 seconds (duration of adhan_ios.wav)
    Future.delayed(const Duration(seconds: 29), () {
      if (isPlayingTestAdhan.value) {
        isPlayingTestAdhan.value = false;
      }
    });
  }

  Future<void> stopTestAdhan() async {
    isPlayingTestAdhan.value = false;
    await NativeAdhanBridge.stopAdhan();
    AppSnackbar.show(
      'إيقاف الأذان',
      'تم إيقاف صوت الأذان التجريبي',
      backgroundColor: const Color(0xFF0F5C4A),
      duration: const Duration(seconds: 2),
    );
  }
}
