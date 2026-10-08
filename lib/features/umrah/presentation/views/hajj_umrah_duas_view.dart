import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/widgets/umrah_filter_chip.dart';
import 'package:share_plus/share_plus.dart';

class HajjDuaItem {
  final String id;
  final String title;
  final String arabicText;
  final String category;
  final String source;
  final int targetCount;

  const HajjDuaItem({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.category,
    required this.source,
    this.targetCount = 1,
  });
}

class HajjUmrahDuasView extends StatefulWidget {
  const HajjUmrahDuasView({super.key});

  @override
  State<HajjUmrahDuasView> createState() => _HajjUmrahDuasViewState();
}

class _HajjUmrahDuasViewState extends State<HajjUmrahDuasView> {
  late final UmrahPreferencesController _prefsController;
  final TextEditingController _searchController = TextEditingController();

  final RxString _selectedCategory = 'الكل'.obs;
  final RxString _searchQuery = ''.obs;
  final RxMap<String, int> _counters = <String, int>{}.obs;

  static const List<String> categories = [
    'الكل',
    'التلبية والإحرام',
    'أدعية الطواف',
    'أدعية السعي',
    'أدعية يوم عرفة',
    'المشعر الحرام',
    'أيام التشريق والرمي',
    'ماء زمزم والملتزم',
  ];

  static const List<HajjDuaItem> allDuas = [
    HajjDuaItem(
      id: 'talbiyah',
      title: 'التلبية النبوية المأثورة',
      category: 'التلبية والإحرام',
      arabicText:
          'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لا شَرِيكَ لَكَ',
      source: 'صحيح البخاري وصحيح مسلم عن عبد الله بن عمر',
      targetCount: 3,
    ),
    HajjDuaItem(
      id: 'ihram_niyyah',
      title: 'نية الدخول في النسك والاشتراط',
      category: 'التلبية والإحرام',
      arabicText: 'لَبَّيْكَ اللَّهُمَّ عُمْرَةً (أَوْ حَجًّا)، اللَّهُمَّ مَحِلِّي حَيْثُ حَبَسْتَنِي',
      source: 'صحيح البخاري (5089) وصحيح مسلم (1207)',
      targetCount: 1,
    ),
    HajjDuaItem(
      id: 'black_stone',
      title: 'التكبير عند استلام الحجر الأسود',
      category: 'أدعية الطواف',
      arabicText: 'بِسْمِ اللَّهِ، وَاللَّهُ أَكْبَرُ',
      source: 'صحيح البخاري (1613) عن عبد الله بن عباس',
      targetCount: 7,
    ),
    HajjDuaItem(
      id: 'between_corners',
      title: 'الدعاء بين الركن اليماني والحجر الأسود',
      category: 'أدعية الطواف',
      arabicText: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      source: 'سورة البقرة: 201، وسنن أبي داود (1892) بإسناد حسن',
      targetCount: 7,
    ),
    HajjDuaItem(
      id: 'tawaf_tasbeeh',
      title: 'التسبيح والتحميد المأثور في أشواط الطواف',
      category: 'أدعية الطواف',
      arabicText:
          'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلا إِلَهَ إِلا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلا حَوْلَ وَلا قُوَّةَ إِلا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ',
      source: 'سنن ابن ماجه (2957) والسنن الكبرى للبيهقي',
      targetCount: 7,
    ),
    HajjDuaItem(
      id: 'tawaf_afw',
      title: 'سؤال العفو والعافية أثناء الطواف',
      category: 'أدعية الطواف',
      arabicText:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، اللَّهُمَّ اسْتُرْ عَوْرَاتِي وَآمِنْ رَوْعَاتِي',
      source: 'سنن أبي داود (5074) وصحيح ابن ماجه',
      targetCount: 3,
    ),
    HajjDuaItem(
      id: 'safa_approach',
      title: 'الذكر عند الدنو من الصفا',
      category: 'أدعية السعي',
      arabicText:
          '﴿إِنَّ الصَّفَا وَالْمَرْوَةَ مِن شَعَائِرِ اللَّهِ﴾، أَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ',
      source: 'صحيح مسلم (1218) عن جابر بن عبد الله',
      targetCount: 1,
    ),
    HajjDuaItem(
      id: 'safa_marwah_dhikr',
      title: 'الذكر النبوي على الصفا والمروة',
      category: 'أدعية السعي',
      arabicText:
          'لا إِلَهَ إِلا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، لا إِلَهَ إِلا اللَّهُ وَحْدَهُ، أَنْجَزَ وَعْدَهُ، وَنَصَرَ عَبْدَهُ، وَهَزَمَ الأَحْزَابَ وَحْدَهُ',
      source: 'صحيح مسلم (1218) حديث جابر الطويل',
      targetCount: 3,
    ),
    HajjDuaItem(
      id: 'green_zone_dua',
      title: 'دعاء السعي بين الميلين الأخضرين',
      category: 'أدعية السعي',
      arabicText:
          'رَبِّ اغْفِرْ وَارْحَمْ، وَتَجَاوَزْ عَمَّا تَعْلَمْ، إِنَّكَ أَنْتَ الأَعَزُّ الأَكْرَمُ',
      source: 'مصنف ابن أبي شيبة بسند صحيح عن ابن مسعود وابن عمر',
      targetCount: 7,
    ),
    HajjDuaItem(
      id: 'arafah_best_dua',
      title: 'خير الدعاء دعاء يوم عرفة',
      category: 'أدعية يوم عرفة',
      arabicText:
          'لا إِلَهَ إِلا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      source: 'جامع الترمذي (3585) وحسنه الألباني',
      targetCount: 100,
    ),
    HajjDuaItem(
      id: 'arafah_tawbah',
      title: 'دعاء الابتهال والاستغفار في صعيد عرفات',
      category: 'أدعية يوم عرفة',
      arabicText:
          'اللَّهُمَّ إِنِّي ظَلَمْتُ نَفْسِي ظُلْمًا كَثِيرًا، وَلا يَغْفِرُ الذُّنُوبَ إِلا أَنْتَ، فَاغْفِرْ لِي مَغْفِرَةً مِنْ عِنْدِكَ، وَارْحَمْنِي إِنَّكَ أَنْتَ الْغَفُورُ الرَّحِيمُ',
      source: 'صحيح البخاري (834) وصحيح مسلم (2705)',
      targetCount: 3,
    ),
    HajjDuaItem(
      id: 'muzdalifah_dhikr',
      title: 'الذكر عند المشعر الحرام بمزدلفة',
      category: 'المشعر الحرام',
      arabicText:
          '﴿فَإِذَا أَفَضْتُم مِّنْ عَرَفَاتٍ فَاذْكُرُوا اللَّهَ عِندَ الْمَشْعَرِ الْحَرَامِ ۖ وَاذْكُرُوهُ كَمَا هَدَاكُمْ وَإِن كُنتُم مِّن قَبْلِهِ لَمِنَ الضَّالِّينَ﴾',
      source: 'سورة البقرة: 198، وصحيح مسلم',
      targetCount: 1,
    ),
    HajjDuaItem(
      id: 'jamarat_takbeer',
      title: 'التكبير عند رمي كل حصاة بالجمرات',
      category: 'أيام التشريق والرمي',
      arabicText: 'اللَّهُ أَكْبَرُ رَغْمًا لِلشَّيْطَانِ وَرِضًا لِلرَّحْمَنِ',
      source: 'السنن الكبرى للبيهقي ومصنف ابن أبي شيبة',
      targetCount: 7,
    ),
    HajjDuaItem(
      id: 'tashreeq_takbeerat',
      title: 'تكبيرات العيد وأيام التشريق المباركة',
      category: 'أيام التشريق والرمي',
      arabicText:
          'اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ لا إِلَهَ إِلا اللَّهُ، اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ وَلِلَّهِ الْحَمْدُ',
      source: 'مصنف عبد الرزاق ومصنف ابن أبي شيبة بإسناد صحيح',
      targetCount: 3,
    ),
    HajjDuaItem(
      id: 'zamzam_shifa',
      title: 'دعاء الشرب والتضلع من ماء زمزم',
      category: 'ماء زمزم والملتزم',
      arabicText: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا وَاسِعًا، وَشِفَاءً مِنْ كُلِّ دَاءٍ',
      source: 'المستدرك على الصحيحين للحاكم (1/473) وسنن الدارقطني',
      targetCount: 1,
    ),
    HajjDuaItem(
      id: 'multazam_dua',
      title: 'الدعاء عند الملتزم وحطايا الكعبة',
      category: 'ماء زمزم والملتزم',
      arabicText:
          'اللَّهُمَّ إِنَّ هَذَا بَيْتُكَ الْحَرَامُ وَأَنَا عَبْدُكَ، جِئْتُكَ مُسْتَجِيرًا مُسْتَغْفِرًا، فَتَقَبَّلْ دُعَائِي وَاغْفِرْ ذَنْبِي وَارْحَمْنِي يَا أَرْحَمَ الرَّاحِمِينَ',
      source: 'سنن أبي داود ومجموع الفتاوى للإمام النووي',
      targetCount: 1,
    ),
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

  List<HajjDuaItem> get _filteredDuas {
    final cat = _selectedCategory.value;
    final q = _searchQuery.value.trim().toLowerCase();

    return allDuas.where((item) {
      final matchesCat = (cat == 'الكل' || item.category == cat);
      final matchesSearch = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.arabicText.toLowerCase().contains(q) ||
          item.source.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();
  }

  void _incrementCounter(HajjDuaItem item) {
    AppHaptics.selection();
    final current = _counters[item.id] ?? 0;
    if (current < item.targetCount) {
      _counters[item.id] = current + 1;
      if (_counters[item.id] == item.targetCount) {
        AppHaptics.cycleCompleted();
      }
    } else {
      _counters[item.id] = 0; // Reset after reaching target
    }
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

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppScaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              'أدعية وأذكار الحج والعمرة',
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
                // Search Input
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _searchQuery.value = val,
                    decoration: InputDecoration(
                      hintText: 'ابحث في أدعية وأذكار الحج والعمرة...',
                      prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                      suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery.value = '';
                              },
                            )
                          : const SizedBox.shrink()),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                ),

                // Category Filter Chips
                SizedBox(
                  height: isElderly ? 58 : 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategory.value == cat;

                      return UmrahFilterChip(
                        label: cat,
                        isSelected: isSelected,
                        fontScale: fontScale,
                        isElderly: isElderly,
                        onTap: () => _selectedCategory.value = cat,
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // Duas List
                Expanded(
                  child: Builder(builder: (context) {
                    final list = _filteredDuas;

                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 54, color: colors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد أدعية مطابقة للبحث',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 16 * fontScale,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final dua = list[index];
                        return _buildDuaCard(
                          dua,
                          colors,
                          primaryColor,
                          textColor,
                          fontScale,
                          isElderly,
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDuaCard(
    HajjDuaItem dua,
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    return Obx(() {
      final currentCount = _counters[dua.id] ?? 0;
      final isCompleted = currentCount >= dua.targetCount && dua.targetCount > 1;

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isCompleted ? Colors.green : colors.divider,
            width: isCompleted ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted ? Colors.green.withAlpha(30) : Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Category Badge + Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    dua.category,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dua.title,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: (isElderly ? 16 : 14.5) * fontScale,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Arabic Text
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                dua.arabicText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.decorativeFont,
                  fontSize: (isElderly ? 24 : 19) * fontScale,
                  height: 1.9,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Source Reference
            Text(
              'المصدر: ${dua.source}',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 11 * fontScale,
                color: colors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Action Row: Counter button, Copy, Share
            Row(
              children: [
                // Repetition Counter button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.green : primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  onPressed: () => _incrementCounter(dua),
                  icon: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.replay_rounded,
                    size: 16,
                  ),
                  label: Text(
                    dua.targetCount > 1
                        ? '$currentCount / ${dua.targetCount}'
                        : 'قرأت الذكر',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5 * fontScale,
                    ),
                  ),
                ),

                const Spacer(),

                // Copy to clipboard
                IconButton(
                  tooltip: 'نسخ الدعاء',
                  icon: Icon(Icons.copy_rounded, color: colors.textMuted, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '${dua.title}\n\n${dua.arabicText}\n\n[المصدر: ${dua.source}]',
                    ));
                    AppHaptics.selection();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ الدعاء إلى الحافظة'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // Share
                IconButton(
                  tooltip: 'مشاركة الدعاء',
                  icon: Icon(Icons.share_rounded, color: colors.textMuted, size: 20),
                  onPressed: () {
                    AppHaptics.selection();
                    Share.share(
                      '${dua.title}\n\n${dua.arabicText}\n\n[المصدر: ${dua.source}]\n\nعبر تطبيق تقرب',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
