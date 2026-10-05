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
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/hadith/presentation/view_model/hadith_view_model.dart';

class SectionHadithView extends StatelessWidget {
  const SectionHadithView({super.key});

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
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
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
                        'الأحاديث المحفوظة 🔖',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withOpacity(0.15),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          '${bookmarks.length} محفوظ',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.bold,
                          ),
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
                              message:
                                  'اضغط على زر "حفظ" في أي حديث لحفظه هنا للرجوع إليه لاحقاً',
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
                                      padding:
                                          const EdgeInsets.all(AppSpacing.xs),
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
                                            style:
                                                textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.primary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          AppSpacing.verticalXs,
                                          Text(
                                            'حديث رقم ${item.hadithNumber}: ${item.text.replaceAll('\n', ' ')}',
                                            style:
                                                textTheme.bodySmall?.copyWith(
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
                                              .hadithModelFinal[
                                                  item.chapterIndex]
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
    final textTheme = Theme.of(context).textTheme;
    final settings = Get.find<SettingsServices>();

    final controller = Get.isRegistered<HadithViewModel>()
        ? Get.find<HadithViewModel>()
        : Get.put(HadithViewModel());

    return AppScaffold(
      title: 'موطأ الإمام مالك',
      constrainContentWidth: true,
      actions: [
        GetBuilder<HadithViewModel>(
          builder: (ctrl) => IconButton(
            icon: Badge(
              isLabelVisible: ctrl.bookmarks.isNotEmpty,
              label: Text('${ctrl.bookmarks.length}'),
              backgroundColor: colors.accent,
              child: const Icon(Icons.bookmarks_rounded),
            ),
            tooltip: 'المحفوظات',
            onPressed: () => _showBookmarksSheet(context, ctrl),
          ),
        ),
      ],
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
                    prefixIcon:
                        Icon(Icons.search_rounded, color: colors.primary),
                    suffixIcon: ctrl.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => ctrl.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
              ),

              // Last Read Resume Card (only shown when not filtering or query is empty)
              if (ctrl.hasLastRead && ctrl.searchQuery.trim().isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withOpacity(0.12),
                          colors.accent.withOpacity(0.08),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(
                        color: colors.primary.withOpacity(0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: AppRadius.borderMd,
                        onTap: () => ctrl.resumeLastRead(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm + 2,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.15),
                                  borderRadius: AppRadius.borderSm,
                                ),
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: colors.primary,
                                  size: 22,
                                ),
                              ),
                              AppSpacing.horizontalMd,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            borderRadius: AppRadius.borderSm,
                                          ),
                                          child: Text(
                                            'آخر قراءة 📍',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        AppSpacing.horizontalXs,
                                        Flexible(
                                          child: Text(
                                            ctrl.lastReadChapterName ?? '',
                                            style: textTheme.labelMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.text,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    AppSpacing.verticalXs,
                                    Text(
                                      'حديث ${(ctrl.lastReadHadithNumber ?? 1)}: ${ctrl.lastReadSnippet ?? ""}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.textMuted,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.horizontalSm,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: AppRadius.borderSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'متابعة',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.verticalXs,
              ],

              // Chapters List
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
                          final chapterIdx =
                              originalIndex >= 0 ? originalIndex : index;
                          final sectionName = chapter
                                  .data?.metadata?.section?.name ??
                              'باب الحديث';
                          final hadithCount =
                              chapter.data?.hadiths.length ?? 0;
                          final bookmarkCount =
                              ctrl.getChapterBookmarkCount(chapterIdx);
                          final isLastReadChapter =
                              ctrl.hasLastRead &&
                              ctrl.lastReadChapterIndex == chapterIdx;

                          return AppCard(
                            variant: isLastReadChapter
                                ? AppCardVariant.elevated
                                : AppCardVariant.flat,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            onTap: () {
                              AppHaptics.selection();
                              settings.sharedPref!.setInt(
                                'indexHadith',
                                chapterIdx,
                              );
                              // If this is the last read chapter, jump to the last read hadith
                              if (isLastReadChapter &&
                                  ctrl.lastReadItemIndex != null) {
                                settings.sharedPref!.setInt(
                                  'saveIndex',
                                  ctrl.lastReadItemIndex!,
                                );
                              } else {
                                settings.sharedPref!.setInt('saveIndex', 0);
                              }
                              Get.toNamed(AppRoutes.hadith);
                            },
                            child: Row(
                              children: [
                                // Chapter Number Badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isLastReadChapter
                                        ? colors.primary.withOpacity(0.18)
                                        : colors.primary.withOpacity(0.08),
                                    borderRadius: AppRadius.borderMd,
                                    border: Border.all(
                                      color: isLastReadChapter
                                          ? colors.primary
                                          : colors.primary.withOpacity(0.2),
                                      width: isLastReadChapter ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${chapterIdx + 1}',
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sectionName,
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colors.text,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isLastReadChapter) ...[
                                            AppSpacing.horizontalXs,
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.xs,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colors.primary,
                                                borderRadius:
                                                    AppRadius.borderSm,
                                              ),
                                              child: Text(
                                                'آخر قراءة 📍',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
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
                                          if (bookmarkCount > 0) ...[
                                            AppSpacing.horizontalSm,
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colors.accent
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    AppRadius.borderSm,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.bookmark_rounded,
                                                    size: 11,
                                                    color: colors.accent,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '$bookmarkCount محفوظ',
                                                    style: textTheme.labelSmall
                                                        ?.copyWith(
                                                      color: colors.accent,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
