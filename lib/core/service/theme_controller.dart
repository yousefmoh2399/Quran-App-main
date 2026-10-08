import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';

/// Available visual theme modes across the entire application
enum AppThemeModeType {
  system,
  light,
  dark,
  sepia;

  static AppThemeModeType fromString(String mode) {
    switch (mode) {
      case 'light':
        return AppThemeModeType.light;
      case 'dark':
        return AppThemeModeType.dark;
      case 'sepia':
        return AppThemeModeType.sepia;
      case 'system':
      default:
        return AppThemeModeType.system;
    }
  }

  String toPrefString() => name;
}

/// Manages application theme mode (light, dark, system, sepia) with SharedPreferences persistence.
class ThemeController extends GetxController {
  final SettingsServices _settings = Get.find<SettingsServices>();
  static const String themePrefKey = 'app_theme_mode';

  late final Rx<ThemeMode> _themeMode;
  late final Rx<AppThemeModeType> _appThemeMode;

  ThemeMode get themeMode => _themeMode.value;
  AppThemeModeType get appThemeMode => _appThemeMode.value;
  bool get isSepia => _appThemeMode.value == AppThemeModeType.sepia;

  @override
  void onInit() {
    super.onInit();
    final savedMode = _settings.sharedPref?.getString(themePrefKey) ?? 'system';
    _appThemeMode = AppThemeModeType.fromString(savedMode).obs;
    _themeMode = _toThemeMode(_appThemeMode.value).obs;
  }

  void setAppThemeMode(AppThemeModeType type) {
    _appThemeMode.value = type;
    _settings.sharedPref?.setString(themePrefKey, type.toPrefString());
    _themeMode.value = _toThemeMode(type);

    if (type == AppThemeModeType.sepia) {
      Get.changeTheme(AppTheme.sepia);
      Get.changeThemeMode(ThemeMode.light);
    } else if (type == AppThemeModeType.dark) {
      Get.changeTheme(AppTheme.dark);
      Get.changeThemeMode(ThemeMode.dark);
    } else if (type == AppThemeModeType.light) {
      Get.changeTheme(AppTheme.light);
      Get.changeThemeMode(ThemeMode.light);
    } else {
      Get.changeTheme(AppTheme.light);
      Get.changeThemeMode(ThemeMode.system);
    }
    update();
  }

  void setThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        setAppThemeMode(AppThemeModeType.light);
        break;
      case ThemeMode.dark:
        setAppThemeMode(AppThemeModeType.dark);
        break;
      case ThemeMode.system:
        setAppThemeMode(AppThemeModeType.system);
        break;
    }
  }

  ThemeData get activeTheme {
    if (isSepia) return AppTheme.sepia;
    return AppTheme.light;
  }

  static ThemeMode _toThemeMode(AppThemeModeType type) {
    switch (type) {
      case AppThemeModeType.light:
      case AppThemeModeType.sepia:
        return ThemeMode.light;
      case AppThemeModeType.dark:
        return ThemeMode.dark;
      case AppThemeModeType.system:
        return ThemeMode.system;
    }
  }
}
