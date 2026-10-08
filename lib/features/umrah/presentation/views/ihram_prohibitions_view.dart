import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/widgets/umrah_filter_chip.dart';

class ProhibitionItem {
  final String title;
  final String category;
  final String description;
  final String evidence;
  final String fidyah;
  final IconData icon;

  const ProhibitionItem({
    required this.title,
    required this.category,
    required this.description,
    required this.evidence,
    required this.fidyah,
    required this.icon,
  });
}

class IhramProhibitionsView extends StatefulWidget {
  const IhramProhibitionsView({super.key});

  @override
  State<IhramProhibitionsView> createState() => _IhramProhibitionsViewState();
}

class _IhramProhibitionsViewState extends State<IhramProhibitionsView> {
  late final UmrahPreferencesController _prefsController;
  final RxString _selectedCategory = 'الكل'.obs;

  static const List<String> categories = [
    'الكل',
    'محظورات عامة',
    'خاصة بالرجال',
    'خاصة بالنساء',
    'أحكام الفدية',
  ];

  static const List<ProhibitionItem> items = [
    ProhibitionItem(
      title: 'استعمال الطيب والعطور',
      category: 'محظورات عامة',
      description:
          'يحرم على المحرم بعد عقد النية التطيب في بدنه أو ثيابه، أو شم الروائح العطرية قصداً، أو استعمال الصابون والشامبو المعطر.',
      evidence:
          'قال النبي ﷺ في المحرم الذي وقصته ناقته: «اغْسِلُوهُ بِمَاءٍ وَسِدْرٍ، وَكَفِّنُوهُ فِي ثَوْبَيْنِ، وَلا تَمَسُّوهُ طِيبًا» (صحيح البخاري ومسلم).',
      fidyah:
          'فدية أذى على التخيير: صيام ثلاثة أيام، أو إطعام ستة مساكين لكل مسكين نصف صاع، أو ذبح شاة.',
      icon: Icons.spa_rounded,
    ),
    ProhibitionItem(
      title: 'إزالة الشعر وتقليم الأظافر',
      category: 'محظورات عامة',
      description:
          'يحرم حلق شعر الرأس أو قصه أو نتفه، وكذلك سائر شعر البدن كالإبط والعانة والشارب، وتقليم أظافر اليدين والرجلين.',
      evidence:
          'قال تعالى: ﴿وَلَا تَحْلِقُوا رُءُوسَكُمْ حَتَّىٰ يَبْلُغَ الْهَدْيُ مَحِلَّهُ﴾ (سورة البقرة: 196).',
      fidyah:
          'إذا أزال ثلاث شعرات أو أظافر فأكثر متعمداً وجبت فدية أذى (صيام 3 أيام أو إطعام 6 مساكين أو ذبح شاة).',
      icon: Icons.content_cut_rounded,
    ),
    ProhibitionItem(
      title: 'لبس المخيط والمحيط المفصل (للرجال)',
      category: 'خاصة بالرجال',
      description:
          'يحرم على الرجل المحرم لبس كل ما فُصّل على قدر البدن أو العضو كالقميص، والسراويل، والفانلة، والجبة، والقفازين، والجوارب، والخفاف. ويجوز لبس الإزار والرداء والنعلين والحزام وساعة اليد.',
      evidence:
          'سُئل رسول الله ﷺ: ما يلبس المحرم؟ فقال: «لا يَلْبَسُ الْقَمِيصَ، وَلا الْعَمَائِمَ، وَلا السَّرَاوِيلاَتِ، وَلا الْبَرَانِسَ، وَلا الْخِفَافَ» (صحيح البخاري ومسلم).',
      fidyah: 'فدية أذى على التخيير إن لبسه لغير ضرورة، وإن لبسه لضرورة وجبت الفدية ولا إثم عليه.',
      icon: Icons.checkroom_rounded,
    ),
    ProhibitionItem(
      title: 'تغطية الرأس بملاصق (للرجال)',
      category: 'خاصة بالرجال',
      description:
          'يحرم على الرجل تغطية رأسه بما يلاصقه كالطاقية والغترة والعمامة. وتجوز الاستظلال بالمظلة الشمسية، وسقف السيارة، وخيمة المعسكر.',
      evidence:
          'قال النبي ﷺ في المحرم: «وَلا تُخَمِّرُوا رَأْسَهُ فَإِنَّهُ يُبْعَثُ يَوْمَ الْقِيَامَةِ مُلَبِّيًا» (صحيح البخاري ومسلم).',
      fidyah: 'فدية أذى على التخيير (شاة أو صيام 3 أيام أو إطعام 6 مساكين).',
      icon: Icons.face_rounded,
    ),
    ProhibitionItem(
      title: 'لبس النقاب والقفازين (للنساء)',
      category: 'خاصة بالنساء',
      description:
          'يحرم على المرأة المحرمة لبس النقاب (ما ستر الوجه وفيه فتحتان للعينين) ولبس القفازين في اليدين. ويسن لها سدل خمارها على وجهها عند مرور الرجال الأجانب دون نقاب.',
      evidence:
          'قال رسول الله ﷺ: «لا تَنْتَقِبِ الْمَرْأَةُ الْمُحْرِمَةُ، وَلا تَلْبَسِ الْقُفَّازَيْنِ» (صحيح البخاري 1838).',
      fidyah: 'فدية أذى على التخيير عند تعمد لبسهما.',
      icon: Icons.female_rounded,
    ),
    ProhibitionItem(
      title: 'عقد النكاح والخطبة',
      category: 'محظورات عامة',
      description:
          'يحرم على المحرم أن يعقد النكاح لنفسه أو لغيره بولاية أو وكالة، وتكره الخطبة.',
      evidence:
          'قال رسول الله ﷺ: «لا يَنْكِحُ الْمُحْرِمُ، وَلا يُنْكِحُ، وَلا يَخْطُبُ» (صحيح مسلم 1409).',
      fidyah: 'عقد النكاح باطل ولا يصح، ولا تجب فيه فدية مالية ولكن يقع به الإثم ويجب التوبة.',
      icon: Icons.favorite_border_rounded,
    ),
    ProhibitionItem(
      title: 'صيد البر وقتله أو الإعانة عليه',
      category: 'محظورات عامة',
      description:
          'يحرم على المحرم صيد الحيوانات البرية المأكولة كالغزال والأرانب والطيور البرية، أو الدلالة عليها. أما صيد البحر فيجوز إجماعاً.',
      evidence:
          'قال تعالى: ﴿وَحُرِّمَ عَلَيْكُمْ صَيْدُ الْبَرِّ مَا دُمْتُمْ حُرُمًا﴾ (سورة المائدة: 96).',
      fidyah: 'جزاء مثل ما قتل من النَّعَم يحكم به ذوا عدل، أو إطعام مساكين، أو عدل ذلك صياماً.',
      icon: Icons.pets_rounded,
    ),
    ProhibitionItem(
      title: 'الجماع ومقدماته',
      category: 'محظورات عامة',
      description:
          'الجماع هو أعظم محظورات الإحرام، ويترتب عليه فساد الحج قبل التحلل الأول، ويجب به المضي فيه وقضاؤه في العام القادم مع ذبح بدنة (ناقة).',
      evidence:
          'قال تعالى: ﴿فَمَن فَرَضَ فِيهِنَّ الْحَجَّ فَلَا رَفَثَ وَلَا فُسُوقَ وَلَا جِدَالَ فِي الْحَجِّ﴾ (سورة البقرة: 197).',
      fidyah: 'ذبح بدنة وقضاء الحج في العام القادم، أما في العمرة فتفسد ويلزم قضاؤها وشاة.',
      icon: Icons.warning_amber_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());
  }

  List<ProhibitionItem> get _filteredItems {
    final cat = _selectedCategory.value;
    if (cat == 'الكل') return items;
    if (cat == 'أحكام الفدية') return items; // Shows all with fidyah highlight
    return items.where((item) => item.category == cat).toList();
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
      final selectedCategory = _selectedCategory.value;
      final filteredList = _filteredItems;

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppScaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              'محظورات الإحرام وأحكام الفدية',
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
                // Top Explanatory Banner
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: primaryColor.withAlpha(70)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.rule_rounded, color: primaryColor, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'قاعدة شرعية: من فعل محظوراً ناسياً أو جاهلاً أو مكرهاً فلا إثم عليه ولا فدية لقوله تعالى: ﴿وَلَيْسَ عَلَيْكُمْ جُنَاحٌ فِيمَا أَخْطَأْتُم بِهِ﴾.',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 12.5 * fontScale,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Chips
                SizedBox(
                  height: isElderly ? 58 : 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selectedCategory == cat;

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

                // Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildProhibitionCard(
                        item,
                        colors,
                        primaryColor,
                        textColor,
                        fontScale,
                        isElderly,
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

  Widget _buildProhibitionCard(
    ProhibitionItem item,
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryColor.withAlpha(25),
                child: Icon(item.icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: (isElderly ? 17 : 15) * fontScale,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      item.category,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11 * fontScale,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.description,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: (isElderly ? 14 : 13) * fontScale,
              color: textColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          // Evidence Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.menu_book_rounded, size: 14, color: colors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.evidence,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5 * fontScale,
                      color: colors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Fidyah Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: Colors.amber.shade700.withAlpha(90)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.healing_rounded, size: 14, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'الفدية: ${item.fidyah}',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
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
  }
}
