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

  /// Font family name for a given mushaf page (1..604).
  static String pageFontFamily(int pageNumber) => 'QPC_V2_P$pageNumber';

  /// Check whether a page font is already loaded in memory.
  bool isPageLoaded(int pageNumber) => _loadedPages.contains(pageNumber);

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

  /// Preload nearby pages around [currentPage] (current +-1 to +-4)
  /// in the background without blocking the UI thread.
  void preloadSurroundingPages(int currentPage) {
    final targets = <int>[
      for (int i = 1; i <= 4; i++) ...[
        if (currentPage - i >= 1) currentPage - i,
        if (currentPage + i <= 604) currentPage + i,
      ],
    ];
    for (final page in targets) {
      ensurePageLoaded(page).catchError((_) {});
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
}
