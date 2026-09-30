import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';

/// SectionHeader component featuring subtle Islamic geometric ornamentation.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showOrnament;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showOrnament = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showOrnament) ...[
            CustomPaint(
              size: const Size(20, 20),
              painter: _IslamicStarPainter(color: colors.accent),
            ),
            AppSpacing.horizontalSm,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: AppTypography.decorativeFont,
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// CustomPainter for a subtle 8-pointed Islamic geometric star.
class _IslamicStarPainter extends CustomPainter {
  final Color color;

  _IslamicStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    // Draw two overlapping squares rotated by 45 degrees to form an 8-pointed star (Rub el Hizb)
    _drawSquare(canvas, center, radius, 0, paint);
    _drawSquare(canvas, center, radius, math.pi / 4, paint);

    // Inner dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.22, dotPaint);
  }

  void _drawSquare(Canvas canvas, Offset center, double radius, double angle, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final a = angle + i * (math.pi / 2);
      final x = center.dx + radius * math.cos(a);
      final y = center.dy + radius * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _IslamicStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
