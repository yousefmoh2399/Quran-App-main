import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';

class AzkarCircularCounter extends StatelessWidget {
  final int targetCount;
  final int remainingCount;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const AzkarCircularCounter({
    super.key,
    required this.targetCount,
    required this.remainingCount,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final isCompleted = remainingCount <= 0;
    final progress = targetCount > 0
        ? ((targetCount - remainingCount) / targetCount).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (!isCompleted) {
              if (remainingCount <= 1) {
                AppHaptics.itemCompleted();
              } else {
                AppHaptics.tap();
              }
              onTap();
            } else {
              AppHaptics.selection();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow / background circle
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? colors.primary.withOpacity(0.15)
                      : colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(isCompleted ? 0.25 : 0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Background track
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.divider.withOpacity(0.6),
                  ),
                ),
              ),
              // Animated progress arc
              SizedBox(
                width: 96,
                height: 96,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: progress, end: progress),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? colors.primary : colors.accent,
                      ),
                    );
                  },
                ),
              ),
              // Center count or completed icon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleted) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.primary,
                      size: 36,
                    ),
                    Text(
                      'تم بحمد الله',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '$remainingCount',
                      style: textTheme.headlineMedium?.copyWith(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      'من $targetCount',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        AppSpacing.verticalSm,
        // Reset or tap hint
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCompleted ? 'اكتملت التكرارات' : 'اضغط للعد',
              style: textTheme.bodySmall?.copyWith(
                color: isCompleted ? colors.primary : colors.textMuted,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (remainingCount < targetCount) ...[
              AppSpacing.horizontalSm,
              InkWell(
                borderRadius: AppRadius.borderSm,
                onTap: onReset,
                child: Padding(
                  padding: AppSpacing.paddingXs,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: colors.textMuted,
                      ),
                      AppSpacing.horizontalXs,
                      Text(
                        'إعادة',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
