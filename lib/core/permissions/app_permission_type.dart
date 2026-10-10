import 'package:flutter/material.dart';

enum AppPermissionType {
  location,
  notification,
  exactAlarm,
  batteryOptimization,
  fullScreenIntent,
  camera;

  String get title {
    switch (this) {
      case AppPermissionType.location:
        return 'الموقع الجغرافي';
      case AppPermissionType.notification:
        return 'الإشعارات والتنبيهات';
      case AppPermissionType.exactAlarm:
        return 'المنبهات الدقيقة (Exact Alarms)';
      case AppPermissionType.batteryOptimization:
        return 'استثناء توفير البطارية';
      case AppPermissionType.fullScreenIntent:
        return 'تنبيه ملء الشاشة للأذان';
      case AppPermissionType.camera:
        return 'الكاميرا';
    }
  }

  String get description {
    switch (this) {
      case AppPermissionType.location:
        return 'مطلوب لتحديد اتجاه القِبلة وحساب مواقيت الصلاة بدقة لموقعك الحالي.';
      case AppPermissionType.notification:
        return 'لتصلك تنبيهات دخول وقت الصلاة وتذكيرات الأذكار اليومية في موعدها.';
      case AppPermissionType.exactAlarm:
        return 'لضمان انطلاق صوت الأذان في التوقيت المضبوط بالدقيقة حتى مع وضع السكون.';
      case AppPermissionType.batteryOptimization:
        return 'للسماح للأذان بالعمل دون أن يُوقفه نظام توفير الطاقة عند قفل الشاشة.';
      case AppPermissionType.fullScreenIntent:
        return 'لعرض شاشة الأذان مباشرة فوق شاشة القفل عند دخول وقت الصلاة (Android 14+).';
      case AppPermissionType.camera:
        return 'مطلوبة لعرض اتجاه القبلة بالواقع المعزز ومسح رموز QR للختمات العائلية.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppPermissionType.location:
        return Icons.location_on_outlined;
      case AppPermissionType.notification:
        return Icons.notifications_active_outlined;
      case AppPermissionType.exactAlarm:
        return Icons.alarm_on_outlined;
      case AppPermissionType.batteryOptimization:
        return Icons.battery_charging_full_outlined;
      case AppPermissionType.fullScreenIntent:
        return Icons.fullscreen_outlined;
      case AppPermissionType.camera:
        return Icons.camera_alt_outlined;
    }
  }

  /// Whether this permission is primarily relevant on Android devices
  bool get isAndroidSpecific {
    switch (this) {
      case AppPermissionType.exactAlarm:
      case AppPermissionType.batteryOptimization:
      case AppPermissionType.fullScreenIntent:
        return true;
      case AppPermissionType.location:
      case AppPermissionType.notification:
      case AppPermissionType.camera:
        return false;
    }
  }
}
