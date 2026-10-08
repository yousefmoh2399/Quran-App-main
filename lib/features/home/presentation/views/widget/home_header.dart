import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/service/theme_controller.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  static const List<String> _arabicDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> _arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  String _formatGregorian(DateTime dt) {
    final day = _arabicDays[dt.weekday - 1];
    final month = _arabicMonths[dt.month - 1];
    return '$day، ${dt.day} $month ${dt.year} م';
  }

  String _formatHijri() {
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.now();
      return '${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {
      return '';
    }
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour >= 3 && hour < 12) {
      return 'صباح الخير والبركة';
    } else if (hour >= 12 && hour < 17) {
      return 'طابت أوقاتكم بذكر الله';
    } else {
      return 'مساء الخير والسكينة';
    }
  }

  IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 3 && hour < 12) {
      return Icons.wb_sunny_rounded;
    } else if (hour >= 12 && hour < 17) {
      return Icons.wb_cloudy_rounded;
    } else {
      return Icons.nightlight_round;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final hijriStr = _formatHijri();
    final gregorianStr = _formatGregorian(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _greetingText(),
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _greetingIcon(),
                      size: 18,
                      color: colors.primary,
                    ),
                  ],
                ),
                AppSpacing.verticalXs,
                if (hijriStr.isNotEmpty)
                  Text(
                    hijriStr,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppTypography.uiFont,
                    ),
                  ),
                Text(
                  gregorianStr,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.horizontalSm,
          // Quick theme toggle button
          GetBuilder<ThemeController>(
            builder: (themeCtrl) {
              final isDark = themeCtrl.themeMode == ThemeMode.dark;
              return Material(
                color: colors.surface,
                borderRadius: AppRadius.borderMd,
                child: InkWell(
                  borderRadius: AppRadius.borderMd,
                  onTap: () {
                    themeCtrl.setThemeMode(
                      isDark ? ThemeMode.light : ThemeMode.dark,
                    );
                  },
                  child: Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.divider),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          ),
          AppSpacing.horizontalSm,
          // Settings button
          Material(
            color: colors.surface,
            borderRadius: AppRadius.borderMd,
            child: InkWell(
              borderRadius: AppRadius.borderMd,
              onTap: () => Get.toNamed(AppRoutes.settings),
              child: Container(
                padding: AppSpacing.paddingSm,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.divider),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: colors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
