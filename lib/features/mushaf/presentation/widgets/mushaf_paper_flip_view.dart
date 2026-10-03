import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/util/assets.dart';
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
  final BookmarkColor? selectedAyahColor;
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
    this.selectedAyahColor,
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
      duration: const Duration(milliseconds: 520),
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
          HapticFeedback.lightImpact();
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
    HapticFeedback.selectionClick();
    setState(() {});

    _animateTurnTo(1.0, duration: const Duration(milliseconds: 480));
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
    HapticFeedback.selectionClick();
    setState(() {});

    _animateTurnTo(1.0, duration: const Duration(milliseconds: 480));
  }

  void _animateTurnTo(double targetValue, {Duration duration = const Duration(milliseconds: 480)}) {
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

    // Authentic Arabic RTL Mushaf:
    // Dragging left (negative delta) = turn page forward to Next Page (+1) (تقليب لليمين -> يسار للمتابعة)
    // Dragging right (positive delta) = turn page backward to Previous Page (-1) (رجوع للصفحة السابقة)
    if (!_isTurning) {
      if (_dragDeltaX < -6.0) {
        // Turning to Next Page
        if (widget.currentPage >= 604) return;
        _isTurning = true;
        _isNext = true;
        _targetPage = widget.currentPage + 1;
        widget.controller.isPageTurning.value = true;
        HapticFeedback.selectionClick();
      } else if (_dragDeltaX > 6.0) {
        // Turning to Previous Page
        if (widget.currentPage <= 1) return;
        _isTurning = true;
        _isNext = false;
        _targetPage = widget.currentPage - 1;
        widget.controller.isPageTurning.value = true;
        HapticFeedback.selectionClick();
      }
    }

    if (_isTurning) {
      double rawProgress;
      if (_isNext) {
        rawProgress = (-_dragDeltaX / (screenWidth * 0.88)).clamp(0.0, 1.0);
      } else {
        rawProgress = (_dragDeltaX / (screenWidth * 0.88)).clamp(0.0, 1.0);
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
      if (velocity < -220.0 || _dragProgress >= 0.20) {
        shouldCommit = true;
      }
    } else {
      // Swiping right: positive velocity commits
      if (velocity > 220.0 || _dragProgress >= 0.20) {
        shouldCommit = true;
      }
    }

    if (shouldCommit) {
      // Complete paper turn smoothly
      final remaining = (1.0 - _dragProgress).clamp(0.1, 1.0);
      final ms = (480 * remaining).toInt().clamp(240, 480);
      _animateTurnTo(1.0, duration: Duration(milliseconds: ms));
    } else {
      // Cancel paper turn smoothly back
      final ms = (350 * _dragProgress).toInt().clamp(160, 350);
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
        selectedAyahColor: widget.selectedAyahColor,
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
            selectedAyahColor: widget.selectedAyahColor,
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

    if (_isNext) {
      // Turning Forward (Next Page):
      // The current page leaf physically rotates in 3D around the left spine (0° to -180°).
      final angle = -t * math.pi;
      final isFrontVisible = t < 0.5;

      final liftProgress = math.sin(t * math.pi);
      final shadowWidth = (width * 0.70 * liftProgress).clamp(16.0, width);
      final shadowOpacity = (0.48 * liftProgress).clamp(0.0, 0.48);

      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Revealed Page Underneath (Next Page)
          if (_targetPage != null)
            _buildSinglePage(_targetPage!, isMoving: true),

          // 2. Realistic Dynamic Cast Drop Shadow cast onto the revealed page
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: shadowWidth,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(shadowOpacity * 0.85),
                      Colors.black.withOpacity(shadowOpacity * 0.45),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. The 3D Turning Page Leaf (Pivoting around the Left Spine)
          Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // Realistic 3D perspective depth
              ..rotateY(angle),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isFrontVisible) ...[
                  // Front: The current page with all text, frame, and verses visibly rotating in 3D
                  _buildSinglePage(widget.currentPage, isMoving: true),

                  // Dynamic paper curvature gradient & highlight as it catches light
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.35 * t), // Spine crease shadow
                            Colors.transparent,
                            Colors.white.withOpacity(0.40 * liftProgress), // Peak curve highlight
                            Colors.black.withOpacity(0.20 * t), // Outer bend shadow
                          ],
                          stops: const [0.0, 0.35, 0.70, 1.0],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Back of the page (turned past 90 degrees)
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBackOfPage(),
                  ),

                  // Soft shadow on the back of the turning page as it settles
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.black.withOpacity(0.30 * (1.0 - t)),
                            Colors.white.withOpacity(0.35 * liftProgress),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.40, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 4. Authentic Quran Book Spine Gutter Depth Shadow (كعب المصحف)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 24.0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.32),
                      Colors.black.withOpacity(0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.40, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Turning Backward (Previous Page):
      // The previous page (_targetPage) sweeps in from the left over the current page!
      final angle = -(1.0 - t) * math.pi;
      final isFrontVisible = t >= 0.5;

      final liftProgress = math.sin(t * math.pi);
      final shadowWidth = (width * 0.70 * liftProgress).clamp(16.0, width);
      final shadowOpacity = (0.48 * liftProgress).clamp(0.0, 0.48);

      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Current Page Underneath (stays flat until covered)
          _buildSinglePage(widget.currentPage, isMoving: true),

          // 2. Cast Drop Shadow onto the current page
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: shadowWidth,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(shadowOpacity * 0.85),
                      Colors.black.withOpacity(shadowOpacity * 0.45),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. The 3D Incoming Page Leaf (Pivoting around the Left Spine)
          Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isFrontVisible) ...[
                  // Front of previous page landing flat
                  if (_targetPage != null)
                    _buildSinglePage(_targetPage!, isMoving: true),

                  // Ambient lighting as it settles
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.35 * (1.0 - t)),
                            Colors.transparent,
                            Colors.white.withOpacity(0.40 * liftProgress),
                            Colors.black.withOpacity(0.20 * (1.0 - t)),
                          ],
                          stops: const [0.0, 0.35, 0.70, 1.0],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Back of incoming page rising from left
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBackOfPage(),
                  ),

                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.black.withOpacity(0.30 * t),
                            Colors.white.withOpacity(0.35 * liftProgress),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.40, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 4. Authentic Quran Book Spine Gutter Depth Shadow
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: 24.0,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.32),
                      Colors.black.withOpacity(0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.40, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBackOfPage() {
    return Container(
      color: widget.theme.pageBg,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.theme.frameBorderOuter.withOpacity(0.25),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                AssetsData.mushaf_1,
                width: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
