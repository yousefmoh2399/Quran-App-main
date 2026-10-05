import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/util/widgets/islamic_quote_card_generator_view.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_bookmark_model.dart';
import 'package:quran_app_android/features/bookmarks/presentation/controllers/bookmarks_controller.dart';

class HadithBookmarksTab extends StatelessWidget {
  final BookmarksController controller;

  const HadithBookmarksTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Obx(() {
      final list = controller.hadithBookmarks;

      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 48.0,
                  color: colors.primary,
                ),
              ),
              AppSpacing.verticalMd,
              Text(
                'لا توجد أحاديث محفوظة بعد',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              AppSpacing.verticalXs,
              Text(
                'يمكنك حفظ أو تحديد الأحاديث التي تحفظها من قسم الأحاديث النبوية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 13.0,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: AppSpacing.screen,
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return _buildHadithItem(context, item, colors);
        },
      );
    });
  }

  Widget _buildHadithItem(
    BuildContext context,
    HadithBookmarkModel item,
    AppColorsExtension colors,
  ) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Category, Status & Delete
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5C4A).withOpacity(0.12),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 14.0, color: Color(0xFF0F5C4A)),
                    const SizedBox(width: 4.0),
                    Text(
                      '${item.chapterName} • حديث ${item.hadithNumber}',
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F5C4A),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Memorization Status Chip / Toggle
              InkWell(
                onTap: () => controller.toggleHadithMemorized(item.id),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: item.isMemorized
                        ? const Color(0xFFD4AF37).withOpacity(0.15)
                        : colors.textMuted.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isMemorized
                          ? const Color(0xFFD4AF37)
                          : colors.divider,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.isMemorized
                            ? Icons.stars_rounded
                            : Icons.star_border_rounded,
                        size: 14.0,
                        color: item.isMemorized
                            ? const Color(0xFFD4AF37)
                            : colors.textMuted,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        item.isMemorized ? 'تم الحفظ ⭐' : 'قيد الحفظ',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: item.isMemorized
                              ? const Color(0xFFD4AF37)
                              : colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              // Delete Button
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18.0, color: colors.error),
                tooltip: 'إزالة من المحفوظات',
                onPressed: () => controller.deleteHadithBookmark(item.id),
              ),
            ],
          ),

          AppSpacing.verticalSm,

          // Hadith Text
          Text(
            '«${item.text}»',
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.hadithFont,
              fontSize: 15.0,
              height: 1.8,
              color: colors.text,
            ),
          ),

          AppSpacing.verticalSm,
          Divider(color: colors.divider, height: 1.0),
          AppSpacing.verticalXs,

          // Bottom Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.source,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 11.5,
                  color: colors.textMuted,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Copy
                  IconButton(
                    icon: Icon(Icons.copy_rounded,
                        size: 17.0, color: colors.primary),
                    tooltip: 'نسخ',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${item.chapterName}\n${item.text}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('تم نسخ الحديث بنجاح'),
                          backgroundColor: colors.primary,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  // Share as image card
                  TextButton.icon(
                    onPressed: () {
                      Get.to(() => IslamicQuoteCardGeneratorView(
                            quoteText: item.text,
                            categoryTitle: 'حديث نبوي شريف',
                            source: '${item.chapterName} • ${item.source}',
                            itemNumber: 'حديث رقم ${item.hadithNumber}',
                          ));
                    },
                    icon: const Icon(Icons.palette_outlined,
                        size: 16.0, color: Color(0xFF0F5C4A)),
                    label: const Text(
                      'مشاركة كصورة',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F5C4A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
