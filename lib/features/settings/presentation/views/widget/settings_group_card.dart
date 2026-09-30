import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';

class SettingsGroupCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const SettingsGroupCard({
    super.key,
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.sm,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: colors.primary,
                ),
                AppSpacing.horizontalXs,
              ],
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
        AppCard(
          variant: AppCardVariant.elevated,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: colors.divider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
