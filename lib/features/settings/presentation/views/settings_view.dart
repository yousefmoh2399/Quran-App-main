import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/gallery/design_gallery_view.dart';
import 'package:quran_app_android/core/design/components/app_button.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/native/native_azkar_bridge.dart';
import 'package:quran_app_android/core/util/assets.dart';
import 'package:quran_app_android/core/util/widgets/custom_appBar.dart';
import 'package:quran_app_android/core/util/widgets/custom_back_button.dart';
import 'package:quran_app_android/features/settings/presentation/view_model/settins_view_model.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/section_azkar_notification.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/section_stop_notification.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/section_theme_mode.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: CustomAppBar(
        centerTitle: true,
        loading: const CustomBackButton(),
        title: Text(
          'الإعدادات',
          style: Theme.of(context).appBarTheme.titleTextStyle ??
              TextStyle(
                fontSize: 20,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: GetBuilder<SettingsViewModel>(
          init: SettingsViewModel(),
          builder: (controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Lottie.asset(AssetsData.settings, width: 220),
                ),
                AppSpacing.verticalMd,
                const SectionThemeMode(),
                AppSpacing.verticalLg,
                SectionAzkarNotification(controller: controller),
                AppSpacing.verticalLg,
                SectionStopNotification(controller: controller),
                AppSpacing.verticalLg,
                OutlinedButton(
                  onPressed: () async {
                    await NativeAzkarBridge.cancelAzkar();
                  },
                  child: const Text('إلغاء تنبيهات الأذكار المجدولة'),
                ),
                AppSpacing.verticalLg,
                AppButton.secondary(
                  label: 'معرض مكونات التصميم (Design Gallery)',
                  icon: const Icon(Icons.palette_outlined, size: 20),
                  onPressed: () {
                    Get.to(() => const DesignGalleryView());
                  },
                ),
                AppSpacing.verticalXl,
              ],
            );
          },
        ),
      ),
    );
  }
}
