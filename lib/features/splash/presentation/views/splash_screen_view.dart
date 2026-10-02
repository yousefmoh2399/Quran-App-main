import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

import 'package:quran_app_android/core/service/navigation/app_navigation_service.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _strokeAnimation;
  late Animation<double> _dotsAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Initial emergence from the native launcher icon
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // Calligraphy stroke writing (0.1 to 0.70)
    _strokeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.72, curve: Curves.easeInOutCubic),
      ),
    );

    // Dots and diacritics bounce in (0.68 to 0.88)
    _dotsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.88, curve: Curves.elasticOut),
      ),
    );

    // Subtitle & Ayah fade in (0.75 to 1.0)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() async {
    final settings = Get.find<SettingsServices>();
    final bool hasOnboarded =
        settings.sharedPref?.getBool('onboarding') ?? false;

    await Get.offAllNamed(
      hasOnboarded ? AppRoutes.home : AppRoutes.onboarding,
    );
    if (hasOnboarded) {
      AppNavigationService.instance.processColdStartNavigationIfNeeded();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09261E),
      body: Stack(
        children: [
          // 1. Subtle Radial Ambient Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 0.9,
                  colors: [
                    Color(0xFF134E3E), // rich emerald center
                    Color(0xFF09261E), // deep edge
                    Color(0xFF051712), // dark vignette
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 2. Center Animated Calligraphy Canvas
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decorative Arch / Geometric Circle Frame
                      SizedBox(
                        width: 280,
                        height: 240,
                        child: CustomPaint(
                          painter: CalligraphyWritingPainter(
                            strokeProgress: _strokeAnimation.value,
                            dotsProgress: _dotsAnimation.value,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Quranic Motto & Title Fade-in
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'تَقَرَّبْ',
                              style: TextStyle(
                                fontFamily: AppTypography.quranFont,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: const Color(0xFFE5C06B),
                                shadows: [
                                  Shadow(
                                    blurRadius: 16.0,
                                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                                    offset: Offset.zero,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF134E3E).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '« فَاذْكُرُونِي أَذْكُرْكُمْ »',
                                style: TextStyle(
                                  fontFamily: AppTypography.quranFont,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFFF6D6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'مصحف • أذكار • صلاة • تدبر',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8CAFA0),
                                letterSpacing: 1.0,
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
          ),

          // Bottom Islamic Crescent Emblem
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFadeAnimation,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 1,
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: const Color(0xFFD4AF37).withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 1,
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that creates the dynamic "handwritten calligraphy" effect
class CalligraphyWritingPainter extends CustomPainter {
  final double strokeProgress;
  final double dotsProgress;

  CalligraphyWritingPainter({
    required this.strokeProgress,
    required this.dotsProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // 1. Subtle Outer Islamic Ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFD4AF37).withOpacity(0.35 * strokeProgress);
    canvas.drawCircle(center, w * 0.44, ringPaint);

    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFFE5C06B).withOpacity(0.25 * strokeProgress);
    canvas.drawCircle(center, w * 0.40, innerRingPaint);

    // 2. Construct the interconnected Calligraphy Path for "تَقَرَّبْ"
    // Flowing from Right to Left (RTL):
    // Taa hook -> Qaaf circle & loop -> Raa descending arc -> Baa wide bowl
    final Path calligraphyPath = Path();

    // Start at right: Initial Taa hook
    calligraphyPath.moveTo(w * 0.78, h * 0.46);
    calligraphyPath.cubicTo(
      w * 0.74, h * 0.44,
      w * 0.70, h * 0.47,
      w * 0.65, h * 0.50,
    );

    // Transition into Qaaf loop (circling upward then back down)
    calligraphyPath.cubicTo(
      w * 0.63, h * 0.40,
      w * 0.55, h * 0.38,
      w * 0.53, h * 0.46,
    );
    calligraphyPath.cubicTo(
      w * 0.51, h * 0.53,
      w * 0.58, h * 0.55,
      w * 0.55, h * 0.51,
    );

    // Connecting toward Raa (descending swooping crescent tail)
    calligraphyPath.cubicTo(
      w * 0.53, h * 0.52,
      w * 0.49, h * 0.55,
      w * 0.47, h * 0.62,
    );
    calligraphyPath.cubicTo(
      w * 0.44, h * 0.72,
      w * 0.38, h * 0.75,
      w * 0.34, h * 0.71,
    );

    // Raa swoops under baseline and connects into Baa
    calligraphyPath.cubicTo(
      w * 0.32, h * 0.68,
      w * 0.34, h * 0.58,
      w * 0.30, h * 0.54,
    );

    // Baa bowl (curving down to baseline and extending left with upward tail)
    calligraphyPath.cubicTo(
      w * 0.28, h * 0.58,
      w * 0.25, h * 0.64,
      w * 0.20, h * 0.64,
    );
    calligraphyPath.cubicTo(
      w * 0.16, h * 0.64,
      w * 0.14, h * 0.58,
      w * 0.15, h * 0.51,
    );

    // Secondary decorative flourishing baseline swoosh
    final Path flourishPath = Path();
    flourishPath.moveTo(w * 0.82, h * 0.62);
    flourishPath.quadraticBezierTo(
      w * 0.50, h * 0.70,
      w * 0.18, h * 0.62,
    );

    // 3. Draw animated calligraphy strokes using PathMetric
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF6D6), // luminous gold
          Color(0xFFE5C06B), // rich warm gold
          Color(0xFFB8892B), // antique gold
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Outer glow for the gold pen stroke
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFD4AF37).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    Offset currentPenTip = Offset.zero;

    // Draw main calligraphy line up to strokeProgress
    for (final metric in calligraphyPath.computeMetrics()) {
      final double extractLength = metric.length * strokeProgress.clamp(0.0, 1.0);
      final Path extracted = metric.extractPath(0.0, extractLength);
      canvas.drawPath(extracted, glowPaint);
      canvas.drawPath(extracted, strokePaint);

      final tangent = metric.getTangentForOffset(extractLength);
      if (tangent != null) {
        currentPenTip = tangent.position;
      }
    }

    // Draw flourishing baseline under text
    if (strokeProgress > 0.4) {
      final double subProgress = ((strokeProgress - 0.4) / 0.6).clamp(0.0, 1.0);
      for (final metric in flourishPath.computeMetrics()) {
        final double extractLength = metric.length * subProgress;
        final Path extracted = metric.extractPath(0.0, extractLength);
        final fPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFD4AF37).withOpacity(0.6 * subProgress);
        canvas.drawPath(extracted, fPaint);
      }
    }

    // 4. Glowing Pen Tip Particle (follows the active calligraphy stroke!)
    if (strokeProgress > 0.02 && strokeProgress < 0.98 && currentPenTip != Offset.zero) {
      // Radiant halo
      final tipGlow = Paint()
        ..color = const Color(0xFFFFE082).withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
      canvas.drawCircle(currentPenTip, 8.0, tipGlow);

      // Bright gold core
      final tipCore = Paint()..color = const Color(0xFFFFFFFF);
      canvas.drawCircle(currentPenTip, 3.5, tipCore);
    }

    // 5. Draw Arabic Calligraphy Dots and Diacritics (pop in with dotsProgress)
    if (dotsProgress > 0.0) {
      final double scale = dotsProgress;
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFFF6D6);

      final dotGlow = Paint()
        ..color = const Color(0xFFD4AF37).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      // Two diamond dots of Taa (above right)
      _drawDiamondDot(canvas, Offset(w * 0.73, h * 0.38), 4.5 * scale, dotPaint, dotGlow);
      _drawDiamondDot(canvas, Offset(w * 0.68, h * 0.36), 4.5 * scale, dotPaint, dotGlow);

      // Two diamond dots of Qaaf (above center loop)
      _drawDiamondDot(canvas, Offset(w * 0.58, h * 0.33), 4.5 * scale, dotPaint, dotGlow);
      _drawDiamondDot(canvas, Offset(w * 0.53, h * 0.32), 4.5 * scale, dotPaint, dotGlow);

      // Single diamond dot of Baa (below left bowl)
      _drawDiamondDot(canvas, Offset(w * 0.20, h * 0.72), 5.0 * scale, dotPaint, dotGlow);

      // Tashkeel: Shaddah (ّ) above Raa
      _drawShaddah(canvas, Offset(w * 0.40, h * 0.42), scale);

      // Tashkeel: Fatha (َ) slant above Taa
      _drawFatha(canvas, Offset(w * 0.72, h * 0.30), scale);
    }
  }

  void _drawDiamondDot(Canvas canvas, Offset center, double size, Paint fill, Paint glow) {
    final Path path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size, center.dy);
    path.close();
    canvas.drawPath(path, glow);
    canvas.drawPath(path, fill);
  }

  void _drawFatha(Canvas canvas, Offset pos, double scale) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE5C06B);
    canvas.drawLine(
      Offset(pos.dx + 6 * scale, pos.dy - 3 * scale),
      Offset(pos.dx - 6 * scale, pos.dy + 3 * scale),
      p,
    );
  }

  void _drawShaddah(Canvas canvas, Offset pos, double scale) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE5C06B);

    final path = Path();
    // Two mini curves of shaddah (w shape)
    path.moveTo(pos.dx + 6 * scale, pos.dy);
    path.quadraticBezierTo(pos.dx + 3 * scale, pos.dy + 4 * scale, pos.dx, pos.dy);
    path.quadraticBezierTo(pos.dx - 3 * scale, pos.dy + 4 * scale, pos.dx - 6 * scale, pos.dy);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CalligraphyWritingPainter oldDelegate) {
    return oldDelegate.strokeProgress != strokeProgress ||
        oldDelegate.dotsProgress != dotsProgress;
  }
}
