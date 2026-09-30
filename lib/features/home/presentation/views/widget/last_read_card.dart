import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

class LastReadCard extends StatelessWidget {
  const LastReadCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final settings = Get.find<SettingsServices>();
    final homeVM = Get.find<HomeViewModel>();

    return Obx(() {
      final lastPage = homeVM.lastReadPage.value ??
          settings.sharedPref?.getInt('mushaf_last_page') ??
          1;
      final lastReadRaw = settings.sharedPref?.getString('lastRead');
      final hasLastRead = lastReadRaw != null && lastReadRaw.trim().isNotEmpty;
      final displayTitle = hasLastRead ? lastReadRaw : 'سورة الفاتحة - صفحة ١';

      return AppCard(
        variant: AppCardVariant.elevated,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: AppSpacing.paddingLg,
        backgroundColor: colors.surface,
        onTap: () {
          Get.toNamed(
            AppRoutes.mushaf,
            arguments: {'pageNumber': lastPage},
          )?.then((_) => homeVM.loadUserQuranData());
        },
        child: Row(
          children: [
            // Quran icon in themed container
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
                        Icons.history_rounded,
                        size: 15,
                        color: colors.accent,
                      ),
                      AppSpacing.horizontalXs,
                      Expanded(
                        child: Text(
                          'تابع القراءة',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppSpacing.horizontalXs,
                      Text(
                        'صـ ${toArabicDigits(lastPage)}',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textMuted,
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
                    'اضغط للمتابعة الفورية من آخر موضع',
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

            // Forward button
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
                    'متابعة',
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
