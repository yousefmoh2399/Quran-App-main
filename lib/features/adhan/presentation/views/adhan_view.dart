import 'package:quran_app_android/features/adhan/presentation/widgets/battery_optimization_guide_dialog.dart';
import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/design/components/loading_skeleton.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/core/util/widgets/custom_toast.dart';
import 'package:quran_app_android/features/adhan/presentation/services/adhan_battery_permission_service.dart';
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';
import 'package:quran_app_android/features/adhan/presentation/views/widget/adhan_hero_card.dart';
import 'package:quran_app_android/features/adhan/presentation/views/widget/adhan_location_bar.dart';
import 'package:quran_app_android/features/adhan/presentation/views/widget/adhan_prayer_row.dart';

class AdhanView extends StatefulWidget {
  const AdhanView({super.key});

  @override
  State<AdhanView> createState() => _AdhanViewState();
}

class _AdhanViewState extends State<AdhanView> with WidgetsBindingObserver {
  bool _showBatteryPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBatteryReliability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBatteryReliability();
    }
  }

  Future<void> _checkBatteryReliability() async {
    if (!Platform.isAndroid) return;
    if (AdhanBatteryPermissionService.hasDismissedNoticeInSession) return;
    final status = await AdhanBatteryPermissionService.checkStatus();
    if (mounted) {
      final wasPrompting = _showBatteryPrompt;
      setState(() {
        _showBatteryPrompt = !status.isFullyConfigured;
      });
      if (wasPrompting && status.isFullyConfigured) {
        defaultToast(text: 'تم ضبط استثناء موفر البطارية بنجاح للأذان');
      }
    }
  }

  PrayerItemStatus _getPrayerStatus(
    Prayer prayer,
    DateTime prayerTime,
    Prayer nextPrayer,
    Prayer currentPrayer,
  ) {
    if (prayer == nextPrayer) {
      return PrayerItemStatus.next;
    }
    if (prayer == currentPrayer) {
      return PrayerItemStatus.current;
    }
    final now = DateTime.now();
    if (now.isAfter(prayerTime)) {
      return PrayerItemStatus.passed;
    }
    return PrayerItemStatus.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      title: 'مواقيت الصلاة',
      constrainContentWidth: true,
      actions: [
        if (kDebugMode)
          IconButton(
            icon: Icon(
              Icons.bug_report_outlined,
              color: colors.primary,
              size: 22,
            ),
            tooltip: 'فحص الأذان والجدولة',
            onPressed: () => Get.toNamed(AppRoutes.adhanDebug),
          ),
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: colors.primary,
            size: 22,
          ),
          tooltip: 'إعدادات الأذان والمؤذن',
          onPressed: () => Get.toNamed(AppRoutes.adhanSettings),
        ),
        GetBuilder<AdhanViewModel>(
          builder: (controller) => IconButton(
            icon: Icon(
              Icons.my_location_rounded,
              color: colors.primary,
              size: 22,
            ),
            tooltip: 'تحديث الموقع',
            onPressed: controller.isLoading.value
                ? null
                : () => controller.getCurrentLocation(),
          ),
        ),
      ],
      body: Stack(
        children: [
          GetBuilder<AdhanViewModel>(
        builder: (controller) {
          if (controller.isLoading.value && controller.prayerTimes == null) {
            return _buildLoadingState();
          }

          final pt = controller.prayerTimes;
          if (pt == null || controller.isLocationRequired.value) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EmptyState(
                      icon: Icons.location_off_rounded,
                      title: 'مطلوب تحديد الموقع لحساب المواقيت',
                      message:
                          'لحساب مواقيت الصلاة بدقة شرعية تامة، يرجى تفعيل الـ GPS أو اختيار مدينتك يدوياً من الإعدادات.',
                      actionLabel: 'تحديد الموقع تلقائياً (GPS)',
                      onActionPressed: () => controller.getCurrentLocation(),
                    ),
                    AppSpacing.verticalMd,
                    TextButton.icon(
                      icon: const Icon(Icons.location_city_rounded),
                      label: const Text('أو اختر المدينة من إعدادات الأذان'),
                      onPressed: () => Get.toNamed(AppRoutes.adhanSettings),
                    ),
                  ],
                ),
              ),
            );
          }

          final nextPrayer = pt.nextPrayer() == Prayer.none
              ? Prayer.fajr
              : pt.nextPrayer();
          final currentPrayer = pt.currentPrayer();

          final prayerItems = [
            _PrayerItemData(
              title: 'صلاة الفجر',
              englishSubtitle: 'Fajr',
              prayer: Prayer.fajr,
              time: pt.fajr,
              icon: Icons.nights_stay_rounded,
            ),
            _PrayerItemData(
              title: 'شروق الشمس',
              englishSubtitle: 'Sunrise',
              prayer: Prayer.sunrise,
              time: pt.sunrise,
              icon: Icons.wb_sunny_outlined,
            ),
            _PrayerItemData(
              title: 'صلاة الظهر',
              englishSubtitle: 'Dhuhr',
              prayer: Prayer.dhuhr,
              time: pt.dhuhr,
              icon: Icons.wb_sunny_rounded,
            ),
            _PrayerItemData(
              title: 'صلاة العصر',
              englishSubtitle: 'Asr',
              prayer: Prayer.asr,
              time: pt.asr,
              icon: Icons.brightness_6_rounded,
            ),
            _PrayerItemData(
              title: 'صلاة المغرب',
              englishSubtitle: 'Maghrib',
              prayer: Prayer.maghrib,
              time: pt.maghrib,
              icon: Icons.brightness_4_rounded,
            ),
            _PrayerItemData(
              title: 'صلاة العشاء',
              englishSubtitle: 'Isha',
              prayer: Prayer.isha,
              time: pt.isha,
              icon: Icons.dark_mode_rounded,
            ),
          ];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Location & method info bar
                AdhanLocationBar(
                  isDefaultLocation: controller.isDefaultLocation,
                  isLoading: controller.isLoading.value,
                  onRefreshLocation: () => controller.getCurrentLocation(),
                ),

                // Hero Countdown & Next Prayer Card
                AdhanHeroCard(prayerTimes: pt),
                AppSpacing.verticalLg,

                // Section Title: مواقيت الصلاة اليوم
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    Text(
                      'مواقيت الصلاة اليوم',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalMd,

                // 6 Prayer Rows
                for (final item in prayerItems)
                  AdhanPrayerRow(
                    title: item.title,
                    englishSubtitle: item.englishSubtitle,
                    time: item.time,
                    icon: item.icon,
                    status: _getPrayerStatus(
                      item.prayer,
                      item.time,
                      nextPrayer,
                      currentPrayer,
                    ),
                  ),

                AppSpacing.verticalMd,

                // Spiritual reminder card
                AppCard(
                  variant: AppCardVariant.flat,
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 26,
                        color: colors.accent,
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        child: Text(
                          '«إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا»',
                          style: TextStyle(
                            fontFamily: AppTypography.decorativeFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalLg,
              ],
            ),
          );
        },
      ),
      if (_showBatteryPrompt)
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildFloatingBatteryPrompt(colors),
        ),
    ],
  ),
);
}

  Widget _buildFloatingBatteryPrompt(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.battery_alert_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لضمان انطلاق الأذان في وقته بدقة',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'يحتاج التطبيق للاستثناء من توفير البطارية حتى لا يوقفه النظام في الخلفية.',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() => _showBatteryPrompt = false);
                  AdhanBatteryPermissionService.hasDismissedNoticeInSession = true;
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.close_rounded, size: 18, color: colors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colors.textMuted,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  setState(() => _showBatteryPrompt = false);
                  AdhanBatteryPermissionService.hasDismissedNoticeInSession = true;
                },
                child: const Text(
                  'لاحقاً',
                  style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text(
                  'ضبط الإعدادات الآن',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                onPressed: () {
                  BatteryOptimizationGuideDialog.show(context, onSettingsCompleted: () {
                    _checkBatteryReliability();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LoadingSkeleton(
            width: double.infinity,
            height: 60,
          ),
          AppSpacing.verticalMd,
          const LoadingSkeleton(
            width: double.infinity,
            height: 200,
          ),
          AppSpacing.verticalLg,
          for (int i = 0; i < 6; i++) ...[
            const LoadingSkeleton(
              width: double.infinity,
              height: 64,
            ),
            AppSpacing.verticalSm,
          ],
        ],
      ),
    );
  }
}

class _PrayerItemData {
  final String title;
  final String englishSubtitle;
  final Prayer prayer;
  final DateTime time;
  final IconData icon;

  const _PrayerItemData({
    required this.title,
    required this.englishSubtitle,
    required this.prayer,
    required this.time,
    required this.icon,
  });
}
