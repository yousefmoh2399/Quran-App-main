import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/features/nameOfAllah/data/models/Names_Of_Allah_model.dart';
import 'package:quran_app_android/features/nameOfAllah/presentation/views/widgets/name_of_allah_detail_sheet.dart';

class NameOfAllahCard extends StatelessWidget {
  final NamesOfAllahModel model;
  final int index;
  final List<NamesOfAllahModel> fullList;

  const NameOfAllahCard({
    super.key,
    required this.model,
    required this.index,
    required this.fullList,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: AppSpacing.paddingMd,
      onTap: () {
        NameOfAllahDetailSheet.show(
          context,
          namesList: fullList,
          initialIndex: index,
        );
      },
      child: Stack(
        children: [
          // Background subtle decorative pattern or accent corner
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.12),
                borderRadius: AppRadius.borderSm,
              ),
              child: Text(
                '${index + 1}',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSpacing.verticalSm,
                // Divine Name in Amiri font
                Text(
                  model.name ?? '',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontFamily: AppTypography.decorativeFont,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.verticalXs,
                // Meaning excerpt
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(
                    model.text ?? '',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
