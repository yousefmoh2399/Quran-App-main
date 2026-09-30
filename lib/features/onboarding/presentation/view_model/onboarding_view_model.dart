import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/onboarding/data/models/onboarding_model.dart';

class OnBoardingViewModel extends GetxController {
  final PageController onboardingController = PageController();
  bool isLast = false;
  int currentIndex = 0;

  void changeSmoothIndicator(int index) {
    currentIndex = index;
    isLast = (index == onboardingData.length - 1);
    update();
  }

  void finishOnboarding(SettingsServices settingsServices) {
    settingsServices.sharedPref!.setBool('onboarding', true).then((_) {
      Get.offAllNamed(AppRoutes.home);
    });
  }

  void next(SettingsServices settingsServices) {
    if (isLast) {
      finishOnboarding(settingsServices);
    } else {
      onboardingController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void previous() {
    if (currentIndex > 0) {
      onboardingController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void onClose() {
    onboardingController.dispose();
    super.onClose();
  }
}
