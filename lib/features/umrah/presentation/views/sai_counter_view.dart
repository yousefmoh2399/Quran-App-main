import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/sai_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';

class SaiCounterView extends StatefulWidget {
  const SaiCounterView({super.key});

  @override
  State<SaiCounterView> createState() => _SaiCounterViewState();
}

class _SaiCounterViewState extends State<SaiCounterView>
    with SingleTickerProviderStateMixin {
  late final SaiController _controller;
  late final UmrahPreferencesController _prefsController;
  late final AnimationController _animController;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(SaiController());
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;
    final disableAnim = MediaQuery.disableAnimationsOf(context);

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
              'عدّاد السعي (الصفا والمروة)',
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
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colors.textMuted),
                tooltip: 'إعادة ضبط السعي',
                onPressed: () => _confirmReset(context),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Direction Track Card
                RepaintBoundary(
                  child: disableAnim
                      ? _buildDirectionTrackCard(
                          colors,
                          primaryColor,
                          textColor,
                          fontScale,
                          isElderly,
                        )
                      : ScaleTransition(
                          scale: _slideAnimation,
                          child: _buildDirectionTrackCard(
                            colors,
                            primaryColor,
                            textColor,
                            fontScale,
                            isElderly,
                          ),
                        ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Finished Banner
                if (_controller.isFinished.value)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.green, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.celebration, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'الحمد لله! تم إتمام 7 أشواط سعي عند المروة',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 15 * fontScale,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Green Light Zone Alert Card (الميلين الأخضرين)
                _buildGreenZoneCard(
                  colors,
                  fontScale,
                  isElderly,
                ),

                const SizedBox(height: AppSpacing.md),

                // Action Buttons (Complete & Undo)
                _buildActionButtons(
                  colors,
                  primaryColor,
                  fontScale,
                  isElderly,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Lap Dua Card
                _buildLapDuaCard(
                  colors,
                  fontScale,
                  isElderly,
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDirectionTrackCard(
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    final lap = _controller.currentLap.value;
    final isDone = _controller.isFinished.value;
    final from = _controller.currentFrom;
    final to = _controller.currentTo;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          // Current Lap Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الشوط الحالي',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 14 * fontScale,
                  color: colors.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  isDone ? 'اكتمل السعي' : 'الشوط ${_controller.activeLapNumber} من 7',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Visual Track between Safa and Marwah
          Row(
            children: [
              // Start Mountain
              _buildMountainNode(
                title: from,
                isCurrent: true,
                isSafa: from == 'الصفا',
                primaryColor: primaryColor,
                fontScale: fontScale,
                isElderly: isElderly,
              ),

              // Path with moving indicator
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: isElderly ? 32 : 26,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'متجه إلى $to',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * fontScale,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: lap / 7.0,
                      backgroundColor: colors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),

              // Destination Mountain
              _buildMountainNode(
                title: to,
                isCurrent: false,
                isSafa: to == 'الصفا',
                primaryColor: primaryColor,
                fontScale: fontScale,
                isElderly: isElderly,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 7 Segment Pills Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final isLapDone = index < lap;
              final isLapActive = index == lap && !isDone;

              return Container(
                width: isElderly ? 34 : 28,
                height: isElderly ? 34 : 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLapDone
                      ? colors.accent
                      : isLapActive
                          ? primaryColor
                          : colors.divider.withAlpha(90),
                  border: isLapActive
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: isElderly ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: (isLapDone || isLapActive) ? Colors.white : textColor,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMountainNode({
    required String title,
    required bool isCurrent,
    required bool isSafa,
    required Color primaryColor,
    required double fontScale,
    required bool isElderly,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: isElderly ? 26 : 22,
          backgroundColor: isCurrent ? primaryColor : Colors.grey.shade400,
          child: Icon(
            isSafa ? Icons.terrain_rounded : Icons.landscape_rounded,
            color: Colors.white,
            size: isElderly ? 26 : 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.bold,
            fontSize: 13 * fontScale,
            color: isCurrent ? primaryColor : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildGreenZoneCard(
    AppColorsExtension colors,
    double fontScale,
    bool isElderly,
  ) {
    final isActive = _controller.isGreenZoneAlertActive.value;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF0F5C4A).withAlpha(40)
            : const Color(0xFF1B5E20).withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isActive ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
          width: isActive ? 2.0 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00C853),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تنبيه: بين الميلين الأخضرين (المنطقة الخضراء)',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * fontScale,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'يُسن للرجال الهرولة والإسراع في المشي بين العلمين الأخضرين في المسعى، بينما تمشي النساء بالمشية المعتادة.',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13 * fontScale,
              color: colors.text,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
              foregroundColor: isActive ? Colors.white : const Color(0xFF1B5E20),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              minimumSize: Size(double.infinity, isElderly ? 52 : 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: () => _controller.toggleGreenZone(),
            icon: Icon(
              isActive ? Icons.check_circle : Icons.directions_run_rounded,
              size: 20,
            ),
            label: Text(
              isActive
                  ? 'أنت الآن في المنطقة الخضراء (انقر لإنهاء الهرولة)'
                  : 'دخول المنطقة الخضراء (بدء الهرولة للرجال)',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 13 * fontScale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    AppColorsExtension colors,
    Color primaryColor,
    double fontScale,
    bool isElderly,
  ) {
    return Row(
      children: [
        // Undo button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: Size(isElderly ? 95 : 80, isElderly ? 66 : 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onPressed: _controller.currentLap.value > 0
              ? () => _controller.undoLap()
              : null,
          icon: const Icon(Icons.undo, size: 20),
          label: Text(
            'تراجع',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 14 * fontScale,
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        // Complete Lap button
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _controller.isFinished.value
                  ? Colors.green.shade700
                  : primaryColor,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, isElderly ? 68 : 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              elevation: 3,
            ),
            onPressed: () {
              if (_controller.currentLap.value < 7) {
                _controller.completeLap();
                _animController.forward(from: 0.0);
              }
            },
            icon: Icon(
              _controller.isFinished.value ? Icons.check_circle : Icons.add_circle,
              size: isElderly ? 26 : 22,
            ),
            label: Text(
              _controller.isFinished.value
                  ? 'تم إكمال جميع أشواط السعي'
                  : 'إتمام الشوط ${_controller.activeLapNumber} (${_controller.currentFrom} إلى ${_controller.currentTo})',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: (isElderly ? 16 : 14) * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLapDuaCard(
    AppColorsExtension colors,
    double fontScale,
    bool isElderly,
  ) {
    final dua = _controller.currentLapDua;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: colors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dua?.title ?? 'دعاء شوط السعي',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 15 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
              ),
              if (dua != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: colors.textMuted,
                  tooltip: 'نسخ الدعاء',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: dua.arabicText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ الدعاء'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
          ),
          const Divider(height: 18),
          Text(
            dua?.arabicText ??
                'إِنَّ الصَّفَا وَالْمَرْوَةَ مِن شَعَائِرِ اللَّهِ ۖ أَبْدَأُ بِمَا بَدَأَ اللَّهُ بِهِ، لا إِلَهَ إِلا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: (isElderly ? 26 : 20) * fontScale,
              height: 1.9,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'المصدر: ${dua?.source ?? "نص تجريبي - يحتاج مراجعة: صحيح مسلم"}',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11 * fontScale,
              color: colors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة ضبط عدّاد السعي'),
        content: const Text('هل تريد تصفير عداد السعي والبدء من الشوط الأول عند الصفا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.resetSai();
            },
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
  }
}
