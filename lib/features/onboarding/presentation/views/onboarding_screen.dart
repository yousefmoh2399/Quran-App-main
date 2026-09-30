import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/onboarding/data/models/onboarding_model.dart';
import 'package:quran_app_android/features/onboarding/presentation/view_model/onboarding_view_model.dart';
import 'package:quran_app_android/features/onboarding/presentation/views/widgets/onboarding_page_view.dart';
import 'package:quran_app_android/features/onboarding/presentation/views/widgets/section_bottons_navi_onboarding.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingScreen extends StatelessWidget {
  OnBoardingScreen({super.key});

  final SettingsServices settingsServices = Get.find<SettingsServices>();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: GetBuilder<OnBoardingViewModel>(
          init: OnBoardingViewModel(),
          builder: (controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  // Top Header with App Name and Skip button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 22,
                            color: colors.primary,
                          ),
                          AppSpacing.horizontalXs,
                          Text(
                            'تطبيق القرآن الكريم',
                            style: TextStyle(
                              fontFamily: AppTypography.decorativeFont,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (!controller.isLast)
                        TextButton(
                          onPressed: () =>
                              controller.finishOnboarding(settingsServices),
                          child: Text(
                            'تخطي',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textMuted,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                  AppSpacing.verticalSm,

                  // Main Carousel PageView
                  OnBoardingPageView(controller: controller),
                  AppSpacing.verticalMd,

                  // Dots Indicator
                  SmoothPageIndicator(
                    controller: controller.onboardingController,
                    count: onboardingData.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: colors.primary,
                      dotColor: colors.divider,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3.5,
                      spacing: 6,
                    ),
                  ),
                  AppSpacing.verticalLg,

                  // Bottom Navigation Actions
                  SectionsButtonsNavi(
                    controller: controller,
                    settingsServices: settingsServices,
                  ),
                  AppSpacing.verticalSm,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
