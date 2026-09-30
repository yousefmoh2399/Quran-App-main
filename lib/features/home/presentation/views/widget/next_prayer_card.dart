import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';

class NextPrayerCard extends StatefulWidget {
  const NextPrayerCard({super.key});

  @override
  State<NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<NextPrayerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _prayerNameArabic(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.none:
        return 'الفجر';
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = isPm ? 'م' : 'ص';
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return GetBuilder<AdhanViewModel>(
      builder: (controller) {
        final prayerTimes = controller.prayerTimes;

        if (controller.isLoading.value && prayerTimes == null) {
          return AppCard(
            variant: AppCardVariant.elevated,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: AppSpacing.paddingLg,
            child: SizedBox(
              height: 140,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      ),
                    ),
                    AppSpacing.horizontalMd,
                    Text(
                      'جارٍ حساب مواقيت الصلاة...',
                      style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final now = DateTime.now();
        Prayer nextPrayer = prayerTimes?.nextPrayer() ?? Prayer.none;
        DateTime? nextPrayerTime;

        if (prayerTimes != null) {
          if (nextPrayer != Prayer.none) {
            nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);
          } else {
            // Next is tomorrow's Fajr
            nextPrayer = Prayer.fajr;
            nextPrayerTime = prayerTimes.fajr.add(const Duration(days: 1));
          }
        }

        String countdownText = '--:--:--';
        if (nextPrayerTime != null) {
          final diff = nextPrayerTime.difference(now);
          if (!diff.isNegative) {
            final h = diff.inHours.toString().padLeft(2, '0');
            final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
            final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
            countdownText = '$h:$m:$s';
          }
        }

        final prayersList = [
          (Prayer.fajr, 'الفجر', prayerTimes?.fajr, Icons.wb_twilight_rounded),
          (Prayer.sunrise, 'الشروق', prayerTimes?.sunrise, Icons.wb_sunny_outlined),
          (Prayer.dhuhr, 'الظهر', prayerTimes?.dhuhr, Icons.wb_sunny_rounded),
          (Prayer.asr, 'العصر', prayerTimes?.asr, Icons.filter_drama_rounded),
          (Prayer.maghrib, 'المغرب', prayerTimes?.maghrib, Icons.nights_stay_outlined),
          (Prayer.isha, 'العشاء', prayerTimes?.isha, Icons.nights_stay_rounded),
        ];

        return AppCard(
          variant: AppCardVariant.elevated,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: AppSpacing.paddingLg,
          onTap: () => Get.toNamed(AppRoutes.adhan),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Next prayer name, time, and countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded, size: 18, color: colors.accent),
                            AppSpacing.horizontalXs,
                            Text(
                              'الصلاة القادمة',
                              style: textTheme.labelMedium?.copyWith(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalXs,
                        Text(
                          _prayerNameArabic(nextPrayer),
                          style: textTheme.headlineMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          _formatTime(nextPrayerTime),
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        'متبقي $countdownText',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.verticalMd,
              Divider(color: colors.divider, height: 1),
              AppSpacing.verticalMd,
              // Horizontal row of prayers
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: prayersList.map((item) {
                    final isCurrentNext = item.$1 == nextPrayer;
                    return Container(
                      margin: const EdgeInsets.only(left: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentNext
                            ? colors.primary.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: AppRadius.borderSm,
                        border: isCurrentNext
                            ? Border.all(color: colors.primary.withOpacity(0.5))
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.$4,
                            size: 16,
                            color: isCurrentNext ? colors.primary : colors.textMuted,
                          ),
                          AppSpacing.verticalXs,
                          Text(
                            item.$2,
                            style: textTheme.labelSmall?.copyWith(
                              color: isCurrentNext ? colors.primary : colors.text,
                              fontWeight: isCurrentNext ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatTime(item.$3),
                            style: textTheme.labelSmall?.copyWith(
                              color: isCurrentNext ? colors.primary : colors.textMuted,
                              fontWeight: isCurrentNext ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
