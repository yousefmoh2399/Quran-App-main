import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An authentic, pixel-perfect, vector-drawn representation of the Holy Kaaba (الكعبة المشرفة).
///
/// Implemented entirely with native Flutter [CustomPainter] canvas vector operations,
/// guaranteeing:
/// 1. 100% crisp retina rendering on all iPhone displays and sizes.
/// 2. Zero dependency on emoji glyphs or device fonts (will never produce `?` on iOS).
/// 3. Rich authentic details: Obsidian Kiswah, metallic gold belt (الحزام),
///    the Golden Door (باب الكعبة), the golden spout (الميزاب), and marble base (الشاذروان).
class KaabaIcon extends StatelessWidget {
  final double size;
  final bool hasGlow;
  final Color? glowColor;

  const KaabaIcon({
    super.key,
    this.size = 24.0,
    this.hasGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: KaabaPainter(),
        size: Size(size, size),
      ),
    );

    if (hasGlow) {
      final effectiveGlow = glowColor ?? const Color(0xFFD4AF37);
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: effectiveGlow.withOpacity(0.4),
              blurRadius: size * 0.4,
              spreadRadius: 2,
            ),
          ],
        ),
        child: icon,
      );
    }

    return icon;
  }
}

/// Native Canvas Vector Painter for the Holy Kaaba.
class KaabaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Center the Kaaba within the bounding box
    // Proportions: Cube occupies roughly 75% width and 80% height
    final double cubeW = w * 0.72;
    final double cubeH = h * 0.74;
    final double left = (w - cubeW) / 2;
    final double top = (h - cubeH) / 2 + h * 0.02;

    // Perspective parameters
    // Front face: 62% of cube width
    // Side face (Eastern wall with Door): 38% of cube width
    final double frontW = cubeW * 0.60;
    final double sideW = cubeW * 0.40;
    final double roofH = cubeH * 0.16;
    final double wallH = cubeH - roofH;

    // Coordinates:
    // P0: Top corner of front-side split
    // P1: Left-top of front wall
    // P2: Left-bottom of front wall
    // P3: Center-bottom (split between front and side)
    // P4: Right-bottom of side wall
    // P5: Right-top of side wall
    // P6: Back-top peak of roof

    final Offset pCenterTop = Offset(left + frontW, top + roofH);
    final Offset pLeftTop = Offset(left, top + roofH * 1.5);
    final Offset pLeftBottom = Offset(left, top + roofH * 1.5 + wallH);
    final Offset pCenterBottom = Offset(left + frontW, top + cubeH);
    final Offset pRightBottom = Offset(left + cubeW, top + cubeH - roofH * 0.5);
    final Offset pRightTop = Offset(left + cubeW, top + roofH * 0.6);
    final Offset pBackTop = Offset(left + frontW * 0.7, top);

    // -------------------------------------------------------------
    // 1. Shadhirwan (الشاذروان - The White Marble Base)
    // -------------------------------------------------------------
    final double baseThickness = h * 0.045;
    final Path basePath = Path()
      ..moveTo(pLeftBottom.dx - w * 0.03, pLeftBottom.dy)
      ..lineTo(pCenterBottom.dx, pCenterBottom.dy + baseThickness)
      ..lineTo(pRightBottom.dx + w * 0.03, pRightBottom.dy + baseThickness * 0.5)
      ..lineTo(pRightBottom.dx + w * 0.03, pRightBottom.dy)
      ..lineTo(pCenterBottom.dx, pCenterBottom.dy)
      ..lineTo(pLeftBottom.dx - w * 0.03, pLeftBottom.dy)
      ..close();

    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFFE8E8E4),
          Color(0xFFF8F8F6),
          Color(0xFFD6D6D0),
        ],
      ).createShader(Rect.fromLTWH(left, top + cubeH - 4, cubeW, baseThickness + 4));
    canvas.drawPath(basePath, basePaint);

    // -------------------------------------------------------------
    // 2. Kaaba Roof (سطح الكعبة المشرفة)
    // -------------------------------------------------------------
    final Path roofPath = Path()
      ..moveTo(pLeftTop.dx, pLeftTop.dy)
      ..lineTo(pBackTop.dx, pBackTop.dy)
      ..lineTo(pRightTop.dx, pRightTop.dy)
      ..lineTo(pCenterTop.dx, pCenterTop.dy)
      ..close();

    final Paint roofPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF2E2E34),
          Color(0xFF1E1E22),
          Color(0xFF16161A),
        ],
      ).createShader(Rect.fromLTWH(left, top, cubeW, roofH * 1.5));
    canvas.drawPath(roofPath, roofPaint);

    // Subtle roof inner border
    final Paint roofBorderPaint = Paint()
      ..color = const Color(0xFF3F3F46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawPath(roofPath, roofBorderPaint);

    // -------------------------------------------------------------
    // 3. Front Wall (الجدار الجنوبي/الغربي - Main Front Face)
    // -------------------------------------------------------------
    final Path frontPath = Path()
      ..moveTo(pLeftTop.dx, pLeftTop.dy)
      ..lineTo(pCenterTop.dx, pCenterTop.dy)
      ..lineTo(pCenterBottom.dx, pCenterBottom.dy)
      ..lineTo(pLeftBottom.dx, pLeftBottom.dy)
      ..close();

    final Paint frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF1E1E22),
          Color(0xFF141416),
          Color(0xFF0D0D0E),
        ],
      ).createShader(Rect.fromLTWH(left, pLeftTop.dy, frontW, wallH));
    canvas.drawPath(frontPath, frontPaint);

    // -------------------------------------------------------------
    // 4. Side Wall (الجدار الشرقي - Eastern Wall with the Door)
    // -------------------------------------------------------------
    final Path sidePath = Path()
      ..moveTo(pCenterTop.dx, pCenterTop.dy)
      ..lineTo(pRightTop.dx, pRightTop.dy)
      ..lineTo(pRightBottom.dx, pRightBottom.dy)
      ..lineTo(pCenterBottom.dx, pCenterBottom.dy)
      ..close();

    final Paint sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF18181A),
          Color(0xFF0F0F10),
          Color(0xFF070708),
        ],
      ).createShader(Rect.fromLTWH(pCenterTop.dx, pRightTop.dy, sideW, wallH));
    canvas.drawPath(sidePath, sidePaint);

    // -------------------------------------------------------------
    // 5. Golden Kiswah Belt (حزام الكعبة المشرفة)
    // -------------------------------------------------------------
    // Belt spans across upper ~20-35% of wall height
    final double beltTopRatio = 0.18;
    final double beltH = wallH * 0.16;

    // Front Belt Segment
    final Offset fb1 = Offset.lerp(pLeftTop, pLeftBottom, beltTopRatio)!;
    final Offset fb2 = Offset.lerp(pCenterTop, pCenterBottom, beltTopRatio)!;
    final Offset fb3 = Offset(fb2.dx, fb2.dy + beltH);
    final Offset fb4 = Offset(fb1.dx, fb1.dy + beltH);

    final Path frontBeltPath = Path()
      ..moveTo(fb1.dx, fb1.dy)
      ..lineTo(fb2.dx, fb2.dy)
      ..lineTo(fb3.dx, fb3.dy)
      ..lineTo(fb4.dx, fb4.dy)
      ..close();

    final Paint goldBeltPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFFFDF73),
          Color(0xFFD4AF37),
          Color(0xFFA67C1E),
          Color(0xFFE8C547),
        ],
      ).createShader(Rect.fromLTWH(left, fb1.dy, cubeW, beltH));
    canvas.drawPath(frontBeltPath, goldBeltPaint);

    // Side Belt Segment
    final Offset sb1 = fb2;
    final Offset sb2 = Offset.lerp(pRightTop, pRightBottom, beltTopRatio)!;
    final Offset sb3 = Offset(sb2.dx, sb2.dy + beltH * 0.9);
    final Offset sb4 = fb3;

    final Path sideBeltPath = Path()
      ..moveTo(sb1.dx, sb1.dy)
      ..lineTo(sb2.dx, sb2.dy)
      ..lineTo(sb3.dx, sb3.dy)
      ..lineTo(sb4.dx, sb4.dy)
      ..close();

    final Paint sideGoldBeltPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFFD4AF37),
          Color(0xFFA67C1E),
          Color(0xFF7A5810),
        ],
      ).createShader(Rect.fromLTWH(pCenterTop.dx, sb1.dy, sideW, beltH));
    canvas.drawPath(sideBeltPath, sideGoldBeltPaint);

    // Belt fine borders (metallic gold stitching)
    final Paint stitchPaint = Paint()
      ..color = const Color(0xFFFFF0A6).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, w * 0.015);
    canvas.drawLine(fb1, fb2, stitchPaint);
    canvas.drawLine(fb4, fb3, stitchPaint);
    canvas.drawLine(sb1, sb2, stitchPaint);
    canvas.drawLine(sb4, sb3, stitchPaint);

    // -------------------------------------------------------------
    // 6. The Golden Door of the Kaaba (باب الكعبة المشرفة)
    // -------------------------------------------------------------
    // Situated on the Side Wall (Eastern Wall) slightly elevated
    final double doorStartT = 0.42;
    final double doorEndT = 0.92;
    final double doorWidthRatio = 0.58;

    final Offset doorTopL = Offset.lerp(
      Offset.lerp(pCenterTop, pCenterBottom, doorStartT)!,
      Offset.lerp(pRightTop, pRightBottom, doorStartT)!,
      0.18,
    )!;
    final Offset doorTopR = Offset.lerp(
      Offset.lerp(pCenterTop, pCenterBottom, doorStartT)!,
      Offset.lerp(pRightTop, pRightBottom, doorStartT)!,
      0.18 + doorWidthRatio,
    )!;
    final Offset doorBottomR = Offset.lerp(
      Offset.lerp(pCenterTop, pCenterBottom, doorEndT)!,
      Offset.lerp(pRightTop, pRightBottom, doorEndT)!,
      0.18 + doorWidthRatio,
    )!;
    final Offset doorBottomL = Offset.lerp(
      Offset.lerp(pCenterTop, pCenterBottom, doorEndT)!,
      Offset.lerp(pRightTop, pRightBottom, doorEndT)!,
      0.18,
    )!;

    final Path doorPath = Path()
      ..moveTo(doorBottomL.dx, doorBottomL.dy)
      ..lineTo(doorTopL.dx, doorTopL.dy)
      ..lineTo(doorTopR.dx, doorTopR.dy)
      ..lineTo(doorBottomR.dx, doorBottomR.dy)
      ..close();

    final Paint doorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFFFFEA88),
          Color(0xFFE5B834),
          Color(0xFFB58818),
          Color(0xFF7A5810),
        ],
      ).createShader(Rect.fromPoints(doorTopL, doorBottomR));
    canvas.drawPath(doorPath, doorPaint);

    // Door inner lock & decorative divider
    final Paint doorDetailPaint = Paint()
      ..color = const Color(0xFF4A3405)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, w * 0.012);

    final Offset doorCenterTop = Offset(
      (doorTopL.dx + doorTopR.dx) / 2,
      (doorTopL.dy + doorTopR.dy) / 2,
    );
    final Offset doorCenterBottom = Offset(
      (doorBottomL.dx + doorBottomR.dx) / 2,
      (doorBottomL.dy + doorBottomR.dy) / 2,
    );
    canvas.drawLine(doorCenterTop, doorCenterBottom, doorDetailPaint);

    // Door border highlight
    final Paint doorBorder = Paint()
      ..color = const Color(0xFFFFF3B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, w * 0.015);
    canvas.drawPath(doorPath, doorBorder);

    // -------------------------------------------------------------
    // 7. Mizab Al-Rahmah (ميزاب الرحمة - Golden Rain Spout on Roof)
    // -------------------------------------------------------------
    final Offset spoutBase = Offset.lerp(pLeftTop, pCenterTop, 0.45)!;
    final Offset spoutTip = Offset(spoutBase.dx - w * 0.045, spoutBase.dy - h * 0.035);

    final Paint spoutPaint = Paint()
      ..color = const Color(0xFFFFDF73)
      ..strokeWidth = math.max(1.2, w * 0.035)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(spoutBase, spoutTip, spoutPaint);

    // -------------------------------------------------------------
    // 8. The Black Stone (الحجر الأسود - Silver Casing Corner)
    // -------------------------------------------------------------
    final Offset blackStonePos = Offset(pCenterBottom.dx, pCenterBottom.dy - wallH * 0.05);
    final double stoneRadius = math.max(1.0, w * 0.03);

    // Silver oval casing
    final Paint stoneSilver = Paint()..color = const Color(0xFFE4E4E7);
    canvas.drawCircle(blackStonePos, stoneRadius, stoneSilver);

    // Dark core
    final Paint stoneCore = Paint()..color = const Color(0xFF18181B);
    canvas.drawCircle(blackStonePos, stoneRadius * 0.55, stoneCore);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
