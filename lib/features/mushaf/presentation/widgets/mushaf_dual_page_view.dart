import 'package:flutter/material.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../models/mushaf_theme_model.dart';
import 'mushaf_page_widget.dart';

/// Renders facing dual pages side-by-side (Dual-page spread) for tablets
/// and landscape mode, featuring an authentic central book spine fold shadow.
class MushafDualPageView extends StatefulWidget {
  final int currentPage;
  final MushafThemeConfig theme;
  final Map<int, MushafPage> pagesCache;
  final int? selectedSurah;
  final int? selectedAyah;
  final Future<MushafPage?> Function(int pageNumber) getPage;
  final void Function(int newPage) onPageChanged;
  final void Function(int surahNumber, int ayahNumber)? onAyahTapped;
  final VoidCallback? onTapPage;

  const MushafDualPageView({
    super.key,
    required this.currentPage,
    required this.theme,
    required this.pagesCache,
    required this.getPage,
    required this.onPageChanged,
    this.selectedSurah,
    this.selectedAyah,
    this.onAyahTapped,
    this.onTapPage,
  });

  @override
  State<MushafDualPageView> createState() => _MushafDualPageViewState();
}

class _MushafDualPageViewState extends State<MushafDualPageView> {
  late PageController _pageController;
  late int _currentSpread;

  @override
  void initState() {
    super.initState();
    _currentSpread = (widget.currentPage - 1) ~/ 2;
    _pageController = PageController(initialPage: _currentSpread);
  }

  @override
  void didUpdateWidget(covariant MushafDualPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetSpread = (widget.currentPage - 1) ~/ 2;
    if (targetSpread != _currentSpread && _pageController.hasClients) {
      _currentSpread = targetSpread;
      _pageController.jumpToPage(targetSpread);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 604 pages -> 302 spreads
    const int totalSpreads = 302;

    return PageView.builder(
      controller: _pageController,
      reverse: true, // RTL page turning
      physics: const BouncingScrollPhysics(),
      itemCount: totalSpreads,
      onPageChanged: (spreadIndex) {
        _currentSpread = spreadIndex;
        final rightPageNum = (spreadIndex * 2) + 1;
        widget.onPageChanged(rightPageNum);
      },
      itemBuilder: (context, spreadIndex) {
        final rightPageNum = (spreadIndex * 2) + 1;
        final leftPageNum = rightPageNum + 1;

        return Row(
          children: [
            // Left Page (even page, e.g. 2, 4, 6...)
            Expanded(
              child: leftPageNum <= 604
                  ? _buildPageSlot(leftPageNum, isRight: false)
                  : Container(color: widget.theme.pageBg),
            ),

            // Central Mushaf Spine Fold Divider ("فاصل طيّة المصحف")
            _buildSpineDivider(),

            // Right Page (odd page, e.g. 1, 3, 5...)
            Expanded(
              child: _buildPageSlot(rightPageNum, isRight: true),
            ),
          ],
        );
      },
    );
  }

  /// Builds the realistic central spine fold shadow between the two facing pages.
  Widget _buildSpineDivider() {
    return Container(
      width: 14.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.04),
            widget.theme.spineShadow,
            Colors.black.withOpacity(0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildPageSlot(int pageNum, {required bool isRight}) {
    final cached = widget.pagesCache[pageNum];
    if (cached != null) {
      return MushafPageWidget(
        page: cached,
        theme: widget.theme,
        isRightPage: isRight,
        selectedSurah: widget.selectedSurah,
        selectedAyah: widget.selectedAyah,
        onAyahTapped: widget.onAyahTapped,
        onTapPage: widget.onTapPage,
      );
    }

    return FutureBuilder<MushafPage?>(
      future: widget.getPage(pageNum),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return MushafPageWidget(
            page: snapshot.data!,
            theme: widget.theme,
            isRightPage: isRight,
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
}
