import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

class LatestBookmarkCard extends StatelessWidget {
  const LatestBookmarkCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final homeVM = Get.find<HomeViewModel>();

    return Obx(() {
      final bookmark = homeVM.latestBookmark.value;

      if (bookmark == null) {
        return AppCard(
          variant: AppCardVariant.outlined,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: AppSpacing.paddingMd,
          backgroundColor: colors.surface,
          onTap: () => Get.toNamed(AppRoutes.bookmarks),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.12),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(Icons.bookmark_add_outlined, color: colors.accent, size: 22),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'علامتك المحفوظة',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      'احفظ موضع قراءتك بشريط ملون للرجوع إليه بلمسة',
                      style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textMuted),
            ],
          ),
        );
      }

      final isAyah = bookmark.type == BookmarkType.ayah;
      final badgeColor = bookmark.color.color;

      return AppCard(
        variant: AppCardVariant.elevated,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: AppSpacing.paddingLg,
        backgroundColor: colors.surface,
        onTap: () {
          Get.toNamed(
            AppRoutes.mushaf,
            arguments: {
              'pageNumber': bookmark.page,
              if (bookmark.surah != null) 'surah': bookmark.surah,
              if (bookmark.ayah != null) 'ayah': bookmark.ayah,
            },
          )?.then((_) => homeVM.loadUserQuranData());
        },
        child: Row(
          children: [
            // Color Bookmark Icon Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.14),
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Icon(
                Icons.bookmark_rounded,
                color: badgeColor,
                size: 28,
              ),
            ),
            AppSpacing.horizontalMd,

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          bookmark.color.labelAr,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      AppSpacing.horizontalXs,
                      Text(
                        'علامتك المحفوظة',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'صـ ${toArabicDigits(bookmark.page)}',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalXs,
                  Text(
                    isAyah && bookmark.ayah != null
                        ? 'آية ${toArabicDigits(bookmark.ayah!)} (صفحة ${toArabicDigits(bookmark.page)})'
                        : 'صفحة ${toArabicDigits(bookmark.page)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTypography.decorativeFont,
                      color: colors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    bookmark.note != null && bookmark.note!.trim().isNotEmpty
                        ? bookmark.note!
                        : 'انقر للانتقال مباشرة إلى العلامة',
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

            // Forward action button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: AppRadius.borderMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'فتح',
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
    });
  }
}
