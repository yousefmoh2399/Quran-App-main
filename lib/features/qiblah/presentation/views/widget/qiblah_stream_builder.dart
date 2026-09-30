import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';

class QiblahStreamBuilder extends StatefulWidget {
  final AnimationController animationController;
  final double begin;
  final double qiblaDirection;

  const QiblahStreamBuilder({
    super.key,
    required this.animationController,
    required this.begin,
    required this.qiblaDirection,
  });

  @override
  State<QiblahStreamBuilder> createState() => _QiblahStreamBuilderState();
}

class _QiblahStreamBuilderState extends State<QiblahStreamBuilder> {
  late Animation<double> animation;
  double begin = 0.0;
  bool _hasVibrated = false;

  @override
  void initState() {
    super.initState();
    animation = Tween<double>(begin: begin, end: begin).animate(widget.animationController);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'خطأ في قراءة البوصلة',
            message: 'تأكد من وجود مستشعر البوصلة في جهازك وتفعيله',
          );
        }

        final compassEvent = snapshot.data;
        if (compassEvent == null || compassEvent.heading == null) {
          return const EmptyState(
            icon: Icons.explore_off_rounded,
            title: 'مستشعر البوصلة غير متوفر',
            message: 'تعذر الحصول على قراءات اتجاه الهاتف حالياً',
          );
        }

        final double currentHeading = compassEvent.heading!;
        final double headingRad = currentHeading * (pi / 180);
        final double qiblaRad = widget.qiblaDirection * (pi / 180);
        final double diffAngle = qiblaRad - headingRad;

        // Check if phone is aligned with Qiblah within ±3 degrees
        final double diffDeg = ((widget.qiblaDirection - currentHeading + 360) % 360);
        final bool isAligned = diffDeg < 4 || diffDeg > 356;

        if (isAligned && !_hasVibrated) {
          HapticFeedback.mediumImpact();
          _hasVibrated = true;
        } else if (!isAligned) {
          _hasVibrated = false;
        }

        animation = Tween<double>(
          begin: begin,
          end: diffAngle,
        ).animate(widget.animationController);

        begin = diffAngle;
        widget.animationController.forward(from: 0);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Alignment status card
              AppCard(
                variant: isAligned ? AppCardVariant.elevated : AppCardVariant.outlined,
                backgroundColor: isAligned
                    ? colors.primary.withOpacity(0.12)
                    : colors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAligned
                          ? Icons.check_circle_rounded
                          : Icons.explore_rounded,
                      color: isAligned ? colors.primary : colors.accent,
                      size: 22,
                    ),
                    AppSpacing.horizontalSm,
                    Text(
                      isAligned
                          ? 'أنت باتجاه القبلة المشرفة الآن 🕋'
                          : 'أدر الهاتف حتى يتطابق المؤشر مع الكعبة',
                      style: textTheme.labelLarge?.copyWith(
                        color: isAligned ? colors.primary : colors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalLg,
              // Heading degrees and Qiblah degrees info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        'الاتجاه الحالي',
                        style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        '${currentHeading.toInt()}°',
                        style: textTheme.headlineSmall?.copyWith(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 36, color: colors.divider),
                  Column(
                    children: [
                      Text(
                        'زاوية القبلة',
                        style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        '${widget.qiblaDirection.toInt()}°',
                        style: textTheme.headlineSmall?.copyWith(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.verticalXl,
              // Modern Compass Dial
              Center(
                child: SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass outer ring with shadow
                      Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface,
                          border: Border.all(
                            color: isAligned ? colors.primary : colors.divider,
                            width: isAligned ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isAligned
                                  ? colors.primary.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Rotating Compass Dial
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: animation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Cardinal points
                                const Positioned(
                                  top: 14,
                                  child: Text('ش', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const Positioned(
                                  bottom: 14,
                                  child: Text('ج', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const Positioned(
                                  right: 14,
                                  child: Text('ق', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                const Positioned(
                                  left: 14,
                                  child: Text('غ', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                // Center Kaaba pointer
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: AppSpacing.paddingXs,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.primary.withOpacity(0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.navigation_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    AppSpacing.verticalXs,
                                    Container(
                                      width: 4,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: colors.primary,
                                        borderRadius: AppRadius.borderFull,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Fixed Center Pivot
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalXl,
              // Instructions Card
              AppCard(
                variant: AppCardVariant.flat,
                padding: AppSpacing.paddingMd,
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: colors.textMuted),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: Text(
                        'ضع الهاتف على سطح مستوٍ وأبعده عن الأجهزة المعدنية والمغناطيسية لدقة أعلى.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
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
      },
    );
  }
}
