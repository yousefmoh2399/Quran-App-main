import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/components/app_card.dart';
import '../controllers/hifz_tester_controller.dart';
import '../../data/models/hifz_test_models.dart';
import '../../data/models/mutashabihat_entry.dart';

class MutashabihatBrowserView extends StatelessWidget {
  final HifzTesterController controller;

  const MutashabihatBrowserView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        // Top Search & Filter Bar
        _buildSearchAndFilters(context, colors),

        // List of Mutashabihat Cards
        Expanded(
          child: Obx(() {
            final entries = controller.filteredMutashabihat;

            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      'لا توجد مواضع متشابهة مطابقة لبحثك',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                return _buildMutashabihatCard(context, entries[index], colors);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Input
          TextField(
            onChanged: (val) => controller.mutashabihatSearchQuery.value = val,
            decoration: InputDecoration(
              hintText: 'ابحث في المتشابهات، السور، أو قواعد الضبط...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: colors.accent),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() {
              final activeCat = controller.selectedCategory.value;
              final categories = controller.mutashabihatCategories;

              return Row(
                children: categories.map((cat) {
                  final isSelected = activeCat == cat;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 11.5)),
                      selected: isSelected,
                      selectedColor: colors.primary.withValues(alpha: 0.2),
                      onSelected: (_) => controller.selectedCategory.value = cat,
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMutashabihatCard(
    BuildContext context,
    MutashabihatEntry entry,
    AppColorsExtension colors,
  ) {
    final isDark = colors.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Category Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : colors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.category,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Verses comparison
            _buildVerseSnippet(
              context,
              surahName: entry.surah1Name,
              ayahNum: entry.ayah1Number,
              text: entry.verse1Text,
              badgeColor: colors.primary,
            ),
            const SizedBox(height: 8),

            _buildVerseSnippet(
              context,
              surahName: entry.surah2Name,
              ayahNum: entry.ayah2Number,
              text: entry.verse2Text,
              badgeColor: const Color(0xFF2E7D32),
            ),

            if (entry.verse3Text != null && entry.surah3Name != null) ...[
              const SizedBox(height: 8),
              _buildVerseSnippet(
                context,
                surahName: entry.surah3Name!,
                ayahNum: entry.ayah3Number ?? 0,
                text: entry.verse3Text!,
                badgeColor: const Color(0xFF1565C0),
              ),
            ],

            const SizedBox(height: 12),

            // Key textual difference
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.compare_arrows_rounded, size: 18, color: colors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.keyDifference,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Mnemonic Rule Box (ضابط الحفظ)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2F25) : const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 16, color: colors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'ضابط الحفظ وقاعدة السلف:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        entry.referenceBook,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.ruleMnemonic,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Button to test this mutashabihat
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  controller.setMode(HifzTestMode.mutashabihat);
                  controller.startTest();
                },
                icon: Icon(Icons.play_circle_fill_rounded, size: 16, color: colors.primary),
                label: Text(
                  'اختبر حفظك في المتشابهات',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseSnippet(
    BuildContext context, {
    required String surahName,
    required int ayahNum,
    required String text,
    required Color badgeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14211A) : const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'سورة $surahName [$ayahNum]',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '﴿ $text ﴾',
            style: const TextStyle(
              fontFamily: 'uthman',
              fontSize: 15.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
