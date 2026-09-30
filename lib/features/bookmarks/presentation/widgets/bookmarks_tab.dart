import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../mushaf/presentation/utils/mushaf_utils.dart';
import '../controllers/bookmarks_controller.dart';

class BookmarksTab extends StatelessWidget {
  final BookmarksController controller;

  const BookmarksTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: TextField(
            onChanged: controller.onSearchChanged,
            style: TextStyle(fontFamily: AppTypography.uiFont, color: colors.text),
            decoration: InputDecoration(
              hintText: 'ابحث بالسورة أو رقم الصفحة أو الملاحظة...',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 13.5),
              prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: colors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: colors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
        ),

        // Bookmarks list
        Expanded(
          child: Obx(() {
            final items = controller.filteredBookmarks;

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border_rounded, size: 56.0, color: colors.textMuted.withOpacity(0.5)),
                    AppSpacing.verticalSm,
                    Text(
                      controller.searchQuery.value.isNotEmpty
                          ? 'لا توجد علامات مطابقة للبحث'
                          : 'لم تقم بحفظ أي علامات مرجعية بعد',
                      style: textTheme.bodyLarge?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => AppSpacing.verticalSm,
              itemBuilder: (context, index) {
                final item = items[index];
                final isAyah = item.type == BookmarkType.ayah;
                final surahName = controller.getSurahName(item.surah);

                return Dismissible(
                  key: ValueKey('bm_${item.id}_${item.page}_${item.ayah}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20.0),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28.0),
                  ),
                  onDismissed: (_) {
                    controller.deleteBookmark(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'تمت إزالة العلامة المرجعية',
                          style: TextStyle(fontFamily: AppTypography.uiFont),
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: InkWell(
                    borderRadius: AppRadius.borderMd,
                    onTap: () {
                      controller.openMushaf(
                        page: item.page,
                        surah: item.surah,
                        ayah: item.ayah,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: colors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            // Color Ribbon Strip
                            Container(
                              width: 6.0,
                              decoration: BoxDecoration(
                                color: item.color.color,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12.0),
                                  bottomRight: Radius.circular(12.0),
                                ),
                              ),
                            ),
                            AppSpacing.horizontalMd,

                            // Content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                          decoration: BoxDecoration(
                                            color: item.color.color.withOpacity(0.12),
                                            borderRadius: AppRadius.borderSm,
                                          ),
                                          child: Text(
                                            isAyah ? 'آية' : 'صفحة',
                                            style: TextStyle(
                                              fontFamily: AppTypography.uiFont,
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.bold,
                                              color: item.color.color,
                                            ),
                                          ),
                                        ),
                                        AppSpacing.horizontalSm,
                                        Expanded(
                                          child: Text(
                                            isAyah
                                                ? 'سورة $surahName  •  آية ${toArabicDigits(item.ayah ?? 1)}'
                                                : 'صفحة ${toArabicDigits(item.page)} ${surahName.isNotEmpty ? " •  سورة $surahName" : ""}',
                                            style: textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.text,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'صـ ${toArabicDigits(item.page)}',
                                          style: TextStyle(
                                            fontFamily: AppTypography.uiFont,
                                            fontSize: 12.0,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (item.note != null && item.note!.trim().isNotEmpty) ...[
                                      AppSpacing.verticalXs,
                                      Text(
                                        item.note!,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.textMuted,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],

                                    AppSpacing.verticalXs,
                                    Text(
                                      _formatDate(item.createdAt),
                                      style: TextStyle(
                                        fontFamily: AppTypography.uiFont,
                                        fontSize: 10.5,
                                        color: colors.textMuted.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16.0),
                              color: colors.textMuted,
                              onPressed: () {
                                controller.openMushaf(
                                  page: item.page,
                                  surah: item.surah,
                                  ayah: item.ayah,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${toArabicDigits(dt.year)}/${toArabicDigits(dt.month)}/${toArabicDigits(dt.day)}';
  }
}
