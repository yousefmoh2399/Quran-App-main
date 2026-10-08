import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/home/data/services/daily_tadabbur_service.dart';
import 'package:share_plus/share_plus.dart';

class DailyTadabburCard extends StatelessWidget {
  const DailyTadabburCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final item = DailyTadabburService.instance.getTodayTadabbur();

    return AppCard(
      variant: AppCardVariant.elevated,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon + Title + Reference Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  AppSpacing.horizontalXs,
                  Text(
                    'آية وتدبر اليوم',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: colors.accent.withOpacity(0.3)),
                ),
                child: Text(
                  item.reference,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,

          // Ayah Text Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.divider.withOpacity(0.5)),
            ),
            child: Text(
              item.ayahText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.decorativeFont,
                fontSize: 18,
                height: 1.7,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
          ),
          AppSpacing.verticalMd,

          // Reflection / Gem
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 20,
                color: colors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.reflection,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13.5,
                        height: 1.6,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.attribution,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Action Buttons: Open in Mushaf | Copy | Share
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.selection();
                    Get.toNamed(
                      AppRoutes.mushaf,
                      arguments: {'page': item.pageNumber},
                    );
                  },
                  icon: const Icon(Icons.chrome_reader_mode_outlined, size: 16),
                  label: const Text(
                    'تلاوة بالصفحة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'نسخ التدبر',
                onPressed: () {
                  AppHaptics.selection();
                  final textToCopy =
                      '${item.ayahText}\n[${item.reference}]\n\n'
                      '💡 لطيفة تدبرية:\n${item.reflection}\n\n'
                      '📚 المصدر: ${item.attribution}\n\n'
                      'تطبيق تقرب - رفيق المسلم القرآني';
                  Clipboard.setData(ClipboardData(text: textToCopy));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'تم نسخ الآية والتدبر بنجاح',
                        style: TextStyle(fontFamily: AppTypography.uiFont),
                      ),
                      backgroundColor: colors.primary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface,
                  foregroundColor: colors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    side: BorderSide(color: colors.divider),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'مشاركة التدبر',
                onPressed: () {
                  AppHaptics.selection();
                  final textToShare =
                      '${item.ayahText}\n[${item.reference}]\n\n'
                      '💡 لطيفة تدبرية:\n${item.reflection}\n\n'
                      '📚 المصدر: ${item.attribution}\n\n'
                      'تطبيق تقرب - رفيق المسلم القرآني';
                  Share.share(textToShare);
                },
                icon: const Icon(Icons.share_rounded, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary.withOpacity(0.12),
                  foregroundColor: colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
