import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../../../core/util/share_helper.dart';
import '../../../card_studio/presentation/views/card_studio_view.dart';
import '../../../mushaf/presentation/utils/mushaf_utils.dart';
import '../controllers/traveler_companion_controller.dart';
import '../../data/models/travel_dua_model.dart';

class TravelDuasTab extends StatelessWidget {
  final TravelerCompanionController controller;

  const TravelDuasTab({super.key, required this.controller});

  void _copyDua(BuildContext context, TravelDuaModel dua) {
    AppHaptics.selection();
    final text = '﴿ ${dua.arabicText} ﴾\n[${dua.title} - ${dua.reference}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ الذكر إلى الحافظة'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareDua(BuildContext context, TravelDuaModel dua) {
    AppHaptics.selection();
    final shareContent = '${dua.title}\n\n«${dua.arabicText}»\n\nالمصدر: ${dua.reference}\n— تطبيق رفيق المسافر';
    Share.share(shareContent, sharePositionOrigin: getSharePositionOrigin(context));
  }

  void _openInCardStudio(TravelDuaModel dua) {
    AppHaptics.selection();
    Get.to(() => CardStudioView(
          initialText: dua.arabicText,
          initialSurahName: dua.title,
          initialTafsir: dua.virtue,
          initialSource: dua.reference,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Obx(() {
      final selectedCat = controller.selectedDuaCategory.value;
      final duas = controller.filteredDuas;

      return Column(
        children: [
          // Filter Chips Horizontal Bar
          Container(
            color: colors.surface,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildCategoryFilterChip(
                    label: 'الكل',
                    isSelected: selectedCat == null,
                    onTap: () => controller.setDuaCategory(null),
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  ...TravelDuaCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildCategoryFilterChip(
                        label: cat.titleAr,
                        isSelected: selectedCat == cat,
                        onTap: () => controller.setDuaCategory(cat),
                        colors: colors,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Duas List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              physics: const BouncingScrollPhysics(),
              itemCount: duas.length,
              itemBuilder: (context, index) {
                return _buildDuaCard(context, duas[index], colors);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.bg,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider.withValues(alpha: 0.7),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 12.0,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : colors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildDuaCard(
    BuildContext context,
    TravelDuaModel dua,
    AppColorsExtension colors,
  ) {
    return Obx(() {
      final currentCount = controller.getDuaCount(dua.id);
      final isDone = currentCount >= dua.targetCount;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: AppCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Category Badge & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      dua.category.titleAr,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      dua.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),

              // Arabic Text Container
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
                ),
                child: Text(
                  dua.arabicText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                    height: 1.85,
                  ),
                ),
              ),

              const SizedBox(height: 10.0),

              // Reference & Virtue
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 14, color: colors.accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dua.reference,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.0,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),

              if (dua.virtue != null) ...[
                const SizedBox(height: 6.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 14, color: colors.accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          dua.virtue!,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 11.0,
                            color: colors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 18.0),

              // Actions & Counter Row
              Row(
                children: [
                  // 1. Copy
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: colors.textMuted,
                    tooltip: 'نسخ',
                    onPressed: () => _copyDua(context, dua),
                  ),
                  // 2. Share Text
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    color: colors.textMuted,
                    tooltip: 'مشاركة نص',
                    onPressed: () => _shareDua(context, dua),
                  ),
                  // 3. Card Studio
                  IconButton(
                    icon: const Icon(Icons.palette_outlined, size: 18),
                    color: colors.accent,
                    tooltip: 'تصميم بطاقة',
                    onPressed: () => _openInCardStudio(dua),
                  ),

                  const Spacer(),

                  // Counter Button
                  InkWell(
                    onTap: () => controller.incrementDua(dua.id, dua.targetCount),
                    borderRadius: BorderRadius.circular(12.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: isDone
                            ? colors.primary.withValues(alpha: 0.15)
                            : colors.bg,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isDone ? colors.primary : colors.divider,
                          width: isDone ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDone ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
                            size: 16,
                            color: isDone ? colors.primary : colors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dua.targetCount > 1
                                ? '${toArabicDigits(currentCount)} / ${toArabicDigits(dua.targetCount)}'
                                : (isDone ? 'تم القراءة' : 'قراءة'),
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: isDone ? colors.primary : colors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
