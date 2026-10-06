import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/hadith/presentation/view_model/hadith_view_model.dart';
import 'package:quran_app_android/features/hadith/presentation/views/widget/hadith_card.dart';

class HadithView extends StatefulWidget {
  const HadithView({super.key});

  @override
  State<HadithView> createState() => _HadithViewState();
}

class _HadithViewState extends State<HadithView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = Get.find<HadithViewModel>();
      final settings = Get.find<SettingsServices>();
      final chIdx = settings.sharedPref?.getInt('indexHadith') ?? 0;
      final savedIdx = settings.sharedPref?.getInt('saveIndex') ?? 0;

      if (chIdx >= 0 && chIdx < ctrl.hadithModelFinal.length) {
        final hadiths = ctrl.hadithModelFinal[chIdx].data?.hadiths ?? [];
        if (hadiths.isNotEmpty) {
          final targetIdx = savedIdx.clamp(0, hadiths.length - 1);
          ctrl.saveLastRead(
            chapterIndex: chIdx,
            chapterName: ctrl.hadithModelFinal[chIdx].data?.metadata?.section?.name ?? '',
            itemIndex: targetIdx,
            hadith: hadiths[targetIdx],
          );
        }
      }
    });
  }

  void _showBookmarksSheet(BuildContext context, HadithViewModel ctrl) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.radiusLg),
      ),
      builder: (ctx) {
        final bookmarks = ctrl.bookmarks;
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  AppSpacing.verticalMd,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأحاديث المحفوظة',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        '${bookmarks.length} محفوظ',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalMd,
                  Expanded(
                    child: bookmarks.isEmpty
                        ? const Center(
                            child: EmptyState(
                              title: 'لا توجد أحاديث محفوظة',
                              message: 'اضغط على زر "حفظ" في أي حديث لحفظه هنا للرجوع إليه لاحقاً',
                              icon: Icons.bookmark_border_rounded,
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: bookmarks.length,
                            separatorBuilder: (_, __) => AppSpacing.verticalSm,
                            itemBuilder: (context, index) {
                              final item = bookmarks[index];
                              return AppCard(
                                variant: AppCardVariant.outlined,
                                padding: AppSpacing.paddingMd,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  ctrl.openChapterAtHadith(
                                    item.chapterIndex,
                                    item.itemIndex,
                                  );
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: colors.primary.withOpacity(0.1),
                                        borderRadius: AppRadius.borderSm,
                                      ),
                                      child: Icon(
                                        Icons.bookmark_rounded,
                                        size: 20,
                                        color: colors.accent,
                                      ),
                                    ),
                                    AppSpacing.horizontalMd,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.chapterName,
                                            style: textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.primary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          AppSpacing.verticalXs,
                                          Text(
                                            'حديث رقم ${item.hadithNumber}: ${item.text.replaceAll('\n', ' ')}',
                                            style: textTheme.bodySmall?.copyWith(
                                              color: colors.textMuted,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                      ),
                                      color: colors.textMuted,
                                      onPressed: () {
                                        ctrl.toggleBookmark(
                                          chapterIndex: item.chapterIndex,
                                          chapterName: item.chapterName,
                                          itemIndex: item.itemIndex,
                                          hadith: ctrl
                                              .hadithModelFinal[item.chapterIndex]
                                              .data!
                                              .hadiths[item.itemIndex],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
              icon: const Icon(Icons.bookmarks_rounded),
              color: colors.accent,
              tooltip: 'المحفوظات',
              onPressed: () => _showBookmarksSheet(context, ctrl),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_added_rounded),
              color: colors.primary,
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
                      onPageChanged: (index) {
                        ctrl.changeIndex(index);
                        ctrl.saveLastRead(
                          chapterIndex: chapterIndex,
                          chapterName: chapterName,
                          itemIndex: index,
                          hadith: hadiths[index],
                        );
                      },
                      itemBuilder: (context, index) {
                        return HadithCard(
                          model: hadiths[index],
                          controller: ctrl,
                          itemIndex: index,
                          totalItems: hadiths.length,
                          chapterName: chapterName,
                          chapterIndex: chapterIndex,
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
