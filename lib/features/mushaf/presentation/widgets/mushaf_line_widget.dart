import 'package:flutter/material.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/mushaf/mushaf_font_manager.dart';
import '../../../../core/services/app_haptics_service.dart';
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
  final BookmarkColor? selectedAyahColor;
  final Map<String, BookmarkColor>? bookmarkedAyahs;
  final Map<String, MemorizeStatus>? memorizedAyahs;
  final void Function(int surahNumber, int ayahNumber)? onAyahTapped;
  final VoidCallback? onTapPage;

  const MushafLineWidget({
    super.key,
    required this.line,
    required this.pageNumber,
    required this.theme,
    this.selectedSurah,
    this.selectedAyah,
    this.selectedAyahColor,
    this.bookmarkedAyahs,
    this.memorizedAyahs,
    this.onAyahTapped,
    this.onTapPage,
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

    final words = line.words;
    final wordWidgets = <Widget>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final isHighlighted = selectedSurah != null &&
          selectedAyah != null &&
          word.surahNumber == selectedSurah &&
          word.ayahNumber == selectedAyah;

      final verseKey = '${word.surahNumber}:${word.ayahNumber}';
      final bookmarkColor = bookmarkedAyahs?[verseKey];
      final memorizeStatus = memorizedAyahs?[verseKey];

      Color bgColor = Colors.transparent;
      Color? borderColor;
      double borderWidth = 0.8;

      if (isHighlighted) {
        // Highlight with the active chosen bookmark color or theme highlight
        final activeColor = bookmarkColor?.color ?? selectedAyahColor?.color ?? theme.ayahHighlight;
        bgColor = activeColor.withOpacity(0.30);
        borderColor = activeColor.withOpacity(0.95);
        borderWidth = 1.2;
      } else if (bookmarkColor != null && memorizeStatus != null) {
        bgColor = memorizeStatus.badgeColor.withOpacity(0.20);
        borderColor = bookmarkColor.color.withOpacity(0.85);
        borderWidth = 1.0;
      } else if (bookmarkColor != null) {
        bgColor = bookmarkColor.color.withOpacity(0.22);
        borderColor = bookmarkColor.color.withOpacity(0.70);
        borderWidth = 0.8;
      } else if (memorizeStatus != null) {
        bgColor = memorizeStatus.badgeColor.withOpacity(0.18);
        borderColor = memorizeStatus.badgeColor.withOpacity(0.50);
        borderWidth = 0.6;
      }

      // Continuous highlight grouping for words of the same verse on this line
      final bool hasActiveStyling = bgColor != Colors.transparent;
      final bool isSameAyahAsPrev = i > 0 &&
          words[i - 1].surahNumber == word.surahNumber &&
          words[i - 1].ayahNumber == word.ayahNumber;
      final bool isSameAyahAsNext = i < words.length - 1 &&
          words[i + 1].surahNumber == word.surahNumber &&
          words[i + 1].ayahNumber == word.ayahNumber;

      // In Arabic RTL, words flow Right to Left:
      // words[0] is at the right edge of the line.
      // So isSameAyahAsPrev connects to the RIGHT, and isSameAyahAsNext connects to the LEFT.
      final bool isRightEnd = !isSameAyahAsPrev;
      final bool isLeftEnd = !isSameAyahAsNext;

      BorderRadius borderRadius;
      if (!hasActiveStyling || (isRightEnd && isLeftEnd)) {
        borderRadius = BorderRadius.circular(4.0);
      } else if (isRightEnd) {
        borderRadius = const BorderRadius.only(
          topRight: Radius.circular(4.0),
          bottomRight: Radius.circular(4.0),
        );
      } else if (isLeftEnd) {
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(4.0),
          bottomLeft: Radius.circular(4.0),
        );
      } else {
        borderRadius = BorderRadius.zero;
      }

      Border? border;
      if (borderColor != null) {
        final side = BorderSide(color: borderColor, width: borderWidth);
        border = Border(
          top: side,
          bottom: side,
          right: isRightEnd ? side : BorderSide.none,
          left: isLeftEnd ? side : BorderSide.none,
        );
      }

      final margin = EdgeInsets.only(
        right: (!hasActiveStyling || isRightEnd) ? 0.8 : 0.0,
        left: (!hasActiveStyling || isLeftEnd) ? 0.8 : 0.0,
      );

      wordWidgets.add(
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            onTapPage?.call();
          },
          onLongPress: () {
            AppHaptics.itemCompleted();
            if (onAyahTapped != null) {
              onAyahTapped!(word.surahNumber, word.ayahNumber);
            }
          },
          child: Container(
            margin: margin,
            padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.0),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: borderRadius,
              border: border,
            ),
            child: Text(
              word.glyphCode,
              style: TextStyle(
                fontFamily: MushafFontManager.pageFontFamily(word.pageNumber),
                fontSize: 22.0,
                color: theme.textColor,
                height: 1.1,
              ),
            ),
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
          children: wordWidgets,
        ),
      ),
    );
  }

  String _extractSurahName(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    return text.replaceAll('سورة', '').trim();
  }
}
