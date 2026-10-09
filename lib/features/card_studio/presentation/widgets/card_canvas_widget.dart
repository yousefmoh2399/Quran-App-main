import 'package:flutter/material.dart';
import '../../../../core/design/app_typography.dart';
import '../../data/models/card_studio_theme_preset.dart';
import 'islamic_frame_painter.dart';

class CardCanvasWidget extends StatelessWidget {
  final CardStudioThemePreset preset;
  final CardIslamicFrameStyle frameStyle;
  final CardStudioFontFamily font;
  final CardAspectRatio ratio;
  final String mainText;
  final String subtitleText;
  final String? tafsirOrNote;
  final double fontSize;
  final bool showBismillah;
  final bool showBrackets;
  final bool showWatermark;
  final TextAlign alignment;

  const CardCanvasWidget({
    super.key,
    required this.preset,
    required this.frameStyle,
    required this.font,
    required this.ratio,
    required this.mainText,
    required this.subtitleText,
    this.tafsirOrNote,
    this.fontSize = 22.0,
    this.showBismillah = true,
    this.showBrackets = true,
    this.showWatermark = true,
    this.alignment = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = showBrackets ? '﴿ $mainText ﴾' : mainText;

    return AspectRatio(
      aspectRatio: ratio.ratio,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: preset.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle background Islamic watermark pattern
              CustomPaint(
                painter: _CardBackgroundPatternPainter(
                  accentColor: preset.accentColor.withOpacity(0.04),
                ),
              ),

              // Islamic Architectural Vector Frame
              CustomPaint(
                painter: IslamicFramePainter(
                  style: frameStyle,
                  borderColor: preset.borderColor,
                  accentColor: preset.accentColor,
                  borderWidth: 1.8,
                  padding: 16.0,
                ),
              ),

              // Content Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top: Bismillah & Header
                    _buildTopHeader(),

                    // Center: Main Quran / Dua Text & Optional Note
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayText,
                                textAlign: alignment,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: font.fontName,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  height: 1.9,
                                  color: preset.textColor,
                                  shadows: preset.isDark
                                      ? [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.4),
                                            offset: const Offset(0, 1.5),
                                            blurRadius: 3,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                              if (tafsirOrNote != null && tafsirOrNote!.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (preset.isDark ? Colors.black : Colors.white)
                                        .withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: preset.accentColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tafsirOrNote!,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 11.5,
                                      height: 1.5,
                                      color: preset.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom: Reference Badge & App Brand
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    if (!showBismillah) {
      return const SizedBox(height: 12);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 20),
                height: 1,
                color: preset.accentColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.star_rounded, size: 9, color: preset.accentColor),
            const SizedBox(width: 6),
            Flexible(
              flex: 4,
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.decorativeFont,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: preset.accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.star_rounded, size: 9, color: preset.accentColor),
            const SizedBox(width: 4),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 20),
                height: 1,
                color: preset.accentColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Source reference pill
        if (subtitleText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: preset.accentColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: preset.accentColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              subtitleText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: preset.accentColor,
              ),
            ),
          ),

        if (showWatermark) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mosque_rounded,
                size: 11,
                color: preset.secondaryTextColor.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'تطبيق تقرّب • أوفلاين',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: preset.secondaryTextColor.withOpacity(0.7),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CardBackgroundPatternPainter extends CustomPainter {
  final Color accentColor;

  _CardBackgroundPatternPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.38;

    // Draw central ambient decorative circle
    canvas.drawCircle(Offset(cx, cy), radius, paint);
    canvas.drawCircle(Offset(cx, cy), radius * 0.7, paint);
  }

  @override
  bool shouldRepaint(covariant _CardBackgroundPatternPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
