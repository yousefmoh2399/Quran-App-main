import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate Taqarrab App Icons and Logo', () async {
    final sizes = {
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png': 192,
      'assets/images/taqarrab_logo.png': 512,
    };

    for (final entry in sizes.entries) {
      final size = entry.value.toDouble();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

      // Draw Icon
      _drawTaqarrabLogo(canvas, size);

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File(entry.key);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      debugPrint('Generated ${entry.key} (${size.toInt()}x${size.toInt()})');
    }
  });
}

void _drawTaqarrabLogo(Canvas canvas, double size) {
  final center = Offset(size / 2, size / 2);
  final radius = size / 2;

  // 1. Background Gradient Circle
  final bgPaint = Paint()
    ..shader = ui.Gradient.radial(
      Offset(size * 0.4, size * 0.35),
      radius * 1.2,
      [
        const Color(0xFF14533F), // rich emerald
        const Color(0xFF0A3326), // deep dark emerald
        const Color(0xFF061E16), // midnight emerald
      ],
      [0.0, 0.6, 1.0],
    );
  canvas.drawCircle(center, radius, bgPaint);

  // 2. Outer Subtle Islamic Geometric Pattern Ring
  final borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.02
    ..color = const Color(0xFFD4AF37).withOpacity(0.55);

  canvas.drawCircle(center, radius * 0.93, borderPaint);

  final innerBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.008
    ..color = const Color(0xFFE6C665).withOpacity(0.4);
  canvas.drawCircle(center, radius * 0.89, innerBorderPaint);

  // 3. Decorative Islamic Star Accents on the ring
  final starPaint = Paint()
    ..color = const Color(0xFFD4AF37)
    ..style = PaintingStyle.fill;

  for (int i = 0; i < 8; i++) {
    final angle = i * math.pi / 4;
    final dotX = center.dx + math.cos(angle) * radius * 0.91;
    final dotY = center.dy + math.sin(angle) * radius * 0.91;
    canvas.drawCircle(Offset(dotX, dotY), size * 0.012, starPaint);
  }

  // 4. Subtle Radiant Glow behind calligraphy
  final glowPaint = Paint()
    ..shader = ui.Gradient.radial(
      center,
      radius * 0.65,
      [
        const Color(0xFFD4AF37).withOpacity(0.18),
        const Color(0xFFD4AF37).withOpacity(0.0),
      ],
    );
  canvas.drawCircle(center, radius * 0.65, glowPaint);

  // 5. Stylized Islamic Mihrab / Crescent Arc at bottom
  final crescentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.022
    ..strokeCap = StrokeCap.round
    ..shader = ui.Gradient.linear(
      Offset(size * 0.2, size * 0.78),
      Offset(size * 0.8, size * 0.78),
      [
        const Color(0xFFB8892B),
        const Color(0xFFF9E498),
        const Color(0xFFB8892B),
      ],
      [0.0, 0.5, 1.0],
    );

  final arcPath = Path();
  arcPath.moveTo(size * 0.22, size * 0.76);
  arcPath.quadraticBezierTo(size * 0.5, size * 0.86, size * 0.78, size * 0.76);
  canvas.drawPath(arcPath, crescentPaint);

  // Little star at bottom center
  final centerStarPath = Path();
  final csX = size * 0.5;
  final csY = size * 0.83;
  final csR = size * 0.018;
  centerStarPath.moveTo(csX, csY - csR);
  centerStarPath.lineTo(csX + csR * 0.4, csY - csR * 0.3);
  centerStarPath.lineTo(csX + csR, csY);
  centerStarPath.lineTo(csX + csR * 0.4, csY + csR * 0.3);
  centerStarPath.lineTo(csX, csY + csR);
  centerStarPath.lineTo(csX - csR * 0.4, csY + csR * 0.3);
  centerStarPath.lineTo(csX - csR, csY);
  centerStarPath.lineTo(csX - csR * 0.4, csY - csR * 0.3);
  centerStarPath.close();
  canvas.drawPath(centerStarPath, starPaint);

  // 6. Primary Calligraphic Typography "تقرّب"
  // Draw with text painter using Amiri or Cairo font if available, with gold gradient
  final textSpan = TextSpan(
    text: 'تَقَرَّبْ',
    style: TextStyle(
      fontSize: size * 0.27,
      fontFamily: 'Amiri',
      fontWeight: FontWeight.bold,
      foreground: Paint()
        ..shader = ui.Gradient.linear(
          Offset(size * 0.3, size * 0.3),
          Offset(size * 0.7, size * 0.65),
          [
            const Color(0xFFFFF6D6), // luminous light gold
            const Color(0xFFE5C06B), // rich warm gold
            const Color(0xFFB38827), // deep antique gold
          ],
          [0.0, 0.5, 1.0],
        ),
      shadows: [
        Shadow(
          offset: Offset(0, size * 0.015),
          blurRadius: size * 0.03,
          color: Colors.black.withOpacity(0.65),
        ),
        Shadow(
          offset: Offset(0, 0),
          blurRadius: size * 0.05,
          color: const Color(0xFFD4AF37).withOpacity(0.4),
        ),
      ],
    ),
  );

  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
  );
  textPainter.layout();
  final textOffset = Offset(
    (size - textPainter.width) / 2,
    (size - textPainter.height) / 2 - size * 0.04,
  );
  textPainter.paint(canvas, textOffset);
}
