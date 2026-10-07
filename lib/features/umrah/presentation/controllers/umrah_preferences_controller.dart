import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UmrahPreferencesController extends GetxController {
  static const String _keyElderlyMode = 'umrah_elderly_mode';

  final RxBool isElderlyMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isElderlyMode.value = prefs.getBool(_keyElderlyMode) ?? false;
    } catch (_) {
      isElderlyMode.value = false;
    }
  }

  Future<void> toggleElderlyMode() async {
    isElderlyMode.value = !isElderlyMode.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyElderlyMode, isElderlyMode.value);
    } catch (_) {}

    if (isElderlyMode.value) {
      AppHaptics.cycleCompleted();
    } else {
      AppHaptics.selection();
    }
  }

  /// Scale multiplier for fonts when in Elderly Mode
  double get fontMultiplier => isElderlyMode.value ? 1.35 : 1.0;

  /// Min touch target size in logical pixels
  double get minTouchTarget => isElderlyMode.value ? 68.0 : 48.0;

  /// Enhanced haptic pulse
  void triggerTapFeedback() {
    if (isElderlyMode.value) {
      AppHaptics.itemCompleted();
    } else {
      AppHaptics.tap();
    }
  }

  /// High contrast color adjustments
  Color getTextColor(Color defaultText, bool isDark) {
    if (!isElderlyMode.value) return defaultText;
    return isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  }

  Color getPrimaryColor(Color defaultPrimary, bool isDark) {
    if (!isElderlyMode.value) return defaultPrimary;
    return isDark ? const Color(0xFF52D6B2) : const Color(0xFF094336);
  }
}
