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
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';
import 'package:quran_app_android/features/adhan/presentation/views/widget/adhan_hero_card.dart';
import 'package:quran_app_android/features/adhan/presentation/views/widget/adhan_location_bar.dart';
import 'package:quran_app_android/features/adhan/presentation/views/widget/adhan_prayer_row.dart';

class AdhanView extends StatelessWidget {
  const AdhanView({super.key});

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
      body: GetBuilder<AdhanViewModel>(
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
