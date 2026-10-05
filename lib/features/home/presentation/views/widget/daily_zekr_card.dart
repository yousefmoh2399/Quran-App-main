import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widgets/zikr_image_share_dialog.dart';

class DailyZekrCard extends StatelessWidget {
  const DailyZekrCard({super.key});

  static const List<(String, String)> _dailyAzkar = [
    (
      'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      'كلمتان خفيفتان على اللسان، ثقيلتان في الميزان، حبيبتان إلى الرحمن'
    ),
    (
      'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      'كنز من كنوز الجنة وباب من أبواب الفرج'
    ),
    (
      'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
      'من لزم الاستغفار جعل الله له من كل هم فرجاً ومن كل ضيق مخرجاً'
    ),
    (
      'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      'من صلى عليّ صلاة صلى الله عليه بها عشراً'
    ),
    (
      'لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
      'دعوة ذي النون ما دعا بها مسلم في كربة إلا فرج الله عنه'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    // Daily index based on day of year
    final dayIndex = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays % _dailyAzkar.length;
    final (zekrText, zekrVirtue) = _dailyAzkar[dayIndex];

    return AppCard(
      variant: AppCardVariant.outlined,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: colors.accent,
                    size: 18,
                  ),
                  AppSpacing.horizontalXs,
                  Text(
                    'ذكر اليوم',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: AppRadius.borderSm,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '$zekrText\n$zekrVirtue'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'تم نسخ الذكر إلى الحافظة بنجاح',
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
                    child: Padding(
                      padding: AppSpacing.paddingXs,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: colors.textMuted,
                          ),
                          AppSpacing.horizontalXs,
                          Text(
                            'نسخ',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: AppRadius.borderSm,
                    onTap: () {
                      ZikrShareHelper.showShareOptions(
                        context,
                        zikrText: zekrText,
                        virtue: zekrVirtue,
                        categoryTitle: 'ذكر اليوم',
                      );
                    },
                    child: Padding(
                      padding: AppSpacing.paddingXs,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.share_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          AppSpacing.horizontalXs,
                          Text(
                            'مشاركة',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.verticalMd,
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.04),
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.divider.withOpacity(0.6)),
            ),
            child: Column(
              children: [
                Text(
                  zekrText,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontFamily: AppTypography.decorativeFont,
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                  ),
                ),
                AppSpacing.verticalSm,
                Text(
                  zekrVirtue,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
