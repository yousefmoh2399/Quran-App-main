import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/data/models/surah_entity.dart';
import '../controllers/hifz_tester_controller.dart';
import '../../data/models/hifz_test_models.dart';

class HifzSetupView extends StatelessWidget {
  final HifzTesterController controller;

  const HifzSetupView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          _buildHeroHeader(context, colors),
          const SizedBox(height: 20),

          // Test Mode Selector
          _buildSectionTitle(context, '١. نمط الاختبار', Icons.tune_rounded, colors),
          const SizedBox(height: 10),
          _buildModeSelector(context, colors),
          const SizedBox(height: 20),

          // Scope Selector
          _buildSectionTitle(context, '٢. نطاق الاختبار', Icons.menu_book_rounded, colors),
          const SizedBox(height: 10),
          _buildScopeSelector(context, colors),
          const SizedBox(height: 20),

          // Difficulty & Count
          _buildSectionTitle(context, '٣. الصعوبة وعدد الأسئلة', Icons.speed_rounded, colors),
          const SizedBox(height: 10),
          _buildDifficultyAndCount(context, colors),
          const SizedBox(height: 24),

          // Start Button
          Obx(() {
            final loading = controller.isLoading.value;
            return SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: loading ? null : controller.startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  elevation: 2,
                ),
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 26),
                label: Text(
                  loading ? 'جاري إعداد الأسئلة...' : 'ابدأ اختبار الحفظ الآن',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          // Shortcut to Mutashabihat Guide
          OutlinedButton.icon(
            onPressed: controller.openMutashabihatGuide,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.accent, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: Icon(Icons.auto_stories_rounded, color: colors.accent),
            label: Text(
              'تصفح دليل وضوابط المتشابهات اللفظية',
              style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, AppColorsExtension colors) {
    final isDark = colors.isDark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A2F), const Color(0xFF14241E)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              size: 32,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختبار وتثبيت الحفظ القرآني',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أداة متقدمة مخصصة للحفاظ والكتاتيب لاختبار ثبات الآيات، إكمال الفراغات، وضبط المتشابهات بدون إنترنت.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon, AppColorsExtension colors) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(BuildContext context, AppColorsExtension colors) {
    return Obx(() {
      final currentMode = controller.selectedMode.value;
      return Column(
        children: HifzTestMode.values.map((mode) {
          final isSelected = currentMode == mode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => controller.setMode(mode),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.1)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? colors.primary
                        : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : Colors.grey.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        mode.icon,
                        size: 20,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode.titleAr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? colors.primary : null,
                            ),
                          ),
                          Text(
                            mode.descriptionAr,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildScopeSelector(BuildContext context, AppColorsExtension colors) {
    return Obx(() {
      final currentScope = controller.selectedScope.value;
      final mode = controller.selectedMode.value;

      if (mode == HifzTestMode.mutashabihat) {
        return AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: colors.accent),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'يتم سحب الأسئلة تلقائياً من بنك المتشابهات اللفظية المعتمد.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Row(
            children: [
              _buildScopeTab(context, HifzScopeType.singleSurah, 'سورة محددة', Icons.bookmark_border_rounded, colors),
              const SizedBox(width: 8),
              _buildScopeTab(context, HifzScopeType.juz, 'جزء محدد', Icons.format_list_numbered_rounded, colors),
              const SizedBox(width: 8),
              _buildScopeTab(context, HifzScopeType.entireQuran, 'المصحف كاملاً', Icons.public_rounded, colors),
            ],
          ),
          const SizedBox(height: 12),

          if (currentScope == HifzScopeType.singleSurah)
            _buildSurahDropdown(context, colors),

          if (currentScope == HifzScopeType.juz)
            _buildJuzSelector(context, colors),
        ],
      );
    });
  }

  Widget _buildScopeTab(
    BuildContext context,
    HifzScopeType scope,
    String title,
    IconData icon,
    AppColorsExtension colors,
  ) {
    final isSelected = controller.selectedScope.value == scope;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setScope(scope),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected ? colors.primary : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : null,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahDropdown(BuildContext context, AppColorsExtension colors) {
    return Obx(() {
      final surahs = controller.surahs;
      final selected = controller.selectedSurah.value;

      if (surahs.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.primary.withValues(alpha: 0.5)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SurahEntity>(
            value: surahs.firstWhereOrNull((s) => s.id == selected?.id) ?? surahs.first,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.primary),
            items: surahs.map((surah) {
              return DropdownMenuItem<SurahEntity>(
                value: surah,
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${surah.id}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.accent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'سورة ${surah.nameAr}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${surah.totalVerses} آية',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newSurah) {
              if (newSurah != null) controller.setSurah(newSurah);
            },
          ),
        ),
      );
    });
  }

  Widget _buildJuzSelector(BuildContext context, AppColorsExtension colors) {
    return Obx(() {
      final activeJuz = controller.selectedJuz.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildJuzChip(context, 30, 'جزء عم (٣٠)', activeJuz == 30, colors),
              const SizedBox(width: 8),
              _buildJuzChip(context, 29, 'جزء تبارك (٢٩)', activeJuz == 29, colors),
              const SizedBox(width: 8),
              _buildJuzChip(context, 1, 'الجزء الأول (١)', activeJuz == 1, colors),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: activeJuz,
                isExpanded: true,
                items: List.generate(30, (i) => i + 1).map((juz) {
                  return DropdownMenuItem<int>(
                    value: juz,
                    child: Text('الجزء رقم ($juz) من القرآن الكريم'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) controller.setJuz(val);
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildJuzChip(
    BuildContext context,
    int juzNumber,
    String label,
    bool isSelected,
    AppColorsExtension colors,
  ) {
    return Expanded(
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: colors.primary.withValues(alpha: 0.15),
        onSelected: (_) => controller.setJuz(juzNumber),
      ),
    );
  }

  Widget _buildDifficultyAndCount(BuildContext context, AppColorsExtension colors) {
    return Column(
      children: [
        // Difficulty
        Row(
          children: HifzDifficulty.values.map((diff) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Obx(() {
                  final isSelected = controller.selectedDifficulty.value == diff;
                  return ChoiceChip(
                    label: Text(diff.labelAr, style: const TextStyle(fontSize: 11.5)),
                    selected: isSelected,
                    selectedColor: colors.accent.withValues(alpha: 0.2),
                    onSelected: (_) => controller.setDifficulty(diff),
                  );
                }),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Question count
        Row(
          children: [
            const Text('عدد الأسئلة:', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 12),
            ...[5, 10, 15, 20].map((count) {
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Obx(() {
                  final isSelected = controller.questionCount.value == count;
                  return ChoiceChip(
                    label: Text('$count'),
                    selected: isSelected,
                    selectedColor: colors.primary.withValues(alpha: 0.2),
                    onSelected: (_) => controller.setQuestionCount(count),
                  );
                }),
              );
            }),
          ],
        ),
      ],
    );
  }
}
