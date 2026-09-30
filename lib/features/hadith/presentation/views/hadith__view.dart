// ignore_for_file: file_names
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
import 'package:quran_app_android/features/hadith/presentation/view_model/hadith_view_model.dart';

class SectionHadithView extends StatelessWidget {
  const SectionHadithView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final settings = Get.find<SettingsServices>();

    final controller = Get.isRegistered<HadithViewModel>()
        ? Get.find<HadithViewModel>()
        : Get.put(HadithViewModel());

    return AppScaffold(
      title: 'موطأ الإمام مالك',
      constrainContentWidth: true,
      body: GetBuilder<HadithViewModel>(
        init: controller,
        builder: (ctrl) {
          if (ctrl.isLoading) {
            return ListView.separated(
              padding: AppSpacing.screen,
              itemCount: 8,
              separatorBuilder: (_, __) => AppSpacing.verticalMd,
              itemBuilder: (_, __) => const LoadingSkeleton(
                width: double.infinity,
                height: 76,
                borderRadius: AppRadius.borderMd,
              ),
            );
          }

          final chapters = ctrl.filteredChapters;

          return Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  onChanged: (val) => ctrl.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'ابحث في أبواب موطأ مالك...',
                    prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                    suffixIcon: ctrl.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => ctrl.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: chapters.isEmpty
                    ? const EmptyState(
                        title: 'لا توجد أبواب مطابقة',
                        message: 'جرب البحث بكلمة أو باب آخر',
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
                        itemCount: chapters.length,
                        separatorBuilder: (_, __) => AppSpacing.verticalSm,
                        itemBuilder: (context, index) {
                          final chapter = chapters[index];
                          final originalIndex =
                              ctrl.hadithModelFinal.indexOf(chapter);
                          final sectionName = chapter
                                  .data?.metadata?.section?.name ??
                              'باب الحديث';
                          final hadithCount =
                              chapter.data?.hadiths.length ?? 0;

                          return AppCard(
                            variant: AppCardVariant.elevated,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            onTap: () {
                              settings.sharedPref!.setInt(
                                'indexHadith',
                                originalIndex >= 0 ? originalIndex : index,
                              );
                              Get.toNamed(AppRoutes.hadith);
                            },
                            child: Row(
                              children: [
                                // Chapter Number Badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.1),
                                    borderRadius: AppRadius.borderMd,
                                    border: Border.all(
                                      color: colors.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${(originalIndex >= 0 ? originalIndex : index) + 1}',
                                      style: textTheme.labelMedium?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                AppSpacing.horizontalMd,
                                // Chapter details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        sectionName,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colors.text,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      AppSpacing.verticalXs,
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_stories_rounded,
                                            size: 13,
                                            color: colors.accent,
                                          ),
                                          AppSpacing.horizontalXs,
                                          Text(
                                            '$hadithCount حديثاً',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: colors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
