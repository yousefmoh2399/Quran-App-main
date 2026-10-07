import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_guide_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';

class UmrahGuideView extends StatefulWidget {
  const UmrahGuideView({super.key});

  @override
  State<UmrahGuideView> createState() => _UmrahGuideViewState();
}

class _UmrahGuideViewState extends State<UmrahGuideView>
    with SingleTickerProviderStateMixin {
  late final UmrahGuideController _controller;
  late final UmrahPreferencesController _prefsController;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(UmrahGuideController());
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    Get.delete<UmrahGuideController>();
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
      final guideTitle = _controller.guide.value?.title ?? 'دليل المناسك';

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppScaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              guideTitle,
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
                icon: Icon(
                  Icons.restart_alt,
                  color: colors.textMuted,
                ),
                tooltip: 'إعادة ضبط النسك',
                onPressed: () => _confirmReset(context),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(6),
              child: Obx(() {
                return LinearProgressIndicator(
                  value: _controller.overallProgress,
                  backgroundColor: colors.divider.withAlpha(80),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  minHeight: 4,
                );
              }),
            ),
          ),
          body: _controller.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      // Steps Horizontal Ribbon
                      _buildStepsRibbon(colors, primaryColor, textColor, isElderly),

                      // Step Content
                      Expanded(
                        child: disableAnim
                            ? _buildStepDetails(
                                colors,
                                primaryColor,
                                textColor,
                                fontScale,
                                isElderly,
                              )
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildStepDetails(
                                  colors,
                                  primaryColor,
                                  textColor,
                                  fontScale,
                                  isElderly,
                                ),
                              ),
                      ),

                      // Sticky Bottom Action Bar
                      _buildBottomActionBar(
                        colors,
                        primaryColor,
                        fontScale,
                        isElderly,
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildStepsRibbon(
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    bool isElderly,
  ) {
    return Container(
      height: isElderly ? 70 : 58,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.divider.withAlpha(90)),
        ),
      ),
      child: Obx(() {
        final guide = _controller.guide.value;
        if (guide == null) return const SizedBox.shrink();

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: guide.steps.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (context, index) {
            final step = guide.steps[index];
            final isSelected = _controller.currentStepIndex.value == index;
            final isDone = _controller.isStepCompleted(step.id);

            return InkWell(
              onTap: () {
                _controller.goToStep(index);
                _animController.forward(from: 0.0);
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : isDone
                          ? colors.accent.withAlpha(40)
                          : colors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : isDone
                            ? colors.accent
                            : colors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: isElderly ? 14 : 11,
                      backgroundColor: isSelected
                          ? Colors.white
                          : isDone
                              ? colors.accent
                              : colors.textMuted.withAlpha(40),
                      child: isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: isElderly ? 13 : 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? primaryColor : textColor,
                              ),
                            ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      step.title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: isElderly ? 15 : 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildStepDetails(
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    return Obx(() {
      final step = _controller.currentStep;
      if (step == null) {
        return const Center(child: Text('لا توجد خطوات متاحة'));
      }

      final isDone = _controller.isStepCompleted(step.id);

      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Step Banner Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDone ? colors.accent : colors.divider,
                width: isDone ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'الخطوة ${step.order} من ${_controller.guide.value?.steps.length ?? 5}',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'تمت بنجاح',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 11 * fontScale,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  step.title,
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 22 * fontScale,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (step.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.shortDescription,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 14 * fontScale,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Shortcut to dedicated interactive counter
          if (step.id == 'tawaf')
            _buildInteractiveToolButton(
              context: context,
              icon: Icons.rotate_right_rounded,
              title: 'فتح عدّاد الطواف التفاعلي (7 أشواط)',
              subtitle: 'دائرة تفاعلية حول الكعبة مع الأدعية والتتبع',
              onTap: () => Get.toNamed(AppRoutes.tawafCounter),
              colors: colors,
              primaryColor: primaryColor,
              fontScale: fontScale,
            ),

          if (step.id == 'sai')
            _buildInteractiveToolButton(
              context: context,
              icon: Icons.directions_walk_rounded,
              title: 'فتح عدّاد السعي التفاعلي (الصفا والمروة)',
              subtitle: 'تتبع 7 أشواط مع تنبيه الميلين الأخضرين',
              onTap: () => Get.toNamed(AppRoutes.saiCounter),
              colors: colors,
              primaryColor: primaryColor,
              fontScale: fontScale,
            ),

          if (step.id == 'tawaf' || step.id == 'sai')
            const SizedBox(height: AppSpacing.md),

          // Instruction card
          Container(
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
                    Icon(Icons.menu_book_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'صفة النسك وبيانه',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  step.instruction,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 16 * fontScale,
                    color: textColor,
                    height: 1.6,
                  ),
                ),
                if (step.notes != null && step.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: colors.accent.withAlpha(60)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: colors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.notes!,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 13 * fontScale,
                              color: textColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Duas Section
          if (step.duas.isNotEmpty || step.lapsDuas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'الأدعية والأذكار المأثورة',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 16 * fontScale,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...step.duas.map((dua) => _buildDuaCard(dua, colors, fontScale, isElderly)),
            ...step.lapsDuas.take(2).map((dua) => _buildDuaCard(dua, colors, fontScale, isElderly)),
          ],

          // Religious Content & Verification Attribution
          const SizedBox(height: AppSpacing.md),
          _buildSourceAttributionCard(step.source, colors, fontScale),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    });
  }

  Widget _buildInteractiveToolButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppColorsExtension colors,
    required Color primaryColor,
    required double fontScale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withAlpha(20),
              colors.accent.withAlpha(30),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.accent, width: 1.2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 15 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12 * fontScale,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDuaCard(
    DuaModel dua,
    AppColorsExtension colors,
    double fontScale,
    bool isElderly,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
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
              Expanded(
                child: Text(
                  dua.title,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 14 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
              ),
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
          const SizedBox(height: 6),
          Text(
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
          const SizedBox(height: 8),
          Text(
            'المصدر: ${dua.source}',
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

  Widget _buildSourceAttributionCard(
    ContentSourceModel source,
    AppColorsExtension colors,
    double fontScale,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.divider.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 16, color: colors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'المصدر الشرعي وتاريخ التدقيق',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: colors.textMuted,
                  ),
                ),
              ),
              Text(
                'تاريخ المراجعة: ${source.reviewedAt}',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 11 * fontScale,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${source.title} (${source.status})',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11 * fontScale,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    AppColorsExtension colors,
    Color primaryColor,
    double fontScale,
    bool isElderly,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(() {
        final step = _controller.currentStep;
        if (step == null) return const SizedBox.shrink();

        final isDone = _controller.isStepCompleted(step.id);
        final isLast = _controller.currentStepIndex.value ==
            (_controller.guide.value?.steps.length ?? 1) - 1;

        return Row(
          children: [
            // Previous button
            if (_controller.currentStepIndex.value > 0)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(isElderly ? 90 : 70, isElderly ? 58 : 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () {
                  _controller.previousStep();
                  _animController.forward(from: 0.0);
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(
                  'السابق',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13 * fontScale,
                  ),
                ),
              ),

            if (_controller.currentStepIndex.value > 0)
              const SizedBox(width: AppSpacing.sm),

            // Toggle Complete / Next button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone ? Colors.green.shade700 : primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, isElderly ? 62 : 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () async {
                  await _controller.toggleStepCompletion(step.id);
                  if (!isLast && !isDone) {
                    _controller.nextStep();
                    _animController.forward(from: 0.0);
                  }
                },
                icon: Icon(
                  isDone ? Icons.check_circle : Icons.done_all_rounded,
                  size: isElderly ? 24 : 20,
                ),
                label: Text(
                  isDone ? 'تم إتمام الخطوة (انقر للإلغاء)' : 'تم — إتمام هذه الخطوة',
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
      }),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة ضبط دليل العمرة'),
        content: const Text(
          'هل تريد إعادة ضبط جميع الخطوات والبدء من جديد؟ لن يتم حذف ملاحظات اليوميات.',
        ),
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
              _controller.resetProgress();
            },
            child: const Text('إعادة ضبط'),
          ),
        ],
      ),
    );
  }
}
