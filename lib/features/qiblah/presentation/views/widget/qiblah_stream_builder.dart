import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/core/util/widgets/kaaba_icon.dart';

class QiblahStreamBuilder extends StatefulWidget {
  final AnimationController animationController;
  final double begin;
  final double qiblaDirection;
  final double userLatitude;
  final double userLongitude;

  const QiblahStreamBuilder({
    super.key,
    required this.animationController,
    required this.begin,
    required this.qiblaDirection,
    this.userLatitude = 30.0444,
    this.userLongitude = 31.2357,
  });

  @override
  State<QiblahStreamBuilder> createState() => _QiblahStreamBuilderState();
}

class _QiblahStreamBuilderState extends State<QiblahStreamBuilder> {
  static double _lastKnownHeading = 0.0;
  static bool _hasReceivedHeading = false;

  Timer? _sensorTimeoutTimer;
  bool _sensorUnavailable = false;

  late Animation<double> animation;
  double begin = 0.0;
  bool _hasVibrated = false;
  int _selectedMode = 0; // 0: Compass, 1: Geographic Radar & Distance

  @override
  void initState() {
    super.initState();
    animation = Tween<double>(begin: begin, end: begin).animate(widget.animationController);

    // If running on simulator or device without heading updates within 2 seconds,
    // fallback gracefully to showing calculated Qiblah angle rather than infinite loading spinner.
    _sensorTimeoutTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!_hasReceivedHeading && mounted) {
        setState(() {
          _sensorUnavailable = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_hasReceivedHeading &&
            !_sensorUnavailable) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
                AppSpacing.verticalMd,
                Text(
                  'جاري قراءة مستشعر البوصلة...',
                  style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError && !_hasReceivedHeading && !_sensorUnavailable) {
          return const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'خطأ في قراءة البوصلة',
            message: 'تأكد من وجود مستشعر البوصلة في جهازك وتفعيله',
          );
        }

        final compassEvent = snapshot.data;
        if (compassEvent?.heading != null) {
          _lastKnownHeading = compassEvent!.heading!;
          _hasReceivedHeading = true;
        }

        final double currentHeading = _hasReceivedHeading ? _lastKnownHeading : 0.0;
        final double headingRad = currentHeading * (pi / 180);
        final double qiblaRad = widget.qiblaDirection * (pi / 180);
        final double diffAngle = qiblaRad - headingRad;

        // Check if phone is aligned with Qiblah within ±3 degrees
        final double diffDeg = ((widget.qiblaDirection - currentHeading + 360) % 360);
        final bool isAligned = diffDeg < 4 || diffDeg > 356;

        if (isAligned && !_hasVibrated) {
          AppHaptics.qiblaAligned();
          _hasVibrated = true;
        } else if (!isAligned && (diffDeg >= 6 && diffDeg <= 354)) {
          _hasVibrated = false;
        }

        animation = Tween<double>(
          begin: begin,
          end: diffAngle,
        ).animate(widget.animationController);

        begin = diffAngle;
        widget.animationController.forward(from: 0);

        final double distanceKm = Geolocator.distanceBetween(
          widget.userLatitude,
          widget.userLongitude,
          21.422487,
          39.826206,
        ) / 1000;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mode switcher: Compass vs Map/Radar
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.borderFull,
                  border: Border.all(color: colors.divider),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      index: 0,
                      label: 'البوصلة الدائرية',
                      icon: Icons.explore_rounded,
                      colors: colors,
                    ),
                    _buildModeButton(
                      index: 1,
                      label: 'الرادار والمسافة',
                      icon: Icons.radar_rounded,
                      colors: colors,
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalMd,
              // Distance to Kaaba badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  borderRadius: AppRadius.borderFull,
                  border: Border.all(color: colors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const KaabaIcon(size: 18),
                    AppSpacing.horizontalXs,
                    Flexible(
                      child: Text(
                        'المسافة إلى الكعبة المشرفة: ${distanceKm.toStringAsFixed(0)} كم',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalMd,
              if (!_hasReceivedHeading) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.08),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: colors.primary.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.explore_outlined, size: 20, color: colors.primary),
                      AppSpacing.horizontalSm,
                      Expanded(
                        child: Text(
                          'المستشعر المغناطيسي غير متوفر على المحاكي. تم توجيه السهم نحو زاوية القبلة لموقعك (${widget.qiblaDirection.toInt()}° بالنسبة للشمال).',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_hasReceivedHeading && compassEvent?.accuracy != null && compassEvent!.accuracy! > 15) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.screen_rotation_rounded, size: 18, color: Colors.amber),
                      AppSpacing.horizontalSm,
                      Expanded(
                        child: Text(
                          'دقة البوصلة منخفضة: حرّك الهاتف في الهواء على شكل رقم 8 (∞) لمعايرة المستشعر',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    Flexible(
                      child: Text(
                        isAligned
                            ? 'أنت باتجاه القبلة المشرفة الآن'
                            : 'أدر الهاتف حتى يتطابق المؤشر مع الكعبة',
                        textAlign: TextAlign.center,
                        style: textTheme.labelLarge?.copyWith(
                          color: isAligned ? colors.primary : colors.text,
                          fontWeight: FontWeight.bold,
                        ),
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
              // View Modes: Compass or Radar
              if (_selectedMode == 0)
                _buildCompassView(colors, isAligned)
              else
                _buildRadarMapView(colors, isAligned, diffDeg, distanceKm),
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
                        _selectedMode == 0
                            ? 'ضع الهاتف على سطح مستوٍ أو ارفعه أمامك أفقياً، وأبعده عن الأجهزة المعدنية لدقة أعلى.'
                            : 'يعرض الرادار خط المحاذاة المباشر بين موقعك الجغرافي والكعبة المشرفة.',
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

  Widget _buildModeButton({
    required int index,
    required String label,
    required IconData icon,
    required AppColorsExtension colors,
  }) {
    final isSelected = _selectedMode == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: AppRadius.borderFull,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : colors.textMuted,
            ),
            AppSpacing.horizontalXs,
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassView(AppColorsExtension colors, bool isAligned) {
    return Center(
      child: SizedBox(
        width: 270,
        height: 270,
        child: Stack(
          alignment: Alignment.center,
          children: [
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
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: animation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isAligned ? colors.primary.withOpacity(0.15) : colors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isAligned ? colors.primary : colors.divider,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isAligned ? colors.primary : Colors.black)
                                      .withOpacity(0.18),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: KaabaIcon(
                              size: 30,
                              hasGlow: isAligned,
                              glowColor: colors.primary,
                            ),
                          ),
                          AppSpacing.verticalXs,
                          Container(
                            width: 4,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isAligned ? colors.primary : colors.accent,
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
    );
  }

  Widget _buildRadarMapView(
    AppColorsExtension colors,
    bool isAligned,
    double diffDeg,
    double distanceKm,
  ) {
    return Center(
      child: SizedBox(
        width: 270,
        height: 270,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Radar concentric circles
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(color: colors.divider, width: 1.5),
              ),
            ),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.divider.withOpacity(0.5), width: 1),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.divider.withOpacity(0.5), width: 1),
              ),
            ),
            // Crosshairs
            Container(width: 260, height: 1, color: colors.divider.withOpacity(0.3)),
            Container(width: 1, height: 260, color: colors.divider.withOpacity(0.3)),
            // Animated pointer ray
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: animation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Direction ray towards Kaaba
                      Positioned(
                        top: 20,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAligned ? colors.primary : colors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAligned ? colors.primary : colors.accent)
                                        .withOpacity(0.4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: KaabaIcon(
                                size: 22,
                                hasGlow: isAligned,
                                glowColor: colors.primary,
                              ),
                            ),
                            Container(
                              width: 3,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    isAligned ? colors.primary : colors.accent,
                                    colors.primary.withOpacity(0.1),
                                  ],
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
            ),
            // User location pin at center
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.person_pin_circle_rounded, size: 18, color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
