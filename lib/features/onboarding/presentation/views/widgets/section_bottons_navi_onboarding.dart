import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/components/app_button.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/onboarding/presentation/view_model/onboarding_view_model.dart';

class SectionsButtonsNavi extends StatelessWidget {
  final OnBoardingViewModel controller;
  final SettingsServices settingsServices;

  const SectionsButtonsNavi({
    super.key,
    required this.controller,
    required this.settingsServices,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isLast) {
      return SizedBox(
        width: double.infinity,
        child: AppButton.primary(
          label: 'ابدأ الآن',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          isFullWidth: true,
          onPressed: () => controller.finishOnboarding(settingsServices),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous Button
        if (controller.currentIndex > 0)
          AppButton.text(
            label: 'السابق',
            onPressed: () => controller.previous(),
          )
        else
          const SizedBox(width: 60),

        // Next Button
        AppButton.primary(
          label: 'التالي',
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          onPressed: () => controller.next(settingsServices),
        ),
      ],
    );
  }
}
