import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';

class GuideStep {
  final int number;
  final String title;
  final String subtitle;
  final String? badgeText;
  final IconData icon;

  const GuideStep({
    required this.number,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.icon,
  });
}

enum DeviceBrandKey {
  samsung,
  xiaomi,
  oppo,
  huawei,
  vivo,
  other,
}

class BrandGuideInfo {
  final DeviceBrandKey brandKey;
  final String displayName;
  final String rawManufacturer;
  final String model;
  final String summaryTip;
  final List<GuideStep> steps;
  final bool hasAutoStart;

  const BrandGuideInfo({
    required this.brandKey,
    required this.displayName,
    required this.rawManufacturer,
    required this.model,
    required this.summaryTip,
    required this.steps,
    required this.hasAutoStart,
  });
}

class DeviceBrandGuideService {
  static BrandGuideInfo? _cachedInfo;

  /// Detects the user device hardware manufacturer and builds custom step-by-step instructions
  static Future<BrandGuideInfo> getBrandInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;

    if (!Platform.isAndroid) {
      _cachedInfo = const BrandGuideInfo(
        brandKey: DeviceBrandKey.other,
        displayName: 'أجهزة Apple iOS',
        rawManufacturer: 'Apple',
        model: 'iPhone / iPad',
        summaryTip: 'نظام iOS يدير دقة المواعيد تلقائياً عند منح إذن الإشعارات',
        steps: [
          GuideStep(
            number: 1,
            title: 'تأكد من تفعيل إذن الإشعارات',
            subtitle: 'يصلك صوت الأذان عبر إشعارات النظام المعتمدة',
            badgeText: 'الإشعارات',
            icon: Icons.notifications_active_rounded,
          ),
        ],
        hasAutoStart: false,
      );
      return _cachedInfo!;
    }

    final devInfo = await NativeAdhanBridge.getDeviceInfo();
    final manufacturer = (devInfo?['manufacturer'] ?? '').toString().toLowerCase();
    final brand = (devInfo?['brand'] ?? '').toString().toLowerCase();
    final model = (devInfo?['model'] ?? '').toString();

    final brandKey = _classifyBrand(manufacturer, brand);
    _cachedInfo = _buildInfoForBrand(brandKey, manufacturer, model);
    return _cachedInfo!;
  }

  static DeviceBrandKey _classifyBrand(String manufacturer, String brand) {
    final combined = '$manufacturer $brand';
    if (combined.contains('samsung')) return DeviceBrandKey.samsung;
    if (combined.contains('xiaomi') || combined.contains('redmi') || combined.contains('poco')) {
      return DeviceBrandKey.xiaomi;
    }
    if (combined.contains('oppo') || combined.contains('realme') || combined.contains('oneplus')) {
      return DeviceBrandKey.oppo;
    }
    if (combined.contains('huawei') || combined.contains('honor')) {
      return DeviceBrandKey.huawei;
    }
    if (combined.contains('vivo') || combined.contains('iqoo')) {
      return DeviceBrandKey.vivo;
    }
    return DeviceBrandKey.other;
  }

  static BrandGuideInfo _buildInfoForBrand(DeviceBrandKey key, String rawMfr, String model) {
    switch (key) {
      case DeviceBrandKey.samsung:
        return BrandGuideInfo(
          brandKey: key,
          displayName: 'هواتف سامسونج (Samsung Galaxy)',
          rawManufacturer: rawMfr,
          model: model.isNotEmpty ? model : 'Galaxy',
          summaryTip: 'اختر (غير مقيّد / Unrestricted) ليعمل الأذان وشاشتك مقفلة',
          steps: const [
            GuideStep(
              number: 1,
              title: 'اضغط على خيار «البطارية» (Battery)',
              subtitle: 'ستجده في صفحة معلومات تطبيق تقرّب التي ستفتح لك الآن',
              badgeText: 'البطارية',
              icon: Icons.battery_charging_full_rounded,
            ),
            GuideStep(
              number: 2,
              title: 'اختر «غير مقيّد» (Unrestricted)',
              subtitle: 'بدلاً من خيار "مُحسَّن"، لضمان انطلاق صوت الأذان في التوقيت بالثانية',
              badgeText: 'غير مقيّد',
              icon: Icons.check_circle_outline_rounded,
            ),
            GuideStep(
              number: 3,
              title: 'تأكد من إيقاف "وضع التطبيق في السكون"',
              subtitle: 'إذا كان الخيار متاحاً، أوقف تفعيله ليبقى التطبيق مستيقظاً وقت الصلاة',
              icon: Icons.bedtime_off_outlined,
            ),
          ],
          hasAutoStart: false,
        );

      case DeviceBrandKey.xiaomi:
        return BrandGuideInfo(
          brandKey: key,
          displayName: 'هواتف شاومي وريدمي (Xiaomi / Redmi / POCO)',
          rawManufacturer: rawMfr,
          model: model.isNotEmpty ? model : 'Redmi / POCO',
          summaryTip: 'فعّل (التشغيل التلقائي) واجعل موفر البطارية (بلا قيود)',
          steps: const [
            GuideStep(
              number: 1,
              title: 'تفعيل خيار «التشغيل التلقائي» (Autostart)',
              subtitle: 'اسمح لتطبيق تقرّب ببدء التشغيل الذاتي لضمان تنبيهك لكل أذان',
              badgeText: 'التشغيل التلقائي',
              icon: Icons.play_circle_outline_rounded,
            ),
            GuideStep(
              number: 2,
              title: 'اضغط على «موفر البطارية» (Battery Saver)',
              subtitle: 'انزل لأسفل في شاشة إعدادات التطبيق واضغط على موفر البطارية',
              badgeText: 'موفر البطارية',
              icon: Icons.battery_saver_rounded,
            ),
            GuideStep(
              number: 3,
              title: 'اختر «لا توجد قيود» (No restrictions)',
              subtitle: 'بدلاً من خيار توفير البطارية الموصى به من النظام',
              badgeText: 'لا توجد قيود',
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
          hasAutoStart: true,
        );

      case DeviceBrandKey.oppo:
        return BrandGuideInfo(
          brandKey: key,
          displayName: 'هواتف أوبو وريلمي (Oppo / Realme / OnePlus)',
          rawManufacturer: rawMfr,
          model: model.isNotEmpty ? model : 'Realme / Oppo',
          summaryTip: 'السماح بالنشاط في الخلفية وبدء التشغيل التلقائي',
          steps: const [
            GuideStep(
              number: 1,
              title: 'اضغط على «استخدام البطارية» (Battery usage)',
              subtitle: 'ستجده في قائمة معلومات التطبيق',
              badgeText: 'استخدام البطارية',
              icon: Icons.battery_charging_full_rounded,
            ),
            GuideStep(
              number: 2,
              title: 'فعّل «السماح بالنشاط في الخلفية»',
              subtitle: 'Allow background activity ليعمل الأذان في موعده',
              badgeText: 'نشاط الخلفية',
              icon: Icons.check_circle_outline_rounded,
            ),
            GuideStep(
              number: 3,
              title: 'فعّل «السماح ببدء التشغيل التلقائي»',
              subtitle: 'Allow auto-launch ليعمل الأذان بعد قفل الشاشة أو إعادة التشغيل',
              badgeText: 'تشغيل تلقائي',
              icon: Icons.power_settings_new_rounded,
            ),
          ],
          hasAutoStart: true,
        );

      case DeviceBrandKey.huawei:
        return BrandGuideInfo(
          brandKey: key,
          displayName: 'هواتف هواوي وهونر (Huawei / Honor)',
          rawManufacturer: rawMfr,
          model: model.isNotEmpty ? model : 'Honor / Huawei',
          summaryTip: 'اختر (إدارة يدوية) وفعّل كافة خيارات التشغيل في الخلفية',
          steps: const [
            GuideStep(
              number: 1,
              title: 'اضغط على «إطلاق التطبيقات» (App Launch)',
              subtitle: 'أو إدارة التشغيل في إعدادات التطبيق أو البطارية',
              badgeText: 'إطلاق التطبيقات',
              icon: Icons.rocket_launch_outlined,
            ),
            GuideStep(
              number: 2,
              title: 'عطّل "الإدارة التلقائية" واجعلها يدوية',
              subtitle: 'اضغط على الزر لتظهر لك خيارات الإدارة اليدوية المتقدمة',
              icon: Icons.tune_rounded,
            ),
            GuideStep(
              number: 3,
              title: 'فعّل: التشغيل التلقائي، الثانوي، والعمل في الخلفية',
              subtitle: 'تأكد من تشغيل كافة الخيارات الثلاثة ليعمل الأذان',
              badgeText: 'سماح دائم',
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
          hasAutoStart: true,
        );

      case DeviceBrandKey.vivo:
        return BrandGuideInfo(
          brandKey: key,
          displayName: 'هواتف فيفو (Vivo / iQOO)',
          rawManufacturer: rawMfr,
          model: model.isNotEmpty ? model : 'Vivo',
          summaryTip: 'السماح باستمرار استهلاك طاقة الخلفية عالي',
          steps: const [
            GuideStep(
              number: 1,
              title: 'اضغط على «استهلاك طاقة الخلفية»',
              subtitle: 'High background power consumption',
              badgeText: 'استهلاك الطاقة',
              icon: Icons.battery_charging_full_rounded,
            ),
            GuideStep(
              number: 2,
              title: 'اختر «السماح باستمرار استهلاك الطاقة في الخلفية»',
              subtitle: 'ليتمكن الأذان من العمل في موعده بدقة',
              badgeText: 'سماح',
              icon: Icons.check_circle_outline_rounded,
            ),
            GuideStep(
              number: 3,
              title: 'فعّل خيار التشغيل التلقائي للتطبيق',
              subtitle: 'من إدارة الأذونات وبدء التشغيل',
              icon: Icons.play_circle_outline_rounded,
            ),
          ],
          hasAutoStart: true,
        );

      case DeviceBrandKey.other:
        return BrandGuideInfo(
          brandKey: key,
          displayName: 'أجهزة أندرويد (Google Pixel / Motorola / أجهزة أخرى)',
          rawManufacturer: rawMfr,
          model: model.isNotEmpty ? model : 'Android',
          summaryTip: 'اختر (غير مقيّد / Unrestricted) لاستخدام البطارية',
          steps: const [
            GuideStep(
              number: 1,
              title: 'اضغط على «استخدام البطارية في التطبيق» (App battery usage)',
              subtitle: 'أو خيار "البطارية" في صفحة معلومات التطبيق',
              badgeText: 'البطارية',
              icon: Icons.battery_charging_full_rounded,
            ),
            GuideStep(
              number: 2,
              title: 'اختر «غير مقيّد» (Unrestricted)',
              subtitle: 'يسمح للتطبيق بالعمل في الخلفية وإطلاق صوت الأذان في موعده',
              badgeText: 'غير مقيّد',
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
          hasAutoStart: false,
        );
    }
  }

  /// Attempts direct OS-level dialog (Allow/Deny) without going to full settings screen
  static Future<bool> requestDirectSystemExemption() async {
    return await NativeAdhanBridge.requestIgnoreBatteryOptimizations();
  }

  /// Opens the optimal settings screen for the specific device
  static Future<void> openOptimalSettings(BrandGuideInfo info) async {
    if (info.hasAutoStart) {
      final opened = await NativeAdhanBridge.openAutoStartSettings();
      if (opened) return;
    }
    await NativeAdhanBridge.openAppDetailsSettings();
  }
}
