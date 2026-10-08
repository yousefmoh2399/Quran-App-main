import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/tawaf_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/widgets/umrah_filter_chip.dart';

class TawafCounterView extends StatefulWidget {
  const TawafCounterView({super.key});

  @override
  State<TawafCounterView> createState() => _TawafCounterViewState();
}

class _TawafCounterViewState extends State<TawafCounterView>
    with SingleTickerProviderStateMixin {
  late final TawafController _controller;
  late final UmrahPreferencesController _prefsController;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(TawafController());
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.stopSensor();
    Get.delete<TawafController>();
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
              'عدّاد طواف الكعبة المشرفة',
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
                tooltip: 'إعادة ضبط الطواف',
                onPressed: () => _confirmReset(context),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Sensor rotation candidate alert prompt (if triggered)
                if (_controller.showSensorPrompt.value)
                  _buildSensorConfirmationCard(
                    colors,
                    primaryColor,
                    fontScale,
                  ),

                // Tawaf Type selector pills
                _buildTawafTypeSelector(colors, primaryColor, fontScale, isElderly),

                const SizedBox(height: AppSpacing.sm),

                // Interactive Circle & Kaaba representation
                Center(
                  child: RepaintBoundary(
                    child: disableAnim
                        ? _buildCircularCounter(
                            colors,
                            primaryColor,
                            textColor,
                            fontScale,
                            isElderly,
                          )
                        : ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildCircularCounter(
                              colors,
                              primaryColor,
                              textColor,
                              fontScale,
                              isElderly,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Completion status banner
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
                          'الحمد لله! تم إتمام 7 أشواط كاملة',
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

                // Smart Pacing & Lap Timer Card
                _buildSmartPacingCard(
                  colors,
                  primaryColor,
                  textColor,
                  fontScale,
                  isElderly,
                ),

                // Primary Action Buttons
                _buildActionButtons(
                  colors,
                  primaryColor,
                  fontScale,
                  isElderly,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Active Lap Dua Card
                _buildLapDuaCard(
                  colors,
                  fontScale,
                  isElderly,
                ),

                const SizedBox(height: AppSpacing.md),

                // Experimental Sensor Tracking Section
                _buildSensorTrackingSection(
                  colors,
                  primaryColor,
                  textColor,
                  fontScale,
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTawafTypeSelector(
    AppColorsExtension colors,
    Color primaryColor,
    double fontScale,
    bool isElderly,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TawafController.availableTawafTypes.map((type) {
          final isSelected = _controller.tawafType.value == type;
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: UmrahFilterChip(
              label: type,
              isSelected: isSelected,
              fontScale: fontScale,
              isElderly: isElderly,
              onTap: () => _controller.setTawafType(type),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCircularCounter(
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    final lap = _controller.currentLap.value;
    final size = isElderly ? 270.0 : 240.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _TawafCirclePainter(
            completedLaps: lap,
            totalLaps: 7,
            accentColor: colors.accent,
            baseColor: colors.divider.withAlpha(90),
            primaryColor: primaryColor,
          ),
        ),
        // Central Kaaba Motif and Lap Counter
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stylized Kaaba Geometric Icon
            Container(
              width: isElderly ? 68 : 56,
              height: isElderly ? 68 : 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Golden band across upper portion
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 5,
                      color: colors.accent,
                    ),
                  ),
                  // Golden door icon hint
                  Positioned(
                    bottom: 6,
                    right: 12,
                    child: Container(
                      width: 10,
                      height: 18,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.tawafType.value,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12 * fontScale,
                fontWeight: FontWeight.bold,
                color: colors.accent,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$lap',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: (isElderly ? 44 : 36) * fontScale,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  ' / 7',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: (isElderly ? 20 : 16) * fontScale,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
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

        // Main Complete Lap button
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
                  ? 'تم إكمال جميع الأشواط'
                  : 'إتمام الشوط ${_controller.currentLap.value + 1}',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: (isElderly ? 18 : 16) * fontScale,
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
                  dua != null ? 'دعاء الشوط ${_controller.activeLapNumber}' : 'دعاء الطواف',
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
                'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
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
            'المصدر: ${dua?.source ?? "سنن أبي داود"}',
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

  Widget _buildSensorTrackingSection(
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
  ) {
    return Container(
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
              Icon(Icons.explore_outlined, color: primaryColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تتبع دوران البوصلة (تجريبي)',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 15 * fontScale,
                    color: textColor,
                  ),
                ),
              ),
              Switch(
                value: _controller.isSensorTrackingEnabled.value,
                onChanged: (_) => _controller.toggleSensorTracking(),
                activeColor: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: colors.accent.withAlpha(50)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: colors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تنبيه: التتبع بالحساسات ميزة تجريبية وقد تخطئ بسبب التداخل المغناطيسي في الحرم. لا تعتمد على GPS وتتطلب دائماً تأكيدك اليدوي.',
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
          if (_controller.isSensorTrackingEnabled.value) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'الدوران المجمع نحو 360°: ${(_controller.accumulator.rotationProgress * 100).toInt()}%',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12 * fontScale,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: _controller.accumulator.rotationProgress,
              backgroundColor: colors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              minHeight: 6,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSensorConfirmationCard(
    AppColorsExtension colors,
    Color primaryColor,
    double fontScale,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.accent.withAlpha(30),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.accent, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: colors.accent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'استشعار إتمام دوران كامل (360°)!',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 15 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'هل أتممت الشوط الفعلي حول الكعبة؟ يرجى التأكيد يدوياً لاحتسابه.',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13 * fontScale,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _controller.dismissSensorPrompt(),
                child: const Text('تجاهل'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _controller.confirmSensorLap(),
                child: const Text('تأكيد واحتساب الشوط'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة ضبط عدّاد الطواف'),
        content: const Text('هل تريد تصفير عداد الأشواط والبدء من الشوط الأول؟'),
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
              _controller.resetTawaf();
            },
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartPacingCard(
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    final totalSec = _controller.totalElapsedSeconds;
    final avgSec = _controller.averageLapSeconds;
    final remainingSec = _controller.estimatedRemainingSeconds;
    final isRunning = _controller.isTimerRunning.value;
    final isFinished = _controller.isFinished.value;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'مؤقت الطواف والسرعة:',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              if (!isFinished)
                InkWell(
                  onTap: () => _controller.toggleTimer(),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRunning ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          size: 15,
                          color: isRunning ? Colors.orange.shade800 : primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isRunning ? 'إيقاف مؤقت' : 'استئناف',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: isRunning ? Colors.orange.shade800 : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPacingStat(
                  label: 'الوقت الإجمالي',
                  value: _controller.formatTime(totalSec),
                  icon: Icons.access_time_rounded,
                  colors: colors,
                  textColor: textColor,
                  fontScale: fontScale,
                ),
              ),
              Container(width: 1, height: 26, color: colors.divider),
              Expanded(
                child: _buildPacingStat(
                  label: 'متوسط الشوط',
                  value: _controller.formatTime(avgSec),
                  icon: Icons.speed_rounded,
                  colors: colors,
                  textColor: textColor,
                  fontScale: fontScale,
                ),
              ),
              Container(width: 1, height: 26, color: colors.divider),
              Expanded(
                child: _buildPacingStat(
                  label: isFinished ? 'الحالة' : 'المتبقي التقديري',
                  value: isFinished ? 'مكتمل' : _controller.formatTime(remainingSec),
                  icon: isFinished ? Icons.check_circle_outline : Icons.hourglass_bottom_rounded,
                  colors: colors,
                  textColor: isFinished ? Colors.green.shade700 : textColor,
                  fontScale: fontScale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPacingStat({
    required String label,
    required String value,
    required IconData icon,
    required AppColorsExtension colors,
    required Color textColor,
    required double fontScale,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 10 * fontScale,
            color: colors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: colors.textMuted),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TawafCirclePainter extends CustomPainter {
  final int completedLaps;
  final int totalLaps;
  final Color accentColor;
  final Color baseColor;
  final Color primaryColor;

  _TawafCirclePainter({
    required this.completedLaps,
    required this.totalLaps,
    required this.accentColor,
    required this.baseColor,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;
    const strokeWidth = 14.0;
    const gapAngle = (math.pi * 2) * 0.025;
    final sweepPerSegment = ((math.pi * 2) - (gapAngle * totalLaps)) / totalLaps;

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start angle at top (-pi / 2) and advance counter-clockwise
    for (int i = 0; i < totalLaps; i++) {
      final startAngle = (-math.pi / 2) - (i * (sweepPerSegment + gapAngle));
      final isDone = i < completedLaps;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        -sweepPerSegment,
        false,
        isDone ? activePaint : basePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TawafCirclePainter oldDelegate) {
    return oldDelegate.completedLaps != completedLaps ||
        oldDelegate.accentColor != accentColor;
  }
}
