import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/data/services/guide_engine.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';

class UmrahSourcesReviewView extends StatefulWidget {
  const UmrahSourcesReviewView({super.key});

  @override
  State<UmrahSourcesReviewView> createState() => _UmrahSourcesReviewViewState();
}

class _UmrahSourcesReviewViewState extends State<UmrahSourcesReviewView> {
  final GuideEngine _guideEngine = GuideEngine();
  late final UmrahPreferencesController _prefsController;

  bool _isLoading = true;
  GuideModel? _guide;

  @override
  void initState() {
    super.initState();
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _guideEngine.loadGuide();
      setState(() {
        _guide = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
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
              'المصادر والتدقيق الشرعي',
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
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Editorial Policy Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: colors.accent, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: colors.accent.withAlpha(30),
                                  child: Icon(Icons.verified_user_rounded, color: colors.accent, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'ميثاق الأمانة والتدقيق الشرعي',
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 16 * fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              'يلتزم تطبيق "تقرب" التزاماً صارماً بعدم تأليف أو استنباط أي حكم فقهي أو دعاء أو ترتيب للمناسك من قبل الذكاء الاصطناعي أو المطورين. كافة النصوص مستقاة حصراً من مصادرها الشرعية المنضبطة.',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 13 * fontScale,
                                color: textColor,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: colors.bg,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                'بيان التوثيق: تم استخراج ومراجعة كافة الأدعية والنصوص الواردة من مصادر السنة النبوية المطهرة وأمهات كتب الفقه المعتمدة.',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 12 * fontScale,
                                  color: colors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        'قائمة المراجع والمصادر المعتمدة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      if (_guide != null)
                        ..._guide!.sourcesReview.map(
                          (item) => _buildSourceItemCard(
                            item,
                            colors,
                            primaryColor,
                            textColor,
                            fontScale,
                            isElderly,
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

  Widget _buildSourceItemCard(
    SourceReviewItem item,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.sourceName,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: (isElderly ? 17 : 15) * fontScale,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: colors.accent.withAlpha(80)),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (item.publisher.isNotEmpty)
            Text(
              'الجهة / المحقق: ${item.publisher}',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 13 * fontScale,
                color: colors.textMuted,
              ),
            ),
          if (item.edition.isNotEmpty)
            Text(
              'الإصدار: ${item.edition}',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12 * fontScale,
                color: colors.textMuted,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            item.notes,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13 * fontScale,
              color: textColor,
              height: 1.45,
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                'تاريخ التدقيق: ${item.reviewedAt}',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 11 * fontScale,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
