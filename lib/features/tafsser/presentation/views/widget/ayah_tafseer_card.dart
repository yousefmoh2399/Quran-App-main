import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/features/quran/data/models/details_model.dart';
import 'package:quran_app_android/features/tafsser/data/models/tafaseerModel.dart';
import 'package:share_plus/share_plus.dart';

class AyahTafseerCard extends StatelessWidget {
  final VersesModel verse;
  final DataModel? tafseer;
  final int ayahIndex;
  final String surahName;
  final double fontSize;
  final VoidCallback onBookmark;

  const AyahTafseerCard({
    super.key,
    required this.verse,
    required this.tafseer,
    required this.ayahIndex,
    required this.surahName,
    required this.fontSize,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final ayahText = verse.text?.trim() ?? '';
    final tafseerText = tafseer?.text?.trim() ?? 'التفسير غير متوفر حالياً';
    final ayahNum = verse.id ?? (ayahIndex + 1);

    return AppCard(
      variant: AppCardVariant.elevated,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah header bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  'الآية رقم $ayahNum',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.bookmark_add_rounded, size: 20, color: colors.accent),
                    tooltip: 'حفظ الموضع',
                    onPressed: onBookmark,
                  ),
                  IconButton(
                    icon: Icon(Icons.copy_rounded, size: 18, color: colors.primary),
                    tooltip: 'نسخ الآية والتفسير',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: '﴿$ayahText﴾ [$surahName: $ayahNum]\n\nالتفسير الميسر:\n$tafseerText',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'تم نسخ الآية وتفسيرها بنجاح',
                            style: TextStyle(fontFamily: AppTypography.uiFont),
                          ),
                          backgroundColor: colors.primary,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMd,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.share_rounded, size: 18, color: colors.primary),
                    tooltip: 'مشاركة',
                    onPressed: () async {
                      await Share.share(
                        '﴿$ayahText﴾ [$surahName: $ayahNum]\n\nالتفسير الميسر:\n$tafseerText',
                        sharePositionOrigin: Rect.fromPoints(
                          const Offset(2, 2),
                          const Offset(3, 3),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.verticalMd,
          // Ayah Quranic text
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.04),
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.divider.withOpacity(0.5)),
            ),
            child: Text(
              '﴿ $ayahText ﴾',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: textTheme.titleLarge?.copyWith(
                fontFamily: AppTypography.decorativeFont,
                fontSize: fontSize + 2,
                height: 1.8,
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppSpacing.verticalMd,
          // Tafseer section
          Row(
            children: [
              Icon(Icons.library_books_rounded, size: 16, color: colors.accent),
              AppSpacing.horizontalXs,
              Text(
                'التفسير الميسر',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          AppSpacing.verticalXs,
          Text(
            tafseerText,
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: AppTypography.uiFont,
              fontSize: fontSize - 2,
              height: 1.7,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }
}
