import 'package:flutter/material.dart';

/// A silk bookmark ribbon hanging from the top edge of a Mushaf page.
///
/// Has a swallowtail / V-notch at the bottom, realistic drop shadow, and a subtle icon.
class PageRibbonWidget extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PageRibbonWidget({
    super.key,
    required this.color,
    this.icon,
    this.width = 24.0,
    this.height = 38.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        size: Size(width, height),
        painter: _RibbonPainter(color: color),
        child: SizedBox(
          width: width,
          height: height,
          child: icon != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      icon,
                      size: width * 0.55,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  final Color color;

  _RibbonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final ribbonPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    // V-notch cut at bottom center
    path.lineTo(size.width / 2, size.height - (size.width * 0.35));
    path.lineTo(0, size.height);
    path.close();

    // Draw drop shadow offset
    canvas.save();
    canvas.translate(0, 1.5);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Draw main ribbon body
    canvas.drawPath(path, ribbonPaint);
    // Subtle inner border for realism
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
