import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_guide_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';

class UmrahHubView extends StatefulWidget {
  const UmrahHubView({super.key});

  @override
  State<UmrahHubView> createState() => _UmrahHubViewState();
}

class _UmrahHubViewState extends State<UmrahHubView> {
  late final UmrahGuideController _guideController;
  late final UmrahPreferencesController _prefsController;

  @override
  void initState() {
    super.initState();
    _guideController = Get.put(UmrahGuideController());
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());
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
              'رفيق المعتمر',
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
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Header Status Card
                _buildHeaderCard(colors, primaryColor, textColor, fontScale, isElderly),

                const SizedBox(height: AppSpacing.md),

                // Elderly Mode Toggle Quick Card
                _buildElderlyQuickToggle(colors, primaryColor, textColor, fontScale, isElderly),

                const SizedBox(height: AppSpacing.md),

                Text(
                  'أدوات ومناسك العمرة',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 16 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 1. Umrah Guide
                _buildHubTile(
                  title: 'دليل مناسك العمرة خطوة بخطوة',
                  subtitle: 'الإحرام، الطواف، الركعتان، السعي، والحلق أو التقصير',
                  icon: Icons.auto_stories_rounded,
                  iconColor: primaryColor,
                  onTap: () => Get.toNamed(AppRoutes.umrahGuide),
                  colors: colors,
                  textColor: textColor,
                  fontScale: fontScale,
                  isElderly: isElderly,
                ),

                const SizedBox(height: AppSpacing.sm),

                // 2. Tawaf Counter
                _buildHubTile(
                  title: 'عدّاد الطواف التفاعلي (7 أشواط)',
                  subtitle: 'دائرة تفاعلية حول الكعبة، الأدعية بخط كبير، وحفظ تلقائي',
                  icon: Icons.rotate_right_rounded,
                  iconColor: colors.accent,
                  onTap: () => Get.toNamed(AppRoutes.tawafCounter),
                  colors: colors,
                  textColor: textColor,
                  fontScale: fontScale,
                  isElderly: isElderly,
                ),

                const SizedBox(height: AppSpacing.sm),

                // 3. Sa'i Counter
                _buildHubTile(
                  title: 'عدّاد السعي (الصفا والمروة)',
                  subtitle: 'تتبع الاتجاه بين الصفا والمروة وتنبيه الميلين الأخضرين',
                  icon: Icons.directions_walk_rounded,
                  iconColor: Colors.green.shade700,
                  onTap: () => Get.toNamed(AppRoutes.saiCounter),
                  colors: colors,
                  textColor: textColor,
                  fontScale: fontScale,
                  isElderly: isElderly,
                ),

                const SizedBox(height: AppSpacing.sm),

                // 4. Congestion Estimates
                _buildHubTile(
                  title: 'تقديرات أوقات الزحام بالحرم',
                  subtitle: 'أنماط استرشادية تقريبية لأفضل أوقات الطواف والسعي',
                  icon: Icons.access_time_rounded,
                  iconColor: Colors.blue.shade700,
                  onTap: () => Get.toNamed(AppRoutes.umrahEstimates),
                  colors: colors,
                  textColor: textColor,
                  fontScale: fontScale,
                  isElderly: isElderly,
                ),

                const SizedBox(height: AppSpacing.sm),

                // 5. Trip Diary
                _buildHubTile(
                  title: 'يوميات وخواطر الرحلة',
                  subtitle: 'سجّل مشاعرك وأدعيتك محلياً مع البحث والتصنيف',
                  icon: Icons.edit_note_rounded,
                  iconColor: Colors.purple.shade700,
                  onTap: () => Get.toNamed(AppRoutes.umrahDiary),
                  colors: colors,
                  textColor: textColor,
                  fontScale: fontScale,
                  isElderly: isElderly,
                ),

                const SizedBox(height: AppSpacing.sm),

                // 6. Sources & Religious Review
                _buildHubTile(
                  title: 'المصادر والتدقيق الشرعي',
                  subtitle: 'بيان المصادر والمراجع وتواريخ التدقيق لكل محتوى',
                  icon: Icons.verified_user_rounded,
                  iconColor: colors.accent,
                  onTap: () => Get.toNamed(AppRoutes.umrahSources),
                  colors: colors,
                  textColor: textColor,
                  fontScale: fontScale,
                  isElderly: isElderly,
                ),

                const SizedBox(height: AppSpacing.lg),

                // 100% Offline Badge
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: colors.textMuted, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'رفيق المعتمر يعمل أوفلاين بالكامل دون اتصال بالإنترنت ودون استهلاك للبيانات.',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 12 * fontScale,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeaderCard(
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    final progress = _guideController.overallProgress;
    final completedCount = _guideController.completedStepIds.length;
    final totalSteps = _guideController.guide.value?.steps.length ?? 5;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withAlpha(210),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withAlpha(40),
                child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقبل الله عمرتكم وسعيكم',
                      style: TextStyle(
                        fontFamily: AppTypography.decorativeFont,
                        fontSize: (isElderly ? 20 : 17) * fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'أدلة ميسرة وعدادات متوافقة مع السنة النبوية',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12 * fontScale,
                        color: Colors.white.withAlpha(210),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'التقدم في المناسك',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13 * fontScale,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$completedCount من $totalSteps خطوات',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12 * fontScale,
                      color: colors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withAlpha(50),
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElderlyQuickToggle(
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isElderly ? primaryColor : colors.divider,
          width: isElderly ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.accessibility_new_rounded,
            color: isElderly ? primaryColor : colors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وضع كبار السن',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * fontScale,
                    color: textColor,
                  ),
                ),
                Text(
                  'أزرار وخطوط مكبرة، تباين عالي، واهتزاز قوي',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11 * fontScale,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isElderly,
            activeColor: primaryColor,
            onChanged: (_) => _prefsController.toggleElderlyMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildHubTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required AppColorsExtension colors,
    required Color textColor,
    required double fontScale,
    required bool isElderly,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: isElderly ? 26 : 22,
              backgroundColor: iconColor.withAlpha(25),
              child: Icon(icon, color: iconColor, size: isElderly ? 26 : 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: (isElderly ? 17 : 15) * fontScale,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12 * fontScale,
                      color: colors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
