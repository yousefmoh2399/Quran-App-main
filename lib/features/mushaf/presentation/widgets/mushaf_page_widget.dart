import 'package:flutter/material.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/mushaf/mushaf_font_manager.dart';
import '../models/mushaf_theme_model.dart';
import '../utils/mushaf_utils.dart';
import 'mushaf_frame_painter.dart';
import 'mushaf_line_widget.dart';

/// Renders a complete 15-line page of the Madinah Mushaf.
///
/// Includes:
/// - Parchment / themed background.
/// - Decorative Islamic double-border frame with arabesque corners.
/// - Top header: Surah name (right), Juz and Hizb (left).
/// - 15 full-width scaled text lines with ayah highlight support.
/// - Bottom footer: Page number in authentic Arabic numerals.
class MushafPageWidget extends StatelessWidget {
  final MushafPage page;
  final MushafThemeConfig theme;
  final int? selectedSurah;
  final int? selectedAyah;
  final bool isRightPage;
  final void Function(int surahNumber, int ayahNumber)? onAyahTapped;
  final VoidCallback? onTapPage;

  const MushafPageWidget({
    super.key,
    required this.page,
    required this.theme,
    this.selectedSurah,
    this.selectedAyah,
    this.isRightPage = true,
    this.onAyahTapped,
    this.onTapPage,
  });

  Future<void> _ensurePageFonts(MushafPage page) async {
    final pageNums = <int>{page.pageNumber};
    for (final line in page.lines) {
      for (final word in line.words) {
        pageNums.add(word.pageNumber);
      }
    }
    await Future.wait(
      pageNums.map((p) => MushafFontManager.instance.ensurePageLoaded(p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ensurePageFonts(page),
      builder: (context, snapshot) {
        final fontReady = snapshot.connectionState == ConnectionState.done;

        return GestureDetector(
          onTap: onTapPage,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: theme.pageBg,
            child: CustomPaint(
              painter: MushafFramePainter(
                theme: theme,
                isRightPage: isRightPage,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 18.0,
                  bottom: 16.0,
                ),
                child: Column(
                  children: [
                    // Top Header
                    _buildHeader(context),
                    const SizedBox(height: 6.0),
                    // Lines Area
                    Expanded(
                      child: fontReady
                          ? _buildLinesList(context)
                          : _buildFontLoadingIndicator(context),
                    ),
                    const SizedBox(height: 4.0),
                    // Bottom Footer
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the top header row:
  /// Right: Surah Name | Left: Juz and Hizb
  Widget _buildHeader(BuildContext context) {
    final hizbNumber = calculateHizbNumber(page.pageNumber, page.juzNumber);
    final juzName = getJuzNameArabic(page.juzNumber);

    return SizedBox(
      height: 28.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Surah Name (Right in RTL)
          Text(
            'سُورَةُ ${page.surahNameAr}',
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: theme.headerFooterColor,
            ),
          ),
          // Juz & Hizb (Left in RTL)
          Text(
            'الجزء $juzName  •  الحزب ${toArabicDigits(hizbNumber)}',
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: theme.headerFooterColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the 15 lines of the page evenly distributed.
  Widget _buildLinesList(BuildContext context) {
    final lines = page.lines;

    // Pages 1 and 2 have fewer lines (7-8 lines) centered vertically
    if (page.pageNumber <= 2 && lines.length < 15) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: lines.map((line) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: MushafLineWidget(
                line: line,
                pageNumber: page.pageNumber,
                theme: theme,
                selectedSurah: selectedSurah,
                selectedAyah: selectedAyah,
                onAyahTapped: onAyahTapped,
              ),
            );
          }).toList(),
        ),
      );
    }

    // Standard 15-line pages: each line gets equal vertical space
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines.map((line) {
        return Expanded(
          child: Center(
            child: MushafLineWidget(
              line: line,
              pageNumber: page.pageNumber,
              theme: theme,
              selectedSurah: selectedSurah,
              selectedAyah: selectedAyah,
              onAyahTapped: onAyahTapped,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the bottom footer: Page number in authentic Arabic numerals
  Widget _buildFooter(BuildContext context) {
    return SizedBox(
      height: 24.0,
      child: Center(
        child: Text(
          'ـ ${toArabicDigits(page.pageNumber)} ـ',
          style: TextStyle(
            fontFamily: AppTypography.decorativeFont,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: theme.headerFooterColor,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildFontLoadingIndicator(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24.0,
        height: 24.0,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: theme.frameBorderInner,
        ),
      ),
    );
  }
}
