import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_shadows.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';

enum PrayerItemStatus {
  passed,
  current,
  next,
  upcoming,
}

class AdhanPrayerRow extends StatelessWidget {
  final String title;
  final String englishSubtitle;
  final DateTime time;
  final IconData icon;
  final PrayerItemStatus status;

  const AdhanPrayerRow({
    super.key,
    required this.title,
    required this.englishSubtitle,
    required this.time,
    required this.icon,
    required this.status,
  });

  String _formatTime(DateTime time) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNext = status == PrayerItemStatus.next;
    final isCurrent = status == PrayerItemStatus.current;
    final isPassed = status == PrayerItemStatus.passed;

    Color backgroundColor;
    Color borderColor;
    Color iconBackgroundColor;
    Color iconColor;
    Color titleColor;
    Color timeColor;

    if (isNext) {
      backgroundColor = colors.primary.withOpacity(0.08);
      borderColor = colors.accent;
      iconBackgroundColor = colors.accent.withOpacity(0.18);
      iconColor = colors.accent;
      titleColor = colors.primary;
      timeColor = colors.primary;
    } else if (isCurrent) {
      backgroundColor = colors.surface;
      borderColor = colors.primary;
      iconBackgroundColor = colors.primary.withOpacity(0.12);
      iconColor = colors.primary;
      titleColor = colors.text;
      timeColor = colors.primary;
    } else if (isPassed) {
      backgroundColor = colors.surface.withOpacity(0.6);
      borderColor = colors.divider.withOpacity(0.5);
      iconBackgroundColor = colors.divider.withOpacity(0.3);
      iconColor = colors.textMuted.withOpacity(0.6);
      titleColor = colors.textMuted;
      timeColor = colors.textMuted;
    } else {
      backgroundColor = colors.surface;
      borderColor = colors.divider;
      iconBackgroundColor = colors.bg;
      iconColor = colors.primary;
      titleColor = colors.text;
      timeColor = colors.text;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: borderColor,
          width: isNext ? 1.8 : 1.0,
        ),
        boxShadow: AppShadows.card(isDark),
      ),
      child: Row(
        children: [
          // Prayer Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
          AppSpacing.horizontalMd,

          // Prayer Title & Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 16,
                        fontWeight: isNext || isCurrent
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (isNext) ...[
                      AppSpacing.horizontalSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'القادمة',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    if (isCurrent && !isNext) ...[
                      AppSpacing.horizontalSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'الحالية',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Formatted Time & Passed Status Checkmark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(time),
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 15,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                  color: timeColor,
                ),
              ),
              if (isPassed) ...[
                AppSpacing.horizontalXs,
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: colors.textMuted.withOpacity(0.6),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
