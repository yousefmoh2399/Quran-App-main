import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../data/models/special_prayer_model.dart';
import '../controllers/special_prayers_controller.dart';

class SpecialPrayersView extends StatefulWidget {
  const SpecialPrayersView({super.key});

  @override
  State<SpecialPrayersView> createState() => _SpecialPrayersViewState();
}

class _SpecialPrayersViewState extends State<SpecialPrayersView> {
  late final SpecialPrayersController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SpecialPrayersController>()
        ? Get.find<SpecialPrayersController>()
        : Get.put(SpecialPrayersController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyDua(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الدعاء إلى الحافظة بنجاح'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'دليل الصلوات الخاصة خطوة بخطوة',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildSearchBar(colors),
            _buildCategoryFilters(colors),
            const SizedBox(height: 6),
            Expanded(
              child: Obx(() {
                final prayers = _controller.filteredPrayers;
                if (prayers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'لا توجد صلوات مطابقة للبحث أو التصنيف',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: prayers.length,
                  itemBuilder: (context, index) {
                    final prayer = prayers[index];
                    return _buildPrayerCard(prayer, colors);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.divider.withOpacity(0.3)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _controller.setSearchQuery,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 13,
            color: colors.text,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن صلاة، خطوة، أو دعاء مأثور...',
            hintStyle: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.5,
              color: colors.textSecondary.withOpacity(0.8),
            ),
            prefixIcon: Icon(Icons.search_rounded, size: 19, color: colors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _controller.setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(dynamic colors) {
    final categories = [
      null,
      SpecialPrayerCategory.occasional,
      SpecialPrayerCategory.personal,
      SpecialPrayerCategory.sujood,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Obx(() {
        final selected = _controller.selectedCategory.value;
        return Row(
          children: categories.map((cat) {
            final isSelected = selected == cat;
            final label = cat == null ? 'كافة الصلوات' : cat.displayName;

            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: () => _controller.setCategory(cat),
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withOpacity(0.15) : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.divider.withOpacity(0.3),
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildPrayerCard(SpecialPrayer prayer, dynamic colors) {
    return Obx(() {
      final isExpanded = _controller.expandedPrayerIds.contains(prayer.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.divider.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _controller.toggleExpanded(prayer.id),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.primary.withOpacity(0.12),
                        child: Icon(prayer.icon, size: 18, color: colors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayer.title,
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                              ),
                            ),
                            Text(
                              prayer.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 11.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: colors.textSecondary.withOpacity(0.6),
                      ),
                    ],
                  ),

                  // Definition & Virtue Preview
                  const SizedBox(height: 10),
                  Text(
                    prayer.definitionAndVirtue,
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // Expanded Detailed Content
                  if (isExpanded) ...[
                    // Conditions & Rulings
                    if (prayer.conditionsAndRulings.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: colors.divider.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 15, color: colors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'أحكام وشروط هامة:',
                                  style: TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...prayer.conditionsAndRulings.map((cond) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold, color: colors.primary)),
                                      Expanded(
                                        child: Text(
                                          cond,
                                          style: TextStyle(
                                            fontFamily: AppTypography.uiFont,
                                            fontSize: 12,
                                            color: colors.text,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],

                    // Step-by-Step Walkthrough
                    const SizedBox(height: 14),
                    Text(
                      'خطوات الصلاة العملية بالتفصيل:',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...prayer.steps.map((step) => _buildStepItem(step, colors)),

                    // Common Mistakes
                    if (prayer.commonMistakes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, size: 15, color: Colors.orange),
                                SizedBox(width: 6),
                                Text(
                                  'تنبيهات وأخطاء شائعة:',
                                  style: TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...prayer.commonMistakes.map((mistake) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    '⚠ $mistake',
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 11.5,
                                      color: colors.text,
                                      height: 1.4,
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStepItem(PrayerStep step, dynamic colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.divider.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: const TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step.description,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          if (step.detailedDua != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'النص أو الدعاء المأثور:',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFFD4AF37)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'نسخ الدعاء',
                        onPressed: () => _copyDua(step.detailedDua!, context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.detailedDua!,
                    style: TextStyle(
                      fontFamily: AppTypography.quranFont,
                      fontSize: 13.5,
                      color: colors.text,
                      height: 1.6,
                    ),
                  ),
                  if (step.reference != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.reference!,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 10,
                        color: colors.textSecondary.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
