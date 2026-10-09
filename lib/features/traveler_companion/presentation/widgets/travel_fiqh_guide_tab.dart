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
import '../controllers/traveler_companion_controller.dart';
import '../../data/models/travel_rule_model.dart';

class TravelFiqhGuideTab extends StatefulWidget {
  final TravelerCompanionController controller;

  const TravelFiqhGuideTab({super.key, required this.controller});

  @override
  State<TravelFiqhGuideTab> createState() => _TravelFiqhGuideTabState();
}

class _TravelFiqhGuideTabState extends State<TravelFiqhGuideTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _shareRule(BuildContext context, TravelRuleModel rule) {
    AppHaptics.selection();
    final buffer = StringBuffer()
      ..writeln('📜 مسألة فقهية: ${rule.title}')
      ..writeln('الخلاصة: ${rule.summary}')
      ..writeln()
      ..writeln('الضابط العملي: ${rule.practicalRule}');

    if (rule.dalil != null && rule.dalil!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('الدليل: ${rule.dalil}');
    }

    buffer.writeln('\n— من تطبيق رفيق المسافر ورخص السفر');
    Share.share(buffer.toString(), sharePositionOrigin: getSharePositionOrigin(context));
  }

  void _copyRule(BuildContext context, TravelRuleModel rule) {
    AppHaptics.selection();
    final text = '${rule.title}\n${rule.summary}\nالضابط: ${rule.practicalRule}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ المسألة الفقهية'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Obx(() {
      final selectedCat = widget.controller.selectedRuleCategory.value;
      var rules = widget.controller.filteredRules;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        rules = rules.where((r) {
          return r.title.toLowerCase().contains(q) ||
              r.summary.toLowerCase().contains(q) ||
              r.practicalRule.toLowerCase().contains(q) ||
              (r.dalil?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      return Column(
        children: [
          // Filter Categories Horizontal Bar
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
                    onTap: () => widget.controller.setRuleCategory(null),
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  ...TravelRuleCategory.values.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildCategoryFilterChip(
                        label: cat.titleAr,
                        isSelected: selectedCat == cat,
                        onTap: () => widget.controller.setRuleCategory(cat),
                        colors: colors,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                color: colors.text,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث في مسائل الجمع والقصر والسنن...',
                hintStyle: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  color: colors.textMuted.withValues(alpha: 0.7),
                  fontSize: 13.0,
                ),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: colors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(color: colors.divider.withValues(alpha: 0.6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(color: colors.divider.withValues(alpha: 0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderMd,
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Rules List
          Expanded(
            child: rules.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد مسائل مطابقة لبحثك',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: colors.textMuted,
                        fontSize: 14.0,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      return _buildRuleCard(context, rules[index], colors);
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

  Widget _buildRuleCard(
    BuildContext context,
    TravelRuleModel rule,
    AppColorsExtension colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Badge & Actions Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    rule.category.titleAr,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  color: colors.textMuted,
                  tooltip: 'نسخ',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _copyRule(context, rule),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 17),
                  color: colors.textMuted,
                  tooltip: 'مشاركة',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _shareRule(context, rule),
                ),
              ],
            ),

            const SizedBox(height: 8.0),

            // Title
            Text(
              rule.title,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),

            const SizedBox(height: 6.0),

            // Summary
            Text(
              rule.summary,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: colors.text,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 10.0),

            // Practical Rule Box
            Container(
              padding: const EdgeInsets.all(11.0),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 17, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الضابط العملي:',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rule.practicalRule,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 12.0,
                            color: colors.text,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (rule.dalil != null && rule.dalil!.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 15, color: colors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'الدليل: ${rule.dalil!}',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: colors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (rule.scholarlyNotes != null && rule.scholarlyNotes!.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: colors.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      rule.scholarlyNotes!,
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
            ],
          ],
        ),
      ),
    );
  }
}
