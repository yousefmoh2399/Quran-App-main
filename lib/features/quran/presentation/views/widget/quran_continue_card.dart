import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

/// Pinned top card on the Quran index screen:
/// "تابع من سورة [الاسم] صفحة [الرقم]"
class QuranContinueReadingCard extends StatelessWidget {
  final String surahName;
  final int pageNumber;
  final VoidCallback onTap;

  const QuranContinueReadingCard({
    super.key,
    required this.surahName,
    required this.pageNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderMd,
          gradient: LinearGradient(
            colors: [
              colors.primary,
              colors.primary.withOpacity(0.85),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.borderMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'تابع القراءة',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.horizontalXs,
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: AppRadius.borderSm,
                              ),
                              child: Text(
                                'صفحة ${toArabicDigits(pageNumber)}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalXs,
                        Text(
                          surahName.isNotEmpty ? 'سورة $surahName' : 'المصحف الشريف',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTypography.decorativeFont,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.horizontalSm,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.borderFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'متابعة',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.horizontalXs,
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
