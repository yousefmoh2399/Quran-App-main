import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../data/models/prophetic_food_model.dart';
import '../controllers/prophetic_medicine_controller.dart';

class PropheticMedicineView extends StatefulWidget {
  const PropheticMedicineView({super.key});

  @override
  State<PropheticMedicineView> createState() => _PropheticMedicineViewState();
}

class _PropheticMedicineViewState extends State<PropheticMedicineView> {
  late final PropheticMedicineController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<PropheticMedicineController>()
        ? Get.find<PropheticMedicineController>()
        : Get.put(PropheticMedicineController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            'الطب النبوي والغذاء القرآني',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 17.5,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildTabSelector(colors),
            _buildSearchBar(colors),
            Expanded(
              child: Obx(() {
                return _controller.selectedTab.value == 0
                    ? _buildFoodsTab(colors)
                    : _buildRecipesTab(colors);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(dynamic colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider.withOpacity(0.4)),
      ),
      child: Obx(() {
        final currentTab = _controller.selectedTab.value;
        return Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'موسوعة الأغذية',
                icon: Icons.menu_book_rounded,
                isSelected: currentTab == 0,
                onTap: () => _controller.setTab(0),
                colors: colors,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTabButton(
                title: 'وصفات منزلية مجربة',
                icon: Icons.soup_kitchen_rounded,
                isSelected: currentTab == 1,
                onTap: () => _controller.setTab(1),
                colors: colors,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.5),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
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
            hintText: 'ابحث عن غذاء، فائدة طبية، أو وصفة...',
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

  Widget _buildFoodsTab(dynamic colors) {
    final categories = [
      null,
      PropheticFoodCategory.quranic,
      PropheticFoodCategory.sunnah,
      PropheticFoodCategory.remedy,
    ];

    return Column(
      children: [
        // Category filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Obx(() {
            final selected = _controller.selectedCategory.value;
            return Row(
              children: categories.map((cat) {
                final isSelected = selected == cat;
                final label = cat == null ? 'كافة الأغذية' : cat.displayName;

                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () => _controller.setCategory(cat),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          fontSize: 11.5,
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
        ),
        const SizedBox(height: 4),

        // Food Items List
        Expanded(
          child: Obx(() {
            final foods = _controller.filteredFoods;
            if (foods.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'لا توجد نتائج مطابقة لبحثك',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return _buildFoodCard(food, colors);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFoodCard(PropheticFood food, dynamic colors) {
    return Obx(() {
      final isExpanded = _controller.expandedFoodIds.contains(food.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.divider.withOpacity(0.35)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _controller.toggleExpanded(food.id),
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
                        child: Icon(food.icon, size: 18, color: colors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name,
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                              ),
                            ),
                            Text(
                              food.category.displayName,
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 11,
                                color: colors.primary,
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
                  const SizedBox(height: 10),

                  // Quran / Hadith text
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.quranOrHadithText,
                          style: TextStyle(
                            fontFamily: AppTypography.quranFont,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          food.reference,
                          style: const TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 10.5,
                            color: Color(0xFFB8860B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Prophetic guidance
                  const SizedBox(height: 10),
                  Text(
                    food.propheticGuidance,
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // Expanded Scientific Benefits & Recipes
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Text(
                      'الفوائد الطبية المثبتة علمياً:',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...food.scientificBenefits.map((benefit) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                benefit,
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
                      );
                    }),
                    if (food.recipes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...food.recipes.map((r) => _buildRecipeInlineCard(r, colors)),
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

  Widget _buildRecipeInlineCard(PropheticRecipe recipe, dynamic colors) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.soup_kitchen_rounded, size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recipe.title,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'الوقت الأفضل: ${recipe.bestTimeToConsume}',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'المكونات:',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...recipe.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.only(right: 6, top: 2),
                child: Text(
                  '• $ing',
                  style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 11.5, color: colors.text),
                ),
              )),
          const SizedBox(height: 8),
          const Text(
            'طريقة التحضير:',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...recipe.steps.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(right: 6, top: 2),
                child: Text(
                  '${entry.key + 1}. ${entry.value}',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecipesTab(dynamic colors) {
    final recipes = _controller.filteredRecipes;

    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'لا توجد وصفات مطابقة للبحث',
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
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.divider.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.primary.withOpacity(0.12),
                    child: Icon(Icons.soup_kitchen_rounded, size: 16, color: colors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'الوقت المثالي: ${recipe.bestTimeToConsume}',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'المكونات المطلوبة:',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 4),
              ...recipe.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.only(right: 6, top: 2),
                    child: Text(
                      '• $ing',
                      style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12, color: colors.text),
                    ),
                  )),
              const SizedBox(height: 10),
              Text(
                'خطوات الإعداد:',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 4),
              ...recipe.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 6, top: 3),
                    child: Text(
                      '${e.key + 1}. ${e.value}',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  )),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        recipe.healthBenefit,
                        style: const TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.5,
                          color: Color(0xFF2E7D32),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
