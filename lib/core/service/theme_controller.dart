import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';

/// Manages application theme mode (light, dark, system) with SharedPreferences persistence.
class ThemeController extends GetxController {
  final SettingsServices _settings = Get.find<SettingsServices>();
  static const String themePrefKey = 'app_theme_mode';

  late final Rx<ThemeMode> _themeMode;
  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    final savedMode = _settings.sharedPref?.getString(themePrefKey) ?? 'system';
    _themeMode = _parseThemeMode(savedMode).obs;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
    _settings.sharedPref?.setString(themePrefKey, _themeModeToString(mode));
    Get.changeThemeMode(mode);
    update();
  }

  static ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
