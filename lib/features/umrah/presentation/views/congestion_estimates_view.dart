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

class CongestionEstimatesView extends StatefulWidget {
  const CongestionEstimatesView({super.key});

  @override
  State<CongestionEstimatesView> createState() => _CongestionEstimatesViewState();
}

class _CongestionEstimatesViewState extends State<CongestionEstimatesView> {
  final GuideEngine _guideEngine = GuideEngine();
  late final UmrahPreferencesController _prefsController;

  bool _isLoading = true;
  CongestionEstimateModel? _congestionData;

  @override
  void initState() {
    super.initState();
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());
    _loadEstimates();
  }

  Future<void> _loadEstimates() async {
    try {
      final guide = await _guideEngine.loadGuide();
      setState(() {
        _congestionData = guide.congestion;
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
              'تقديرات أوقات الزحام بالحرم',
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
                      // Mandatory Disclaimer Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: colors.accent, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: colors.accent, size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'تقدير تقريبي مبني على الأنماط المعتادة',
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 * fontScale,
                                      color: colors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _congestionData?.disclaimer ??
                                  'هذه تقديرات تقريبية استرشادية مبنية على الأنماط التاريخية لحركة الحشود، وليست بيانات حية أو لحظية. يرجى اتباع توجيهات رجال الأمن وإرشادات إدارة الحرم الميدانية.',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 13 * fontScale,
                                color: textColor,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'تاريخ مراجعة النمط: ${_congestionData?.reviewedAt ?? "2026-10-01"}',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 11 * fontScale,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'الأوقات المعتادة على مدار اليوم',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Pattern Cards
                      if (_congestionData != null)
                        ..._congestionData!.patterns.map(
                          (pattern) => _buildPatternCard(
                            pattern,
                            colors,
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

  Widget _buildPatternCard(
    CongestionPatternModel pattern,
    AppColorsExtension colors,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    Color levelColor;
    switch (pattern.levelCode) {
      case 'low':
        levelColor = Colors.green.shade700;
        break;
      case 'medium':
        levelColor = Colors.blue.shade700;
        break;
      case 'medium_high':
        levelColor = Colors.orange.shade800;
        break;
      case 'peak':
        levelColor = Colors.red.shade700;
        break;
      default:
        levelColor = colors.accent;
    }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.timeTitle,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: (isElderly ? 18 : 16) * fontScale,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pattern.timeRange,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13 * fontScale,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: levelColor.withAlpha(100)),
                ),
                child: Text(
                  pattern.crowdLevel,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              value: pattern.levelPercent,
              backgroundColor: colors.divider.withAlpha(90),
              valueColor: AlwaysStoppedAnimation<Color>(levelColor),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            pattern.notes,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13 * fontScale,
              color: textColor,
              height: 1.45,
            ),
          ),

          if (pattern.tip.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: colors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pattern.tip,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12 * fontScale,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
