import 'package:flutter/services.dart';

/// Manages lazy loading and caching of 604 QPC V2 Hafs page fonts.
///
/// Uses Flutter's [FontLoader] to load WOFF2 page fonts dynamically into memory
/// as needed, avoiding loading ~93 MB into RAM at once.
/// Supports preloading next and previous pages for smooth navigation.
class MushafFontManager {
  MushafFontManager._();
  static final MushafFontManager instance = MushafFontManager._();

  final Set<int> _loadedPages = {};
  final Map<int, Future<void>> _loadingFutures = {};

  final Set<int> _loadedPagesV1 = {};
  final Map<int, Future<void>> _loadingFuturesV1 = {};

  /// Font family name for a given mushaf page (1..604).
  static String pageFontFamily(int pageNumber) => 'QPC_V2_P$pageNumber';

  /// Font family name for QPC V1 for a given mushaf page (1..604).
  static String pageFontFamilyV1(int pageNumber) => 'QPC_V1_P$pageNumber';

  /// Check whether a page font (V2) is already loaded in memory.
  bool isPageLoaded(int pageNumber) => _loadedPages.contains(pageNumber);

  /// Check whether a page font (V1) is already loaded in memory.
  bool isPageLoadedV1(int pageNumber) => _loadedPagesV1.contains(pageNumber);

  /// Ensure font for [pageNumber] is loaded in memory.
  Future<void> ensurePageLoaded(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    if (_loadedPages.contains(pageNumber)) return;

    if (_loadingFutures.containsKey(pageNumber)) {
      return _loadingFutures[pageNumber];
    }

    final future = _loadPageFont(pageNumber);
    _loadingFutures[pageNumber] = future;
    try {
      await future;
    } finally {
      _loadingFutures.remove(pageNumber);
    }
  }

  /// Ensure QPC V1 font for [pageNumber] is loaded in memory.
  Future<void> ensurePageLoadedV1(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    if (_loadedPagesV1.contains(pageNumber)) return;

    if (_loadingFuturesV1.containsKey(pageNumber)) {
      return _loadingFuturesV1[pageNumber];
    }

    final future = _loadPageFontV1(pageNumber);
    _loadingFuturesV1[pageNumber] = future;
    try {
      await future;
    } finally {
      _loadingFuturesV1.remove(pageNumber);
    }
  }

  /// Preload nearby pages around [currentPage] (e.g. current - 1, current + 1)
  /// in the background without blocking the UI thread.
  void preloadSurroundingPages(int currentPage) {
    if (currentPage > 1) {
      ensurePageLoaded(currentPage - 1).catchError((_) {});
    }
    if (currentPage < 604) {
      ensurePageLoaded(currentPage + 1).catchError((_) {});
    }
  }

  Future<void> _loadPageFont(int pageNumber) async {
    final fontName = pageFontFamily(pageNumber);
    final assetPath = 'assets/fonts/qpc_v2/p$pageNumber.ttf';

    final fontLoader = FontLoader(fontName);
    final fontData = rootBundle.load(assetPath);
    fontLoader.addFont(fontData);
    await fontLoader.load();

    _loadedPages.add(pageNumber);
  }

  Future<void> _loadPageFontV1(int pageNumber) async {
    final fontName = pageFontFamilyV1(pageNumber);
    final assetPath = 'assets/fonts/qpc_v1/p$pageNumber.ttf';

    final fontLoader = FontLoader(fontName);
    final fontData = rootBundle.load(assetPath);
    fontLoader.addFont(fontData);
    await fontLoader.load();

    _loadedPagesV1.add(pageNumber);
  }
}

