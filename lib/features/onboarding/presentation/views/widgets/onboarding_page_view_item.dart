import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/features/onboarding/data/models/onboarding_model.dart';

class OnBoardingPageViewItems extends StatelessWidget {
  final int index;
  final OnBoardingModel model;

  const OnBoardingPageViewItems({
    super.key,
    required this.index,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Responsive animation height based on screen size
    final animationHeight = (screenHeight * 0.35).clamp(160.0, 280.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation Container
            SizedBox(
              height: animationHeight,
              child: Lottie.asset(
                model.image,
                fit: BoxFit.contain,
              ),
            ),
            AppSpacing.verticalMd,

            // Badge Pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: colors.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                model.badge,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
            AppSpacing.verticalMd,

            // Title
            Text(
              model.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.decorativeFont,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.text,
                height: 1.3,
              ),
            ),
            AppSpacing.verticalSm,

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                model.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 14,
                  color: colors.textMuted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
