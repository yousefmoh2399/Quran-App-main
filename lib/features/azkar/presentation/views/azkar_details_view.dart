import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/azkar/presentation/view_model/azkar_view_model.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widget/azkar_item_card.dart';

class DetailesAzkarView extends StatelessWidget {
  const DetailesAzkarView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsServices>();
    final index = settings.sharedPref?.getInt('indexAzkar') ?? 0;

    return GetBuilder<AzkarViewModel>(
      builder: (ctrl) {
        if (index < 0 || index >= ctrl.azkarModel.length) {
          return const AppScaffold(
            title: 'الأذكار',
            body: EmptyState(
              title: 'لم يتم العثور على الأذكار',
              message: 'يرجى العودة واختيار الباب مجدداً',
            ),
          );
        }

        final categoryModel = ctrl.azkarModel[index];
        final azkarList = categoryModel.array;

        return AppScaffold(
          title: categoryModel.category ?? 'الأذكار',
          constrainContentWidth: true,
          body: azkarList.isEmpty
              ? const EmptyState(
                  title: 'لا توجد أذكار في هذا الباب',
                  message: 'قريباً سيتم إضافة المزيد من الأدعية',
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    child: PageView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: azkarList.length,
                      itemBuilder: (context, itemIndex) {
                        return AzkarItemCard(
                          model: azkarList[itemIndex],
                          controller: ctrl,
                          itemIndex: itemIndex,
                          totalItems: azkarList.length,
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
