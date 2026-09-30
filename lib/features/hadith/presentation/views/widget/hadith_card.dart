import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_model_malek.dart';
import 'package:quran_app_android/features/hadith/presentation/view_model/hadith_view_model.dart';
import 'package:share_plus/share_plus.dart';

class HadithCard extends StatelessWidget {
  final HadithsModel model;
  final HadithViewModel controller;
  final int itemIndex;
  final int totalItems;
  final String chapterName;

  const HadithCard({
    super.key,
    required this.model,
    required this.controller,
    required this.itemIndex,
    required this.totalItems,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final hadithText = model.text?.trim() ?? '';
    final hadithNum = model.arabicnumber ?? (itemIndex + 1);

    return AppCard(
      variant: AppCardVariant.elevated,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Index & Font Resizers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge
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
                  'حديث رقم $hadithNum ($totalItems / ${itemIndex + 1})',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Font controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.text_increase_rounded, size: 20),
                    color: colors.textMuted,
                    tooltip: 'تكبير الخط',
                    onPressed: () => controller.increaseFont(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_decrease_rounded, size: 20),
                    color: colors.textMuted,
                    tooltip: 'تصغير الخط',
                    onPressed: () => controller.decreaseFont(),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.verticalMd,
          // Scrollable Hadith Text
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  hadithText,
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: controller.fontSize,
                    height: 1.85,
                    color: colors.text,
                  ),
                ),
              ),
            ),
          ),
          AppSpacing.verticalMd,
          Divider(color: colors.divider, height: 1),
          AppSpacing.verticalSm,
          // Bottom Actions: Bookmark, Copy, Share
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bookmark button
              TextButton.icon(
                onPressed: () {
                  controller.addCurrentIndex(itemIndex);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'تم حفظ موضع الحديث بنجاح',
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
                icon: Icon(Icons.bookmark_add_rounded, size: 18, color: colors.accent),
                label: Text(
                  'حفظ',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: colors.divider),
              // Copy button
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: '$chapterName\n\n$hadithText'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'تم نسخ نص الحديث بنجاح',
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
                icon: Icon(Icons.copy_rounded, size: 18, color: colors.primary),
                label: Text(
                  'نسخ',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: colors.divider),
              // Share button
              TextButton.icon(
                onPressed: () async {
                  await Share.share(
                    '📜 من موطأ الإمام مالك\n$chapterName\n\n$hadithText',
                    sharePositionOrigin: Rect.fromPoints(
                      const Offset(2, 2),
                      const Offset(3, 3),
                    ),
                  );
                },
                icon: Icon(Icons.share_rounded, size: 18, color: colors.primary),
                label: Text(
                  'مشاركة',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
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
