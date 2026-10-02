/// Models representing aggregated marks, bookmarks, and memorization data
/// for Surahs and Juzs in the Quran index.
class SurahMarksSummary {
  final int surahId;
  final String surahName;
  final int startPage;
  final int endPage;
  final int totalVerses;
  final int memorizedAyahsCount;
  final bool hasBookmark;
  final int? bookmarkedPage;
  final bool isLastRead;
  final int? lastReadPage;

  const SurahMarksSummary({
    required this.surahId,
    required this.surahName,
    required this.startPage,
    required this.endPage,
    required this.totalVerses,
    this.memorizedAyahsCount = 0,
    this.hasBookmark = false,
    this.bookmarkedPage,
    this.isLastRead = false,
    this.lastReadPage,
  });

  /// Ratio of memorized verses (0.0 to 1.0).
  double get memorizedRatio =>
      totalVerses > 0 ? (memorizedAyahsCount / totalVerses).clamp(0.0, 1.0) : 0.0;

  /// Percentage of memorization (0 to 100).
  int get memorizedPercentage => (memorizedRatio * 100).round();

  /// True if 100% of the surah's verses are memorized.
  bool get isFullyMemorized =>
      totalVerses > 0 && memorizedAyahsCount >= totalVerses;

  /// True if partially memorized (at least 1 verse, but not 100%).
  bool get isPartiallyMemorized =>
      memorizedAyahsCount > 0 && !isFullyMemorized;

  SurahMarksSummary copyWith({
    int? surahId,
    String? surahName,
    int? startPage,
    int? endPage,
    int? totalVerses,
    int? memorizedAyahsCount,
    bool? hasBookmark,
    int? bookmarkedPage,
    bool? isLastRead,
    int? lastReadPage,
  }) {
    return SurahMarksSummary(
      surahId: surahId ?? this.surahId,
      surahName: surahName ?? this.surahName,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      totalVerses: totalVerses ?? this.totalVerses,
      memorizedAyahsCount: memorizedAyahsCount ?? this.memorizedAyahsCount,
      hasBookmark: hasBookmark ?? this.hasBookmark,
      bookmarkedPage: bookmarkedPage ?? this.bookmarkedPage,
      isLastRead: isLastRead ?? this.isLastRead,
      lastReadPage: lastReadPage ?? this.lastReadPage,
    );
  }
}

class JuzMarksSummary {
  final int juzNumber;
  final String title;
  final String startSurahName;
  final int startPage;
  final int endPage;
  final int totalVerses;
  final int memorizedAyahsCount;
  final bool hasBookmark;
  final bool isLastRead;
  final int? lastReadPage;

  const JuzMarksSummary({
    required this.juzNumber,
    required this.title,
    required this.startSurahName,
    required this.startPage,
    required this.endPage,
    this.totalVerses = 0,
    this.memorizedAyahsCount = 0,
    this.hasBookmark = false,
    this.isLastRead = false,
    this.lastReadPage,
  });

  /// Ratio of memorized verses (0.0 to 1.0).
  double get memorizedRatio =>
      totalVerses > 0 ? (memorizedAyahsCount / totalVerses).clamp(0.0, 1.0) : 0.0;

  /// Percentage of memorization (0 to 100).
  int get memorizedPercentage => (memorizedRatio * 100).round();

  /// True if 100% of the juz's verses are memorized.
  bool get isFullyMemorized =>
      totalVerses > 0 && memorizedAyahsCount >= totalVerses;

  /// True if partially memorized.
  bool get isPartiallyMemorized =>
      memorizedAyahsCount > 0 && !isFullyMemorized;

  JuzMarksSummary copyWith({
    int? juzNumber,
    String? title,
    String? startSurahName,
    int? startPage,
    int? endPage,
    int? totalVerses,
    int? memorizedAyahsCount,
    bool? hasBookmark,
    bool? isLastRead,
    int? lastReadPage,
  }) {
    return JuzMarksSummary(
      juzNumber: juzNumber ?? this.juzNumber,
      title: title ?? this.title,
      startSurahName: startSurahName ?? this.startSurahName,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      totalVerses: totalVerses ?? this.totalVerses,
      memorizedAyahsCount: memorizedAyahsCount ?? this.memorizedAyahsCount,
      hasBookmark: hasBookmark ?? this.hasBookmark,
      isLastRead: isLastRead ?? this.isLastRead,
      lastReadPage: lastReadPage ?? this.lastReadPage,
    );
  }
}

/// Metadata for a single Surah's structure in the standard Madinah Mushaf.
class SurahMetadata {
  final int id;
  final String nameAr;
  final int totalVerses;
  final int startPage;
  final int endPage;
  final Map<int, List<int>> ayahsByPage; // pageNumber -> list of ayahNumbers

  const SurahMetadata({
    required this.id,
    required this.nameAr,
    required this.totalVerses,
    required this.startPage,
    required this.endPage,
    required this.ayahsByPage,
  });
}

/// Precomputed structural layout of the Quran (Surahs, pages, and Juzs).
class QuranIndexStructure {
  final Map<int, SurahMetadata> surahs; // surahId -> metadata
  final Map<int, List<int>> pageToSurahs; // pageNumber -> list of surahIds
  final Map<int, List<int>> juzPages; // juzNumber -> [startPage, endPage]

  const QuranIndexStructure({
    required this.surahs,
    required this.pageToSurahs,
    required this.juzPages,
  });
}

/// Combined aggregate result of all marks (bookmarks, memorization, last-read)
/// for high-performance instant index rendering.
class QuranMarksAggregate {
  final Map<int, SurahMarksSummary> surahs;
  final Map<int, JuzMarksSummary> juzs;
  final int? lastReadPage;
  final int? lastReadSurah;
  final String? lastReadSurahName;

  const QuranMarksAggregate({
    required this.surahs,
    required this.juzs,
    this.lastReadPage,
    this.lastReadSurah,
    this.lastReadSurahName,
  });
}

