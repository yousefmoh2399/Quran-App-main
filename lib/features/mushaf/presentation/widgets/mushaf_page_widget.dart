import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/mushaf/mushaf_font_manager.dart';
import '../../../../core/mushaf/mushaf_raster_cache.dart';
import '../models/mushaf_theme_model.dart';
import '../utils/mushaf_utils.dart';
import 'mushaf_frame_painter.dart';
import 'mushaf_line_widget.dart';
import 'page_ribbon_widget.dart';

/// Renders a complete 15-line page of the Madinah Mushaf.
///
/// Features:
/// - Silk corner ribbon indicator on bookmarked or memorized pages.
/// - Persistent tinting on bookmarked and memorized verses.
/// - Mini progress bar at footer showing progress towards Khatma (Page X of 604).
/// - 60fps/120fps raster image caching via [MushafRasterCache] when moving.
class MushafPageWidget extends StatefulWidget {
  final MushafPage page;
  final MushafThemeConfig theme;
  final int? selectedSurah;
  final int? selectedAyah;
  final bool isRightPage;
  final bool isMoving;
  final BookmarkColor? pageBookmarkColor;
  final MemorizeStatus? pageMemorizeStatus;
  final Map<String, BookmarkColor>? bookmarkedAyahs;
  final Map<String, MemorizeStatus>? memorizedAyahs;
  final void Function(int surahNumber, int ayahNumber)? onAyahTapped;
  final VoidCallback? onTapPage;

  const MushafPageWidget({
    super.key,
    required this.page,
    required this.theme,
    this.selectedSurah,
    this.selectedAyah,
    this.isRightPage = true,
    this.isMoving = false,
    this.pageBookmarkColor,
    this.pageMemorizeStatus,
    this.bookmarkedAyahs,
    this.memorizedAyahs,
    this.onAyahTapped,
    this.onTapPage,
  });

  @override
  State<MushafPageWidget> createState() => _MushafPageWidgetState();
}

class _MushafPageWidgetState extends State<MushafPageWidget> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _scheduleCapture();
  }

  @override
  void didUpdateWidget(covariant MushafPageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.pageNumber != widget.page.pageNumber ||
        oldWidget.theme.mode != widget.theme.mode ||
        oldWidget.pageBookmarkColor != widget.pageBookmarkColor ||
        oldWidget.pageMemorizeStatus != widget.pageMemorizeStatus) {
      _scheduleCapture();
    }
  }

  void _scheduleCapture() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureRasterImage();
    });
  }

  Future<void> _captureRasterImage() async {
    if (!mounted || _isCapturing) return;
    if (widget.selectedAyah != null) return;
    if (MushafRasterCache.instance.has(widget.page.pageNumber, widget.theme.mode)) {
      return;
    }

    _isCapturing = true;
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null &&
          boundary.hasSize &&
          boundary.size.width > 0 &&
          !boundary.debugNeedsPaint) {
        final pixelRatio = View.of(context).devicePixelRatio.clamp(1.0, 2.0);
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        MushafRasterCache.instance.put(widget.page.pageNumber, widget.theme.mode, image);
        if (mounted) {
          setState(() {});
        }
      }
    } catch (_) {
      // Boundary not ready or in teardown; ignore silently
    } finally {
      _isCapturing = false;
    }
  }

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
    final cachedImage = MushafRasterCache.instance.get(
      widget.page.pageNumber,
      widget.theme.mode,
    );

    // When the page is swiping or turning, and a pre-rendered raster image is available,
    // display only the lightweight 2D texture (RawImage) for butter-smooth 60fps scrolling.
    if (widget.isMoving && cachedImage != null && widget.selectedAyah == null) {
      return GestureDetector(
        onTap: widget.onTapPage,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: widget.theme.pageBg,
          child: Stack(
            children: [
              Positioned.fill(
                child: RawImage(
                  image: cachedImage,
                  fit: BoxFit.fill,
                ),
              ),
              ..._buildRibbons(),
            ],
          ),
        ),
      );
    }

    // Settled page: render live interactive widgets inside RepaintBoundary
    return RepaintBoundary(
      key: _boundaryKey,
      child: FutureBuilder<void>(
        future: _ensurePageFonts(widget.page),
        builder: (context, snapshot) {
          final fontReady = snapshot.connectionState == ConnectionState.done;

          return GestureDetector(
            onTap: widget.onTapPage,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: widget.theme.pageBg,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: MushafFramePainter(
                      theme: widget.theme,
                      isRightPage: widget.isRightPage,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        top: 18.0,
                        bottom: 14.0,
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

                  // Corner Silk Ribbons (Bookmarked and/or Memorized)
                  ..._buildRibbons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds corner silk ribbons for bookmarked and/or memorized page.
  List<Widget> _buildRibbons() {
    final ribbons = <Widget>[];

    final hasBookmark = widget.pageBookmarkColor != null;
    final hasMemorize = widget.pageMemorizeStatus != null;

    if (hasBookmark) {
      ribbons.add(
        Positioned(
          top: 0.0,
          right: widget.isRightPage ? 36.0 : null,
          left: widget.isRightPage ? null : 36.0,
          child: PageRibbonWidget(
            color: widget.pageBookmarkColor!.color,
            icon: Icons.bookmark_rounded,
          ),
        ),
      );
    }

    if (hasMemorize) {
      final double offset = hasBookmark ? 66.0 : 36.0;
      final status = widget.pageMemorizeStatus!;
      final IconData memIcon = status == MemorizeStatus.memorized
          ? Icons.check_circle_rounded
          : (status == MemorizeStatus.needsReview
              ? Icons.rate_review_rounded
              : Icons.sync_rounded);

      ribbons.add(
        Positioned(
          top: 0.0,
          right: widget.isRightPage ? offset : null,
          left: widget.isRightPage ? null : offset,
          child: PageRibbonWidget(
            color: status.badgeColor,
            icon: memIcon,
          ),
        ),
      );
    }

    return ribbons;
  }

  /// Builds the top header row:
  /// Right: Surah Name | Left: Juz and Hizb
  Widget _buildHeader(BuildContext context) {
    final hizbNumber = calculateHizbNumber(widget.page.pageNumber, widget.page.juzNumber);
    final juzName = getJuzNameArabic(widget.page.juzNumber);

    return SizedBox(
      height: 28.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Surah Name (Right in RTL)
          Flexible(
            child: Text(
              'سُورَةُ ${widget.page.surahNameAr}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.decorativeFont,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: widget.theme.headerFooterColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Juz & Hizb (Left in RTL)
          Flexible(
            child: Text(
              'الجزء $juzName  •  الحزب ${toArabicDigits(hizbNumber)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: AppTypography.decorativeFont,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: widget.theme.headerFooterColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the 15 lines of the page evenly distributed.
  Widget _buildLinesList(BuildContext context) {
    final lines = widget.page.lines;

    // Pages 1 and 2 have fewer lines (7-8 lines) centered vertically
    if (widget.page.pageNumber <= 2 && lines.length < 15) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: lines.map((line) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: MushafLineWidget(
                line: line,
                pageNumber: widget.page.pageNumber,
                theme: widget.theme,
                selectedSurah: widget.selectedSurah,
                selectedAyah: widget.selectedAyah,
                bookmarkedAyahs: widget.bookmarkedAyahs,
                memorizedAyahs: widget.memorizedAyahs,
                onAyahTapped: widget.onAyahTapped,
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
              pageNumber: widget.page.pageNumber,
              theme: widget.theme,
              selectedSurah: widget.selectedSurah,
              selectedAyah: widget.selectedAyah,
              bookmarkedAyahs: widget.bookmarkedAyahs,
              memorizedAyahs: widget.memorizedAyahs,
              onAyahTapped: widget.onAyahTapped,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the bottom footer:
  /// - Ornamental page number
  /// - Reading progress percentage (Page X of 604)
  /// - Sleek mini progress bar line
  Widget _buildFooter(BuildContext context) {
    final progress = (widget.page.pageNumber / 604.0).clamp(0.0, 1.0);
    final percentStr = (progress * 100).toStringAsFixed(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Page progress label
            Text(
              'صفحة ${toArabicDigits(widget.page.pageNumber)} من ٦٠٤ ($percentStr%)',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 10.5,
                color: widget.theme.headerFooterColor.withOpacity(0.75),
              ),
            ),
            // Page number ornamental
            Text(
              'ـ ${toArabicDigits(widget.page.pageNumber)} ـ',
              style: TextStyle(
                fontFamily: AppTypography.decorativeFont,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: widget.theme.headerFooterColor,
                letterSpacing: 1.0,
              ),
            ),
            // Juz counter
            Text(
              'الجزء ${toArabicDigits(widget.page.juzNumber)}',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 10.5,
                color: widget.theme.headerFooterColor.withOpacity(0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3.0),
        // Mini progress indicator
        ClipRRect(
          borderRadius: BorderRadius.circular(1.5),
          child: SizedBox(
            height: 2.5,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: widget.theme.frameBorderInner.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.theme.frameBorderOuter.withOpacity(0.85),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontLoadingIndicator(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24.0,
        height: 24.0,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: widget.theme.frameBorderInner,
        ),
      ),
    );
  }
}
