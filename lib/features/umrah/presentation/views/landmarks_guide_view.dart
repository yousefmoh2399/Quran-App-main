import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/umrah/data/models/landmark_models.dart';
import 'package:quran_app_android/features/umrah/data/services/landmarks_service.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/widgets/umrah_filter_chip.dart';

class LandmarksGuideView extends StatefulWidget {
  const LandmarksGuideView({super.key});

  @override
  State<LandmarksGuideView> createState() => _LandmarksGuideViewState();
}

class _LandmarksGuideViewState extends State<LandmarksGuideView> {
  late final UmrahPreferencesController _prefsController;
  final TextEditingController _searchController = TextEditingController();

  final RxString _selectedCity = 'الكل'.obs;
  final RxString _searchQuery = ''.obs;

  static const List<String> cities = [
    'الكل',
    'مكة المكرمة',
    'المدينة المنورة',
  ];

  @override
  void initState() {
    super.initState();
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Obx(() {
      final isElderly = _prefsController.isElderlyMode.value;
      final fontScale = _prefsController.fontMultiplier;
      final primaryColor = _prefsController.getPrimaryColor(colors.primary, isDark);
      final textColor = _prefsController.getTextColor(colors.text, isDark);
      final selectedCity = _selectedCity.value;
      final query = _searchQuery.value;

      final items = LandmarksService.instance.search(query, city: selectedCity);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppScaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              'معالم الحرمين وآداب الزيارة',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18 * fontScale,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _searchQuery.value = val,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 14 * fontScale,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن معلم (مثل: الكعبة، الروضة، زمزم)...',
                      hintStyle: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13 * fontScale,
                        color: colors.textMuted,
                      ),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery.value = '';
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                    ),
                  ),
                ),

                // City Filter Chips
                SizedBox(
                  height: isElderly ? 56 : 46,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: cities.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final city = cities[index];
                      final isSelected = selectedCity == city;
                      return UmrahFilterChip(
                        label: city,
                        isSelected: isSelected,
                        fontScale: fontScale,
                        isElderly: isElderly,
                        onTap: () => _selectedCity.value = city,
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // Landmarks List
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 60,
                                  color: colors.textMuted.withAlpha(120),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'لا توجد معالم مطابقة لبحثك',
                                  style: TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                    fontSize: 15 * fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final landmark = items[index];
                            return _buildLandmarkCard(
                              landmark: landmark,
                              colors: colors,
                              primaryColor: primaryColor,
                              textColor: textColor,
                              fontScale: fontScale,
                              isElderly: isElderly,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLandmarkCard({
    required LandmarkItem landmark,
    required AppColorsExtension colors,
    required Color primaryColor,
    required Color textColor,
    required double fontScale,
    required bool isElderly,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          leading: Container(
            width: isElderly ? 50 : 42,
            height: isElderly ? 50 : 42,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              landmark.icon,
              color: primaryColor,
              size: isElderly ? 26 : 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  landmark.name,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 16 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: landmark.city == 'مكة المكرمة'
                      ? const Color(0xFFC5A059).withAlpha(25)
                      : Colors.teal.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  landmark.city,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: landmark.city == 'مكة المكرمة'
                        ? const Color(0xFFC5A059)
                        : Colors.teal.shade700,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              landmark.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12.5 * fontScale,
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Virtues / Significance
            _buildSection(
              title: 'الفضائل والأهمية الشرعية:',
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFFC5A059),
              content: landmark.virtues,
              colors: colors,
              textColor: textColor,
              fontScale: fontScale,
            ),
            const SizedBox(height: 12),

            // Manners & Sunnahs
            _buildListSection(
              title: 'السنن والآداب المأثورة:',
              icon: Icons.check_circle_outline_rounded,
              iconColor: primaryColor,
              items: landmark.mannersAndSunnahs,
              colors: colors,
              textColor: textColor,
              fontScale: fontScale,
            ),
            const SizedBox(height: 12),

            // Common Mistakes
            _buildListSection(
              title: 'محاذير وأخطاء شائعة:',
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange.shade800,
              items: landmark.commonMistakes,
              colors: colors,
              textColor: textColor,
              fontScale: fontScale,
            ),
            const SizedBox(height: 12),

            // Practical & Regulatory Advice
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: primaryColor.withAlpha(40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      landmark.practicalAdvice,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12 * fontScale,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String content,
    required AppColorsExtension colors,
    required Color textColor,
    required double fontScale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 13 * fontScale,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(right: 22),
          child: Text(
            content,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.5 * fontScale,
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required AppColorsExtension colors,
    required Color textColor,
    required double fontScale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 13 * fontScale,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(right: 22),
          child: Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.5 * fontScale,
                          color: colors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
