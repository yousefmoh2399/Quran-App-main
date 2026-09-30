import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

class LastReadCard extends StatelessWidget {
  const LastReadCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final settings = Get.find<SettingsServices>();
    final lastReadRaw = settings.sharedPref?.getString('lastRead');

    // Parse or default
    final hasLastRead = lastReadRaw != null && lastReadRaw.trim().isNotEmpty;
    final displayTitle = hasLastRead ? lastReadRaw : 'سورة الفاتحة';
    final subtitle = hasLastRead ? 'آخر موضع توقفت عنده' : 'ابدأ وردك اليومي المبارك';

    return AppCard(
      variant: AppCardVariant.elevated,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: AppSpacing.paddingLg,
      backgroundColor: colors.surface,
      onTap: () => Get.toNamed(AppRoutes.quranScreen),
      child: Row(
        children: [
          // Quran icon in themed circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: colors.primary.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: colors.primary,
              size: 26,
            ),
          ),
          AppSpacing.horizontalMd,
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bookmark_added_rounded,
                      size: 15,
                      color: colors.accent,
                    ),
                    AppSpacing.horizontalXs,
                    Text(
                      'تابع القراءة',
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalXs,
                Text(
                  displayTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTypography.decorativeFont,
                    color: colors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.horizontalSm,
          // Forward arrow / continue indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: AppRadius.borderMd,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'قراءة',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.horizontalXs,
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
