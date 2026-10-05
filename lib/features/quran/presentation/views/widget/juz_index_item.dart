import 'package:flutter/material.dart';
import 'package:quran_app_android/core/data/models/quran_marks_models.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';
import 'package:quran_app_android/features/quran/data/models/juz_model.dart';

/// Highly optimized Juz index row with support for:
/// 1. "آخر قراءة" badge in identity primary color (opens exact last read page)
/// 2. "ابدأ من أول الجزء" secondary action
/// 3. Bookmark indicator icon
/// 4. Memorization percentage indicator and full checkmark ✓ when complete
class JuzIndexItem extends StatelessWidget {
  final JuzModel juz;
  final JuzMarksSummary? marks;
  final VoidCallback onTap;
  final VoidCallback? onStartFromBeginning;

  const JuzIndexItem({
    super.key,
    required this.juz,
    this.marks,
    required this.onTap,
    this.onStartFromBeginning,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final isLastRead = marks?.isLastRead == true;
    final hasBookmark = marks?.hasBookmark == true;
    final isFullyMemorized = marks?.isFullyMemorized == true;
    final isPartiallyMemorized = marks?.isPartiallyMemorized == true;
    const successColor = Color(0xFF27AE60);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: isLastRead && onStartFromBeginning != null
          ? onStartFromBeginning
          : null,
      child: AppCard(
        variant: isLastRead ? AppCardVariant.outlined : AppCardVariant.elevated,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        onTap: onTap,
        child: Row(
          children: [
            // 1. Juz Number Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isLastRead
                    ? colors.primary.withOpacity(0.16)
                    : colors.accent.withOpacity(0.12),
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: isLastRead
                      ? colors.primary
                      : colors.accent.withOpacity(0.3),
                  width: isLastRead ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  '${juz.number}',
                  style: textTheme.labelMedium?.copyWith(
                    color: isLastRead ? colors.primary : colors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            AppSpacing.horizontalMd,

            // 2. Juz Details & Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          juz.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasBookmark) ...[
                        AppSpacing.horizontalXs,
                        Tooltip(
                          message: 'يحتوي على علامة مرجعية',
                          child: Icon(
                            Icons.bookmark_rounded,
                            size: 17,
                            color: colors.accent,
                            key: const Key('juz_bookmark_icon'),
                          ),
                        ),
                      ],
                      if (isFullyMemorized) ...[
                        AppSpacing.horizontalXs,
                        Tooltip(
                          message: 'جزء محفوظ بالكامل (١٠٠٪)',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: successColor.withOpacity(0.12),
                              borderRadius: AppRadius.borderFull,
                              border: Border.all(
                                color: successColor.withOpacity(0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: successColor,
                                  key: Key('juz_fully_memorized_icon'),
                                ),
                                AppSpacing.horizontalXs,
                                Text(
                                  'محفوظ',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: successColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.verticalXs,

                  // Subtitle: Start Surah & Memorization progress if partial
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'يبدأ من سورة ${juz.startSurahName} (آية ${juz.startAyah})',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPartiallyMemorized && marks != null) ...[
                        AppSpacing.horizontalSm,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.08),
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  value: marks!.memorizedRatio,
                                  strokeWidth: 2,
                                  backgroundColor: colors.divider,
                                  color: colors.primary,
                                ),
                              ),
                              AppSpacing.horizontalXs,
                              Text(
                                '${toArabicDigits(marks!.memorizedPercentage)}٪',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Last Read Badge & Beginning Button
                  if (isLastRead && marks?.lastReadPage != null) ...[
                    AppSpacing.verticalXs,
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          key: const Key('juz_last_read_badge'),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              AppSpacing.horizontalXs,
                              Text(
                                'آخر قراءة - صـ ${toArabicDigits(marks!.lastReadPage!)}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onStartFromBeginning != null)
                          InkWell(
                            key: const Key('juz_start_beginning_btn'),
                            onTap: onStartFromBeginning,
                            borderRadius: AppRadius.borderSm,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.first_page_rounded,
                                    size: 15,
                                    color: colors.textMuted,
                                  ),
                                  AppSpacing.horizontalXs,
                                  Text(
                                    'من أول الجزء',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.textMuted,
                                      fontSize: 10.5,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.horizontalSm,

            // 3. Arrow indicator
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isLastRead ? colors.primary : colors.textMuted.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
