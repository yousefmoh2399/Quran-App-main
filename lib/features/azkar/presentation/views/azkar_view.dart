import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/design/components/loading_skeleton.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/azkar/presentation/view_model/azkar_view_model.dart';

class AzkarView extends StatelessWidget {
  const AzkarView({super.key});

  String _getAzkar3DIcon(String category) {
    if (category.contains('صباح') || category.contains('مساء')) {
      return 'assets/images/icon_3d_lantern.png';
    }
    if (category.contains('صلاة') || category.contains('أذان') || category.contains('مسجد') || category.contains('وضوء')) {
      return 'assets/images/icon_3d_prayer_clock.png';
    }
    if (category.contains('سفر') || category.contains('ركوب') || category.contains('دابة')) {
      return 'assets/images/icon_3d_travel.png';
    }
    if (category.contains('قرآن')) {
      return 'assets/images/icon_3d_quran.png';
    }
    if (category.contains('تسبيح') || category.contains('استغفار')) {
      return 'assets/images/icon_3d_tasbeeh.png';
    }
    return 'assets/images/icon_3d_praying_hands.png';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final settings = Get.find<SettingsServices>();

    final azkarController = Get.isRegistered<AzkarViewModel>()
        ? Get.find<AzkarViewModel>()
        : Get.put(AzkarViewModel());

    return AppScaffold(
      title: 'حصن المسلم والأذكار',
      constrainContentWidth: true,
      body: GetBuilder<AzkarViewModel>(
        init: azkarController,
        builder: (controller) {
          if (controller.isLoading) {
            return ListView.separated(
              padding: AppSpacing.screen,
              itemCount: 8,
              separatorBuilder: (_, __) => AppSpacing.verticalMd,
              itemBuilder: (_, __) => const LoadingSkeleton(
                width: double.infinity,
                height: 72,
                borderRadius: AppRadius.borderMd,
              ),
            );
          }

          final list = controller.filteredAzkar;

          return Column(
            children: [
              // Search Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  onChanged: (val) => controller.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'ابحث في أبواب الأذكار والأدعية...',
                    prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                    suffixIcon: controller.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => controller.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        title: 'لا توجد أذكار مطابقة',
                        message: 'حاول البحث بكلمة أخرى',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: AppSpacing.xl,
                          top: AppSpacing.xs,
                        ),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => AppSpacing.verticalSm,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final originalIndex = controller.azkarModel.indexOf(item);
                          final count = item.array.length;

                          return AppCard(
                            variant: AppCardVariant.elevated,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            onTap: () {
                              settings.sharedPref!.setInt(
                                'indexAzkar',
                                originalIndex >= 0 ? originalIndex : index,
                              );
                              Get.toNamed(AppRoutes.azkarDetails);
                            },
                            child: Row(
                              children: [
                                // 3D Category Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    _getAzkar3DIcon(item.category ?? ''),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.spa_rounded,
                                      color: colors.primary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                AppSpacing.horizontalMd,
                                // Category name and details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.category ?? '',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colors.text,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      AppSpacing.verticalXs,
                                      Text(
                                        '$count ذكر ودعاء',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSpacing.horizontalSm,
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                AppSpacing.horizontalSm,
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: colors.textMuted.withOpacity(0.6),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
