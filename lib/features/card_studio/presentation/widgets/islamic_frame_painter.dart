import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/card_studio_theme_preset.dart';

/// Pure Vector CustomPainter rendering mathematical Islamic architectural frames
/// Works completely offline on Android, iOS, and all platforms with zero asset dependency.
class IslamicFramePainter extends CustomPainter {
  final CardIslamicFrameStyle style;
  final Color borderColor;
  final Color accentColor;
  final double borderWidth;
  final double padding;

  const IslamicFramePainter({
    required this.style,
    required this.borderColor,
    required this.accentColor,
    this.borderWidth = 1.6,
    this.padding = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (style == CardIslamicFrameStyle.none) return;

    final outerPaint = Paint()
      ..color = borderColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final innerPaint = Paint()
      ..color = accentColor.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 0.7;

    final fillPaint = Paint()
      ..color = accentColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    switch (style) {
      case CardIslamicFrameStyle.andalusian:
        _drawAndalusianFrame(canvas, size, outerPaint, innerPaint, fillPaint);
        break;
      case CardIslamicFrameStyle.mihrab:
        _drawMihrabFrame(canvas, size, outerPaint, innerPaint, fillPaint);
        break;
      case CardIslamicFrameStyle.classic:
        _drawClassicFrame(canvas, size, outerPaint, innerPaint, fillPaint);
        break;
      case CardIslamicFrameStyle.none:
        break;
    }
  }

  void _drawAndalusianFrame(
    Canvas canvas,
    Size size,
    Paint outerPaint,
    Paint innerPaint,
    Paint fillPaint,
  ) {
    final p = padding;
    final w = size.width;
    final h = size.height;
    final cornerRadius = 14.0;

    // Outer Rectangle with inward notched corners
    final outerRect = Rect.fromLTWH(p, p, w - 2 * p, h - 2 * p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, Radius.circular(cornerRadius)),
      outerPaint,
    );

    // Inner parallel frame
    final innerP = p + 6.0;
    final innerRect = Rect.fromLTWH(innerP, innerP, w - 2 * innerP, h - 2 * innerP);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(cornerRadius - 3)),
      innerPaint,
    );

    // 8-Pointed Islamic Stars at 4 corners
    final starSize = 10.0;
    _drawEightPointedStar(canvas, innerP + 4, innerP + 4, starSize, fillPaint);
    _drawEightPointedStar(canvas, w - innerP - 4, innerP + 4, starSize, fillPaint);
    _drawEightPointedStar(canvas, innerP + 4, h - innerP - 4, starSize, fillPaint);
    _drawEightPointedStar(canvas, w - innerP - 4, h - innerP - 4, starSize, fillPaint);

    // Top and Bottom decorative center fleurons
    _drawCenterFleuron(canvas, w / 2, innerP, true, fillPaint, outerPaint);
    _drawCenterFleuron(canvas, w / 2, h - innerP, false, fillPaint, outerPaint);
  }

  void _drawMihrabFrame(
    Canvas canvas,
    Size size,
    Paint outerPaint,
    Paint innerPaint,
    Paint fillPaint,
  ) {
    final p = padding;
    final w = size.width;
    final h = size.height;
    final archHeight = math.min(50.0, h * 0.12);

    final path = Path();
    // Start at bottom right
    path.moveTo(w - p, h - p);
    // Left to bottom left
    path.lineTo(p, h - p);
    // Up to arch start
    path.lineTo(p, p + archHeight);

    // Mihrab pointed arch curves
    final midX = w / 2;
    path.quadraticBezierTo(
      p + (midX - p) * 0.25,
      p,
      midX,
      p + 4,
    );
    path.quadraticBezierTo(
      w - p - (w - p - midX) * 0.25,
      p,
      w - p,
      p + archHeight,
    );
    path.lineTo(w - p, h - p);
    path.close();

    canvas.drawPath(path, outerPaint);

    // Inner Mihrab Path
    final innerPath = Path();
    final ip = p + 5.0;
    final iArchHeight = archHeight - 4;
    innerPath.moveTo(w - ip, h - ip);
    innerPath.lineTo(ip, h - ip);
    innerPath.lineTo(ip, ip + iArchHeight);
    innerPath.quadraticBezierTo(
      ip + (midX - ip) * 0.25,
      ip,
      midX,
      ip + 4,
    );
    innerPath.quadraticBezierTo(
      w - ip - (w - ip - midX) * 0.25,
      ip,
      w - ip,
      ip + iArchHeight,
    );
    innerPath.lineTo(w - ip, h - ip);
    innerPath.close();

    canvas.drawPath(innerPath, innerPaint);

    // Top Medallion
    canvas.drawCircle(Offset(midX, p + 4), 4.5, fillPaint);
  }

  void _drawClassicFrame(
    Canvas canvas,
    Size size,
    Paint outerPaint,
    Paint innerPaint,
    Paint fillPaint,
  ) {
    final p = padding;
    final w = size.width;
    final h = size.height;

    // Dual concentric borders
    canvas.drawRect(Rect.fromLTWH(p, p, w - 2 * p, h - 2 * p), outerPaint);
    canvas.drawRect(Rect.fromLTWH(p + 5, p + 5, w - 2 * (p + 5), h - 2 * (p + 5)), innerPaint);

    // 4 Corner Diamonds
    const cornerOffset = 5.0;
    _drawDiamond(canvas, p + cornerOffset, p + cornerOffset, 5, fillPaint);
    _drawDiamond(canvas, w - p - cornerOffset, p + cornerOffset, 5, fillPaint);
    _drawDiamond(canvas, p + cornerOffset, h - p - cornerOffset, 5, fillPaint);
    _drawDiamond(canvas, w - p - cornerOffset, h - p - cornerOffset, 5, fillPaint);
  }

  void _drawEightPointedStar(Canvas canvas, double cx, double cy, double radius, Paint paint) {
    final path = Path();
    final points = 8;
    final innerRadius = radius * 0.48;

    for (int i = 0; i < points * 2; i++) {
      final r = (i.isEven) ? radius : innerRadius;
      final angle = (i * math.pi) / points - (math.pi / 2);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, double cx, double cy, double size, Paint paint) {
    final path = Path()
      ..moveTo(cx, cy - size)
      ..lineTo(cx + size, cy)
      ..lineTo(cx, cy + size)
      ..lineTo(cx - size, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawCenterFleuron(
    Canvas canvas,
    double cx,
    double cy,
    bool isTop,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    final path = Path();
    final sign = isTop ? 1 : -1;

    path.moveTo(cx - 16, cy);
    path.quadraticBezierTo(cx - 8, cy + 6 * sign, cx, cy + 10 * sign);
    path.quadraticBezierTo(cx + 8, cy + 6 * sign, cx + 16, cy);
    path.close();

    canvas.drawPath(path, strokePaint);
    canvas.drawCircle(Offset(cx, cy + 5 * sign), 2.5, fillPaint);
  }

  @override
  bool shouldRepaint(covariant IslamicFramePainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.padding != padding;
  }
}
