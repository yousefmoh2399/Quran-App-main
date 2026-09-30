import 'package:flutter/material.dart';
import '../models/mushaf_theme_model.dart';

/// CustomPainter that renders an authentic Islamic decorative border
/// around the 15-line Mushaf page.
class MushafFramePainter extends CustomPainter {
  final MushafThemeConfig theme;
  final bool isRightPage; // In dual spread: right page vs left page

  const MushafFramePainter({
    required this.theme,
    this.isRightPage = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final outerPaint = Paint()
      ..color = theme.frameBorderOuter.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final innerPaint = Paint()
      ..color = theme.frameBorderInner.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final accentPaint = Paint()
      ..color = theme.cornerAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double outerMargin = 8.0;
    const double innerMargin = 13.0;

    // 1. Outer Frame
    final outerRect = Rect.fromLTWH(
      outerMargin,
      outerMargin,
      size.width - (outerMargin * 2),
      size.height - (outerMargin * 2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(4.0)),
      outerPaint,
    );

    // 2. Inner Frame
    final innerRect = Rect.fromLTWH(
      innerMargin,
      innerMargin,
      size.width - (innerMargin * 2),
      size.height - (innerMargin * 2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(2.0)),
      innerPaint,
    );

    // 3. Ornate Corner Decorations
    _drawCornerOrnament(canvas, innerRect.topLeft, 1, 1, accentPaint);
    _drawCornerOrnament(canvas, innerRect.topRight, -1, 1, accentPaint);
    _drawCornerOrnament(canvas, innerRect.bottomLeft, 1, -1, accentPaint);
    _drawCornerOrnament(canvas, innerRect.bottomRight, -1, -1, accentPaint);

    // 4. Header separator line
    const double headerHeight = 36.0;
    final headerY = innerRect.top + headerHeight;
    canvas.drawLine(
      Offset(innerRect.left + 8, headerY),
      Offset(innerRect.right - 8, headerY),
      Paint()
        ..color = theme.frameBorderOuter.withOpacity(0.3)
        ..strokeWidth = 0.8,
    );

    // 5. Footer separator line
    const double footerHeight = 32.0;
    final footerY = innerRect.bottom - footerHeight;
    canvas.drawLine(
      Offset(innerRect.left + 8, footerY),
      Offset(innerRect.right - 8, footerY),
      Paint()
        ..color = theme.frameBorderOuter.withOpacity(0.3)
        ..strokeWidth = 0.8,
    );
  }

  void _drawCornerOrnament(
    Canvas canvas,
    Offset corner,
    double dirX,
    double dirY,
    Paint paint,
  ) {
    const double size = 10.0;
    final path = Path();

    // Corner bracket step
    path.moveTo(corner.dx + (dirX * size), corner.dy);
    path.lineTo(corner.dx, corner.dy);
    path.lineTo(corner.dx, corner.dy + (dirY * size));

    // Little inner 45-degree diagonal ornament
    path.moveTo(corner.dx + (dirX * 3), corner.dy + (dirY * 6));
    path.lineTo(corner.dx + (dirX * 6), corner.dy + (dirY * 3));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MushafFramePainter oldDelegate) {
    return oldDelegate.theme.mode != theme.mode ||
        oldDelegate.isRightPage != isRightPage;
  }
}
