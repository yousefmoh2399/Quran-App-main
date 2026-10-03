import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/data/models/user_models.dart';
import '../controllers/mushaf_controller.dart';
import '../models/mushaf_theme_model.dart';
import 'mushaf_page_widget.dart';

/// A realistic paper book page flip widget for the 604-page Madinah Mushaf.
///
/// Features:
/// - True physical paper curl and peel animation with cylindrical highlight & cast drop shadows.
/// - Strict single-page navigation: prevents overshooting or skipping to a 3rd page during swipe.
/// - Monotonic, critically-damped transition without any oscillation, shaking, or bouncing.
/// - Authentic Arabic RTL book page turning order.
/// - Full preservation of Ayah long-press selection, bookmarks, and page tap overlays.
class MushafPaperFlipView extends StatefulWidget {
  final int currentPage;
  final MushafThemeConfig theme;
  final Map<int, MushafPage> pagesCache;
  final Future<MushafPage?> Function(int pageNumber) getPage;
  final int? selectedSurah;
  final int? selectedAyah;
  final void Function(int newPage) onPageChanged;
  final void Function(int surahNumber, int ayahNumber) onAyahTapped;
  final VoidCallback onTapPage;
  final BookmarkColor? Function(int pageNumber) getPageBookmarkColor;
  final MemorizeStatus? Function(int pageNumber) getPageMemorizeStatus;
  final Map<String, BookmarkColor> Function() getAyahBookmarkColors;
  final Map<String, MemorizeStatus> Function() getAyahMemorizeStatuses;
  final MushafController controller;

  const MushafPaperFlipView({
    super.key,
    required this.currentPage,
    required this.theme,
    required this.pagesCache,
    required this.getPage,
    this.selectedSurah,
    this.selectedAyah,
    required this.onPageChanged,
    required this.onAyahTapped,
    required this.onTapPage,
    required this.getPageBookmarkColor,
    required this.getPageMemorizeStatus,
    required this.getAyahBookmarkColors,
    required this.getAyahMemorizeStatuses,
    required this.controller,
  });

  @override
  State<MushafPaperFlipView> createState() => MushafPaperFlipViewState();
}

class MushafPaperFlipViewState extends State<MushafPaperFlipView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _turnAnimation;

  // Interaction State
  bool _isTurning = false;
  bool _isNext = true; // true = forward (next page), false = backward (prev page)
  int? _targetPage;
  double _dragProgress = 0.0;
  double _dragDeltaX = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _animController.addListener(() {
      if (_isAnimating && _turnAnimation != null) {
        setState(() {
          _dragProgress = _turnAnimation!.value;
        });
      }
    });

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimating = false;
        if (_dragProgress >= 0.99 && _targetPage != null) {
          final committedPage = _targetPage!;
          _isTurning = false;
          _targetPage = null;
          _dragProgress = 0.0;
          _dragDeltaX = 0.0;
          widget.controller.isPageTurning.value = false;
          HapticFeedback.selectionClick();
          widget.onPageChanged(committedPage);
        } else {
          // Cancelled turn
          _isTurning = false;
          _targetPage = null;
          _dragProgress = 0.0;
          _dragDeltaX = 0.0;
          widget.controller.isPageTurning.value = false;
        }
        if (mounted) setState(() {});
      }
    });

    // Register flip trigger with controller
    widget.controller.paperFlipState = this;
  }

  @override
  void didUpdateWidget(covariant MushafPaperFlipView oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.paperFlipState = this;
  }

  @override
  void dispose() {
    if (widget.controller.paperFlipState == this) {
      widget.controller.paperFlipState = null;
    }
    _animController.dispose();
    super.dispose();
  }

  /// Programmatic forward turn animation (e.g. from bottom bar next button)
  Future<void> turnNext() async {
    if (_isAnimating || _isTurning) return;
    if (widget.currentPage >= 604) return;

    _isNext = true;
    _targetPage = widget.currentPage + 1;
    _isTurning = true;
    _dragProgress = 0.0;
    widget.controller.isPageTurning.value = true;
    setState(() {});

    _animateTurnTo(1.0, duration: const Duration(milliseconds: 280));
  }

  /// Programmatic backward turn animation (e.g. from bottom bar prev button)
  Future<void> turnPrevious() async {
    if (_isAnimating || _isTurning) return;
    if (widget.currentPage <= 1) return;

    _isNext = false;
    _targetPage = widget.currentPage - 1;
    _isTurning = true;
    _dragProgress = 0.0;
    widget.controller.isPageTurning.value = true;
    setState(() {});

    _animateTurnTo(1.0, duration: const Duration(milliseconds: 280));
  }

  void _animateTurnTo(double targetValue, {Duration duration = const Duration(milliseconds: 240)}) {
    _isAnimating = true;
    _turnAnimation = Tween<double>(
      begin: _dragProgress,
      end: targetValue,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.duration = duration;
    _animController.forward(from: 0.0);
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    if (_isAnimating) return;
    _dragDeltaX = 0.0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    final delta = details.primaryDelta ?? 0.0;
    _dragDeltaX += delta;
    final screenWidth = MediaQuery.of(context).size.width;

    // In Arabic RTL:
    // Dragging left (negative delta) = turn forward to Next Page (+1)
    // Dragging right (positive delta) = turn backward to Previous Page (-1)
    if (!_isTurning) {
      if (_dragDeltaX < -6.0) {
        // Turning to Next Page
        if (widget.currentPage >= 604) return;
        _isTurning = true;
        _isNext = true;
        _targetPage = widget.currentPage + 1;
        widget.controller.isPageTurning.value = true;
      } else if (_dragDeltaX > 6.0) {
        // Turning to Previous Page
        if (widget.currentPage <= 1) return;
        _isTurning = true;
        _isNext = false;
        _targetPage = widget.currentPage - 1;
        widget.controller.isPageTurning.value = true;
      }
    }

    if (_isTurning) {
      double rawProgress;
      if (_isNext) {
        rawProgress = (-_dragDeltaX / (screenWidth * 0.95)).clamp(0.0, 1.0);
      } else {
        rawProgress = (_dragDeltaX / (screenWidth * 0.95)).clamp(0.0, 1.0);
      }

      setState(() {
        _dragProgress = rawProgress;
      });
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isAnimating || !_isTurning) return;

    final velocity = details.primaryVelocity ?? 0.0;
    bool shouldCommit = false;

    if (_isNext) {
      // Swiping left: negative velocity commits
      if (velocity < -250.0 || _dragProgress >= 0.22) {
        shouldCommit = true;
      }
    } else {
      // Swiping right: positive velocity commits
      if (velocity > 250.0 || _dragProgress >= 0.22) {
        shouldCommit = true;
      }
    }

    if (shouldCommit) {
      // Complete paper turn smoothly to 1.0
      final remaining = (1.0 - _dragProgress).clamp(0.1, 1.0);
      final ms = (250 * remaining).toInt().clamp(120, 280);
      _animateTurnTo(1.0, duration: Duration(milliseconds: ms));
    } else {
      // Cancel paper turn smoothly back to 0.0
      final ms = (220 * _dragProgress).toInt().clamp(100, 220);
      _animateTurnTo(0.0, duration: Duration(milliseconds: ms));
    }
  }

  void _handleHorizontalDragCancel() {
    if (_isAnimating || !_isTurning) return;
    _animateTurnTo(0.0, duration: const Duration(milliseconds: 180));
  }

  Widget _buildSinglePage(int pageNumber, {required bool isMoving}) {
    final cached = widget.pagesCache[pageNumber];
    if (cached != null) {
      return MushafPageWidget(
        key: ValueKey('mushaf_page_$pageNumber'),
        page: cached,
        theme: widget.theme,
        isMoving: isMoving,
        isRightPage: pageNumber % 2 != 0,
        pageBookmarkColor: widget.getPageBookmarkColor(pageNumber),
        pageMemorizeStatus: widget.getPageMemorizeStatus(pageNumber),
        bookmarkedAyahs: widget.getAyahBookmarkColors(),
        memorizedAyahs: widget.getAyahMemorizeStatuses(),
        selectedSurah: widget.selectedSurah,
        selectedAyah: widget.selectedAyah,
        onAyahTapped: widget.onAyahTapped,
        onTapPage: widget.onTapPage,
      );
    }

    return FutureBuilder<MushafPage?>(
      future: widget.getPage(pageNumber),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return MushafPageWidget(
            key: ValueKey('mushaf_page_$pageNumber'),
            page: snapshot.data!,
            theme: widget.theme,
            isMoving: isMoving,
            isRightPage: pageNumber % 2 != 0,
            pageBookmarkColor: widget.getPageBookmarkColor(pageNumber),
            pageMemorizeStatus: widget.getPageMemorizeStatus(pageNumber),
            bookmarkedAyahs: widget.getAyahBookmarkColors(),
            memorizedAyahs: widget.getAyahMemorizeStatuses(),
            selectedSurah: widget.selectedSurah,
            selectedAyah: widget.selectedAyah,
            onAyahTapped: widget.onAyahTapped,
            onTapPage: widget.onTapPage,
          );
        }

        return Container(
          color: widget.theme.pageBg,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: widget.theme.frameBorderInner,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    return GestureDetector(
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onHorizontalDragCancel: _handleHorizontalDragCancel,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_isTurning)
            // Stationary view: current page flat and interactive
            _buildSinglePage(widget.currentPage, isMoving: false)
          else ...[
            // Base layer: the page revealed underneath
            if (_targetPage != null)
              RepaintBoundary(
                child: _buildSinglePage(_targetPage!, isMoving: true),
              ),

            // Realistic Paper Curl / Peel Layer
            _buildPaperCurlTransition(width),
          ],
        ],
      ),
    );
  }

  Widget _buildPaperCurlTransition(double width) {
    final t = _dragProgress.clamp(0.0, 1.0);
    // Curl cylinder width scales naturally with progress
    final double curlCylinderWidth = (36.0 + 14.0 * math.sin(t * math.pi)).clamp(20.0, 50.0);

    if (_isNext) {
      // Turning Forward (Next Page):
      // The current page is peeled from right to left across the screen.
      // foldX marks the boundary where paper is curling over.
      final foldX = (width * (1.0 - t)).clamp(0.0, width);

      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Soft Ambient Cast Shadow onto the revealed page underneath
          Positioned(
            top: 0,
            bottom: 0,
            left: (foldX - curlCylinderWidth * 1.2).clamp(0.0, width),
            width: curlCylinderWidth * 1.5,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35 * (1.0 - t * 0.4)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. The Turning Page (clipped to the unpeeled region [0, foldX])
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: foldX,
            child: ClipRect(
              child: OverflowBox(
                minWidth: width,
                maxWidth: width,
                alignment: Alignment.centerLeft,
                child: _buildSinglePage(widget.currentPage, isMoving: true),
              ),
            ),
          ),

          // 3. 3D Perspective Paper Curl Cylinder & Edge Lighting along the fold
          if (foldX > 2.0 && foldX < width - 2.0) ...[
            // Drop shadow cast by the curved page edge
            Positioned(
              top: 0,
              bottom: 0,
              left: foldX,
              width: curlCylinderWidth * 0.8,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.40 * (1.0 - t * 0.3)),
                        Colors.black.withOpacity(0.12 * (1.0 - t * 0.3)),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Highlight and inner paper curl cylinder on the page itself
            Positioned(
              top: 0,
              bottom: 0,
              left: (foldX - curlCylinderWidth).clamp(0.0, width),
              width: curlCylinderWidth,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.30 * (1.0 - t * 0.3)),
                        Colors.black.withOpacity(0.18 * (1.0 - t * 0.3)),
                        Colors.black.withOpacity(0.35 * (1.0 - t * 0.3)),
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 4. Authentic Inner Book Spine Binding Shadow (gutter depth)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 14.0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Turning Backward (Previous Page):
      // The previous page peels in from the left over the current page.
      final foldX = (width * t).clamp(0.0, width);

      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Current page underneath
          _buildSinglePage(widget.currentPage, isMoving: true),

          // 2. Soft Ambient Cast Shadow under the incoming page onto current page
          Positioned(
            top: 0,
            bottom: 0,
            left: foldX,
            width: curlCylinderWidth * 1.4,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.35 * (1.0 - (1.0 - t) * 0.4)),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Incoming Previous Page (clipped to [0, foldX])
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: foldX,
            child: ClipRect(
              child: OverflowBox(
                minWidth: width,
                maxWidth: width,
                alignment: Alignment.centerLeft,
                child: _buildSinglePage(_targetPage!, isMoving: true),
              ),
            ),
          ),

          // 4. Paper Curl Cylinder & Edge Lighting on the incoming page edge
          if (foldX > 2.0 && foldX < width - 2.0)
            Positioned(
              top: 0,
              bottom: 0,
              left: (foldX - curlCylinderWidth).clamp(0.0, width),
              width: curlCylinderWidth,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.30 * t),
                        Colors.black.withOpacity(0.18 * t),
                        Colors.black.withOpacity(0.35 * t),
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Authentic Inner Book Spine Binding Shadow
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 14.0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
