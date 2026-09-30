import 'package:flutter/material.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/mushaf/mushaf_font_manager.dart';
import '../models/mushaf_theme_model.dart';

/// Renders a single line of the 15 lines of a Madinah Mushaf page.
///
/// Ensures exact full-width fit via [FittedBox(fit: BoxFit.fitWidth)],
/// handles Surah headers, Basmalah lines, and verse highlighting and tap interactions.
class MushafLineWidget extends StatelessWidget {
  final MushafLine line;
  final int pageNumber;
  final MushafThemeConfig theme;
  final int? selectedSurah;
  final int? selectedAyah;
  final void Function(int surahNumber, int ayahNumber)? onAyahTapped;

  const MushafLineWidget({
    super.key,
    required this.line,
    required this.pageNumber,
    required this.theme,
    this.selectedSurah,
    this.selectedAyah,
    this.onAyahTapped,
  });

  @override
  Widget build(BuildContext context) {
    switch (line.lineType) {
      case MushafLineType.surahHeader:
        return _buildSurahHeader(context);
      case MushafLineType.basmalah:
        return _buildBasmalah(context);
      case MushafLineType.ayah:
        return _buildAyahLine(context);
    }
  }

  /// Builds the ornate decorative Surah header banner.
  Widget _buildSurahHeader(BuildContext context) {
    final surahName = _extractSurahName(line.text);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: theme.surahHeaderBg,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: theme.surahHeaderBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: theme.surahHeaderBorder.withOpacity(0.12),
            blurRadius: 4.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '۞  ',
              style: TextStyle(
                color: theme.surahHeaderBorder,
                fontSize: 14.0,
              ),
            ),
            Text(
              'سُورَةُ $surahName',
              style: TextStyle(
                fontFamily: AppTypography.decorativeFont,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: theme.surahHeaderTextColor,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '  ۞',
              style: TextStyle(
                color: theme.surahHeaderBorder,
                fontSize: 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the centered Basmalah line.
  Widget _buildBasmalah(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds standard Ayah text line scaled to exactly fit the page width.
  Widget _buildAyahLine(BuildContext context) {
    if (line.words.isEmpty) {
      // Fallback if words list is empty
      final rawText = line.qpcV2 ?? line.text ?? '';
      return FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        child: Text(
          rawText,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: MushafFontManager.pageFontFamily(pageNumber),
            fontSize: 22.0,
            color: theme.textColor,
            height: 1.1,
          ),
        ),
      );
    }

    // In Arabic RTL, words flow right to left
    return FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.center,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: line.words.map((word) {
            final isHighlighted = selectedSurah != null &&
                selectedAyah != null &&
                word.surahNumber == selectedSurah &&
                word.ayahNumber == selectedAyah;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (onAyahTapped != null) {
                  onAyahTapped!(word.surahNumber, word.ayahNumber);
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.0),
                decoration: BoxDecoration(
                  color: isHighlighted ? theme.ayahHighlight : Colors.transparent,
                  borderRadius: BorderRadius.circular(4.0),
                  border: isHighlighted
                      ? Border.all(color: theme.surahHeaderBorder, width: 0.6)
                      : null,
                ),
                child: Text(
                  word.glyphCode,
                  style: TextStyle(
                    fontFamily: MushafFontManager.pageFontFamily(pageNumber),
                    fontSize: 22.0,
                    color: theme.textColor,
                    height: 1.1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _extractSurahName(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    return text.replaceAll('سورة', '').trim();
  }
}
