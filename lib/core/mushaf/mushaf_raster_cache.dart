import 'dart:ui' as ui;
import '../../features/mushaf/presentation/models/mushaf_theme_model.dart';

/// LRU Memory cache for rasterized Mushaf page images.
///
/// Keeps at most [maxCapacity] pages in memory to ensure ultra-low RAM footprint
/// (<50MB) on low-end devices (e.g. 2GB RAM Android 8+).
class MushafRasterCache {
  MushafRasterCache._();
  static final MushafRasterCache instance = MushafRasterCache._();

  static const int maxCapacity = 5;

  // Map maintaining insertion order (LinkedHashMap in Dart)
  final Map<String, ui.Image> _cache = {};

  int _hits = 0;
  int _misses = 0;

  int get hits => _hits;
  int get misses => _misses;
  double get hitRatio => (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0.0;

  /// Returns estimated GPU/RAM memory in bytes for all cached textures.
  /// (RGBA = 4 bytes per pixel)
  int get estimatedMemoryBytes {
    int bytes = 0;
    for (final img in _cache.values) {
      bytes += img.width * img.height * 4;
    }
    return bytes;
  }

  /// Estimated memory in MegaBytes (MB)
  double get estimatedMemoryMB => estimatedMemoryBytes / (1024.0 * 1024.0);

  String _key(int pageNumber, MushafThemeMode mode) => '${pageNumber}_${mode.name}';

  /// Returns cached image for the given page and theme, or null if not cached.
  /// Moves the entry to the end to maintain LRU order.
  ui.Image? get(int pageNumber, MushafThemeMode mode) {
    final key = _key(pageNumber, mode);
    final image = _cache.remove(key);
    if (image != null) {
      _cache[key] = image;
      _hits++;
      return image;
    }
    _misses++;
    return null;
  }

  /// Stores a newly rasterized page image, evicting the least recently used
  /// entry if capacity exceeds [maxCapacity].
  void put(int pageNumber, MushafThemeMode mode, ui.Image image) {
    final key = _key(pageNumber, mode);
    if (_cache.containsKey(key)) {
      final old = _cache.remove(key);
      old?.dispose();
    } else if (_cache.length >= maxCapacity) {
      final oldestKey = _cache.keys.first;
      final oldestImage = _cache.remove(oldestKey);
      oldestImage?.dispose();
    }
    _cache[key] = image;
  }

  /// Checks if an image is currently cached for the given page and theme.
  bool has(int pageNumber, MushafThemeMode mode) {
    return _cache.containsKey(_key(pageNumber, mode));
  }

  /// Removes and disposes an image for a specific page.
  void remove(int pageNumber, MushafThemeMode mode) {
    final key = _key(pageNumber, mode);
    final image = _cache.remove(key);
    image?.dispose();
  }

  /// Removes and disposes cached images across all themes for a specific page.
  void removePage(int pageNumber) {
    for (final mode in MushafThemeMode.values) {
      remove(pageNumber, mode);
    }
  }

  /// Clears the entire cache and disposes all native image textures.
  void clear() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Current number of cached raster pages.
  int get length => _cache.length;
}
