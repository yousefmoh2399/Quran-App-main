// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/hadith/presentation/view_model/hadith_view_model.dart';
import 'package:quran_app_android/features/hadith/presentation/views/widget/hadith_card.dart';

class HadithView extends StatelessWidget {
  const HadithView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = Get.find<SettingsServices>();
    final controller = Get.isRegistered<HadithViewModel>()
        ? Get.find<HadithViewModel>()
        : Get.put(HadithViewModel());

    final chapterIndex = settings.sharedPref?.getInt('indexHadith') ?? 0;

    return GetBuilder<HadithViewModel>(
      init: controller,
      builder: (ctrl) {
        if (chapterIndex < 0 || chapterIndex >= ctrl.hadithModelFinal.length) {
          return const AppScaffold(
            title: 'الحديث الشريف',
            body: EmptyState(
              title: 'لم يتم العثور على الباب',
              message: 'يرجى العودة واختيار الباب مجدداً',
            ),
          );
        }

        final chapter = ctrl.hadithModelFinal[chapterIndex];
        final chapterName =
            chapter.data?.metadata?.section?.name ?? 'الحديث الشريف';
        final hadiths = chapter.data?.hadiths ?? [];

        return AppScaffold(
          title: chapterName,
          constrainContentWidth: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_rounded),
              color: colors.accent,
              tooltip: 'الانتقال للموضع المحفوظ',
              onPressed: () => ctrl.goToPage(),
            ),
          ],
          body: hadiths.isEmpty
              ? const EmptyState(
                  title: 'لا توجد أحاديث في هذا الباب',
                  message: 'قريباً سيتم إضافة المزيد من الأحاديث',
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    child: PageView.builder(
                      controller: ctrl.pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: hadiths.length,
                      itemBuilder: (context, index) {
                        return HadithCard(
                          model: hadiths[index],
                          controller: ctrl,
                          itemIndex: index,
                          totalItems: hadiths.length,
                          chapterName: chapterName,
                        );
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }
}
