import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/features/pngtree/presentation/view_model/pngTree_view_model.dart';

class ModernTasbeehRing extends StatefulWidget {
  final PngTreeViewModel controller;

  const ModernTasbeehRing({super.key, required this.controller});

  @override
  State<ModernTasbeehRing> createState() => _ModernTasbeehRingState();
}

class _ModernTasbeehRingState extends State<ModernTasbeehRing> {
  double _scale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _scale = 0.94);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.controller.increaseCounter();
  }

  void _handleTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final ctrl = widget.controller;

    final progress = ctrl.targetCount > 0
        ? (ctrl.counter / ctrl.targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Center(
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.12),
                  blurRadius: 28,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer subtle track
                SizedBox(
                  width: 236,
                  height: 236,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.divider.withOpacity(0.4),
                    ),
                  ),
                ),
                // Animated progress arc
                SizedBox(
                  width: 236,
                  height: 236,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: progress, end: progress),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) {
                      return CircularProgressIndicator(
                        value: val,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
                      );
                    },
                  ),
                ),
                // Center content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active Zekr text
                      Text(
                        ctrl.currentZekr,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontFamily: AppTypography.decorativeFont,
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.verticalSm,
                      // Big number
                      FittedBox(
                        child: Text(
                          '${ctrl.counter}',
                          style: textTheme.displayLarge?.copyWith(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                            fontSize: 64,
                            height: 1.1,
                          ),
                        ),
                      ),
                      AppSpacing.verticalXs,
                      // Target indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withOpacity(0.12),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          'الهدف: ${ctrl.targetCount}',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        'اضغط في أي مكان للتسبيح',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
