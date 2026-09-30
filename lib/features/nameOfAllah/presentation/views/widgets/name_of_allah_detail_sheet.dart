import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_bottom_sheet.dart';
import 'package:quran_app_android/features/nameOfAllah/data/models/Names_Of_Allah_model.dart';
import 'package:share_plus/share_plus.dart';

class NameOfAllahDetailSheet extends StatefulWidget {
  final List<NamesOfAllahModel> namesList;
  final int initialIndex;

  const NameOfAllahDetailSheet({
    super.key,
    required this.namesList,
    required this.initialIndex,
  });

  static void show(
    BuildContext context, {
    required List<NamesOfAllahModel> namesList,
    required int initialIndex,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NameOfAllahDetailSheet(
        namesList: namesList,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<NameOfAllahDetailSheet> createState() => _NameOfAllahDetailSheetState();
}

class _NameOfAllahDetailSheetState extends State<NameOfAllahDetailSheet> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final item = widget.namesList[_currentIndex];
    final total = widget.namesList.length;

    return AppBottomSheet(
      title: 'شرح اسم الله الحسنى',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Decorative Name Header Container
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: colors.accent.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Number badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.18),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Text(
                    '${_currentIndex + 1} من $total',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppSpacing.verticalMd,
                // Name in decorative Amiri font
                Text(
                  item.name ?? '',
                  textAlign: TextAlign.center,
                  style: textTheme.displayMedium?.copyWith(
                    fontFamily: AppTypography.decorativeFont,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalLg,
          // Meaning and explanation
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                item.text ?? '',
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: textTheme.bodyLarge?.copyWith(
                  fontFamily: AppTypography.uiFont,
                  height: 1.8,
                  color: colors.text,
                ),
              ),
            ),
          ),
          AppSpacing.verticalLg,
          Divider(color: colors.divider, height: 1),
          AppSpacing.verticalMd,
          // Bottom controls: Previous, Copy, Share, Next
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                color: _currentIndex > 0 ? colors.primary : colors.divider,
                tooltip: 'الاسم السابق',
                onPressed: _currentIndex > 0
                    ? () => setState(() => _currentIndex--)
                    : null,
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: '${item.name}\n${item.text}'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'تم نسخ الاسم والشرح بنجاح',
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
                  AppSpacing.horizontalSm,
                  TextButton.icon(
                    onPressed: () async {
                      await Share.share(
                        '✨ ${item.name} ✨\n\n${item.text}',
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
              // Next button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                color: _currentIndex < total - 1 ? colors.primary : colors.divider,
                tooltip: 'الاسم التالي',
                onPressed: _currentIndex < total - 1
                    ? () => setState(() => _currentIndex++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
