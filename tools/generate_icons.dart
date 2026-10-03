import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate Taqarrab App Icons and Logo', () async {
    // 1. Load authentic Arabic Amiri font into test engine
    final fontFile = File('assets/fonts/Amiri-Bold.ttf');
    final fontBytes = await fontFile.readAsBytes();
    final fontLoader = FontLoader('Amiri');
    fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
    await fontLoader.load();

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

  // 1. Deep Royal Emerald Radial Gradient Background
  final bgPaint = Paint()
    ..shader = ui.Gradient.radial(
      Offset(size * 0.5, size * 0.45),
      radius * 1.15,
      [
        const Color(0xFF135743), // luminous royal emerald
        const Color(0xFF092E23), // deep dark emerald
        const Color(0xFF041812), // midnight obsidian emerald
      ],
      [0.0, 0.65, 1.0],
    );
  canvas.drawCircle(center, radius, bgPaint);

  // 2. Subtle Radiant Golden Core Glow
  final glowPaint = Paint()
    ..shader = ui.Gradient.radial(
      center,
      radius * 0.72,
      [
        const Color(0xFFE5C06B).withOpacity(0.22),
        const Color(0xFFD4AF37).withOpacity(0.08),
        const Color(0xFF092E23).withOpacity(0.0),
      ],
      [0.0, 0.45, 1.0],
    );
  canvas.drawCircle(center, radius * 0.72, glowPaint);

  // 3. Islamic Octagram (8-pointed Star / Rub el Hizb) Inner Golden Framing
  final octagramPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.012
    ..color = const Color(0xFFD4AF37).withOpacity(0.55);

  final octagramPath = Path();
  final outerR = radius * 0.90;
  final innerR = radius * 0.81;
  for (int i = 0; i < 16; i++) {
    final angle = i * math.pi / 8 - math.pi / 2;
    final r = (i % 2 == 0) ? outerR : innerR;
    final x = center.dx + math.cos(angle) * r;
    final y = center.dy + math.sin(angle) * r;
    if (i == 0) {
      octagramPath.moveTo(x, y);
    } else {
      octagramPath.lineTo(x, y);
    }
  }
  octagramPath.close();
  canvas.drawPath(octagramPath, octagramPaint);

  // Concentric Inner Circular Ring
  final innerRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.008
    ..color = const Color(0xFFFFF0BD).withOpacity(0.40);
  canvas.drawCircle(center, radius * 0.77, innerRingPaint);

  // 8 Sacred Pearls / Golden Dots at the tips
  final pearlPaint = Paint()
    ..color = const Color(0xFFFFF0BD)
    ..style = PaintingStyle.fill;
  for (int i = 0; i < 8; i++) {
    final angle = i * math.pi / 4 - math.pi / 2;
    final dotX = center.dx + math.cos(angle) * outerR;
    final dotY = center.dy + math.sin(angle) * outerR;
    canvas.drawCircle(Offset(dotX, dotY), size * 0.014, pearlPaint);
  }

  // 4. Stylized Islamic Mihrab / Quranic Crescent Arch at bottom
  final crescentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.024
    ..strokeCap = StrokeCap.round
    ..shader = ui.Gradient.linear(
      Offset(size * 0.22, size * 0.77),
      Offset(size * 0.78, size * 0.77),
      [
        const Color(0xFFB8892B),
        const Color(0xFFFFF6D6),
        const Color(0xFFB8892B),
      ],
      [0.0, 0.5, 1.0],
    );

  final arcPath = Path();
  arcPath.moveTo(size * 0.24, size * 0.76);
  arcPath.quadraticBezierTo(size * 0.5, size * 0.85, size * 0.76, size * 0.76);
  canvas.drawPath(arcPath, crescentPaint);

  // Radiant Diamond Star at the center of the arc
  final starPaint = Paint()
    ..color = const Color(0xFFFFF6D6)
    ..style = PaintingStyle.fill;
  final starPath = Path();
  final csX = size * 0.5;
  final csY = size * 0.82;
  final sR = size * 0.020;
  starPath.moveTo(csX, csY - sR);
  starPath.lineTo(csX + sR * 0.35, csY - sR * 0.35);
  starPath.lineTo(csX + sR, csY);
  starPath.lineTo(csX + sR * 0.35, csY + sR * 0.35);
  starPath.lineTo(csX, csY + sR);
  starPath.lineTo(csX - sR * 0.35, csY + sR * 0.35);
  starPath.lineTo(csX - sR, csY);
  starPath.lineTo(csX - sR * 0.35, csY - sR * 0.35);
  starPath.close();
  canvas.drawPath(starPath, starPaint);

  // 5. Authentic Royal Calligraphy «تَقَرَّبْ»
  final textSpan = TextSpan(
    text: 'تَقَرَّبْ',
    style: TextStyle(
      fontSize: size * 0.30,
      fontFamily: 'Amiri',
      fontWeight: FontWeight.bold,
      foreground: Paint()
        ..shader = ui.Gradient.linear(
          Offset(size * 0.3, size * 0.25),
          Offset(size * 0.7, size * 0.65),
          [
            const Color(0xFFFFFFFF), // pure celestial light
            const Color(0xFFFFF5D1), // warm pearl gold
            const Color(0xFFE5C06B), // rich imperial gold
            const Color(0xFFB38827), // deep antique gold
          ],
          [0.0, 0.25, 0.70, 1.0],
        ),
      shadows: [
        Shadow(
          offset: Offset(0, size * 0.016),
          blurRadius: size * 0.035,
          color: Colors.black.withOpacity(0.70),
        ),
        Shadow(
          offset: Offset.zero,
          blurRadius: size * 0.06,
          color: const Color(0xFFD4AF37).withOpacity(0.55),
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
    (size - textPainter.height) / 2 - size * 0.05,
  );
  textPainter.paint(canvas, textOffset);
}
