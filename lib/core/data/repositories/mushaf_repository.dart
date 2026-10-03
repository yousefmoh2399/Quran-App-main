import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/ayah_entity.dart';
import '../models/mushaf_models.dart';
import '../arabic_normalizer.dart';

/// Repository for authentic 604-page, 15-line Madinah Mushaf operations.
class MushafRepository {
  final AppDatabase _appDatabase;

  MushafRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db => _appDatabase.database;

  /// Retrieves the 15 lines of [pageNumber] with their words and glyphs,
  /// as well as the active Surah name and Juz number for the page header.
  Future<MushafPage> getPage(int pageNumber) async {
    assert(pageNumber >= 1 && pageNumber <= 604, 'Page must be between 1 and 604');
    final db = await _db;

    // Fetch lines for this page ordered by line_number ASC
    final lineRows = await db.query(
      'mushaf_lines',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC',
    );

    // Fetch all words for this page ordered by line_number ASC, id ASC
    // Note: id reflects the exact sequential reading order in the Quran text.
    final wordRows = await db.query(
      'mushaf_words',
      where: 'page_number = ?',
      whereArgs: [pageNumber],
      orderBy: 'line_number ASC, id ASC',
    );

    final wordsByLine = <int, List<MushafWord>>{};
    for (final row in wordRows) {
      final word = MushafWord.fromMap(row);
      wordsByLine.putIfAbsent(word.lineNumber, () => []).add(word);
    }

    final lines = <MushafLine>[];
    int? detectedSurah;

    for (final row in lineRows) {
      final lineNum = row['line_number'] as int;
      final lineWords = wordsByLine[lineNum] ?? const [];
      final line = MushafLine.fromMap(row, words: lineWords);
      lines.add(line);

      if (detectedSurah == null) {
        if (line.surahNumber != null) {
          detectedSurah = line.surahNumber;
        } else if (lineWords.isNotEmpty) {
          detectedSurah = lineWords.first.surahNumber;
        }
      }
    }

    // Determine Surah Name
    String surahName = '';
    if (detectedSurah != null) {
      final surahRow = await db.query(
        'surahs',
        columns: ['name_ar'],
        where: 'id = ?',
        whereArgs: [detectedSurah],
        limit: 1,
      );
      if (surahRow.isNotEmpty) {
        surahName = (surahRow.first['name_ar'] as String?) ?? '';
      }
    }

    // Determine Juz Number
    int juzNumber = 1;
    final juzRows = await db.query(
      'juz_metadata',
      where: 'start_page <= ?',
      whereArgs: [pageNumber],
      orderBy: 'juz_number DESC',
      limit: 1,
    );
    if (juzRows.isNotEmpty) {
      juzNumber = juzRows.first['juz_number'] as int;
    }

    return MushafPage(
      pageNumber: pageNumber,
      lines: lines,
      surahNumber: detectedSurah ?? 1,
      surahNameAr: surahName,
      juzNumber: juzNumber,
    );
  }

  /// Returns the page number where a given [surahNumber] and [ayahNumber] is located.
  Future<int?> getPageOfAyah(int surahNumber, int ayahNumber) async {
    final db = await _db;
    final res = await db.query(
      'ayahs',
      columns: ['page_number'],
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahNumber, ayahNumber],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['page_number'] as int?;
  }

  /// Returns the starting page number of a [surahNumber].
  Future<int?> getSurahStart(int surahNumber) async {
    final db = await _db;
    final res = await db.query(
      'ayahs',
      columns: ['page_number'],
      where: 'surah_id = ? AND ayah_number = 1',
      whereArgs: [surahNumber],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['page_number'] as int?;
  }

  /// Returns the starting page number of a [juzNumber] (1..30).
  Future<int?> getJuzStart(int juzNumber) async {
    final db = await _db;
    final res = await db.query(
      'juz_metadata',
      columns: ['start_page'],
      where: 'juz_number = ?',
      whereArgs: [juzNumber],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['start_page'] as int?;
  }

  /// Searches for Ayahs matching [query] using normalized Arabic text.
  Future<List<AyahEntity>> searchAyahs(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await _db;
    final normalized = ArabicNormalizer.normalize(query);

    final results = await db.query(
      'ayahs',
      where: 'text_search LIKE ?',
      whereArgs: ['%$normalized%'],
      orderBy: 'surah_id ASC, ayah_number ASC',
      limit: 50,
    );

    return results.map((m) => AyahEntity.fromMap(m)).toList();
  }

  /// Retrieves all 15 Sajdah positions in the Quran.
  Future<List<SajdahInfo>> getSajdahs() async {
    final db = await _db;
    final res = await db.query(
      'sajdahs',
      orderBy: 'sajdah_number ASC',
    );
    return res.map((m) => SajdahInfo.fromMap(m)).toList();
  }

  /// Retrieves all 30 Ajza' metadata.
  Future<List<JuzInfo>> getAjza() async {
    final db = await _db;
    final res = await db.query(
      'juz_metadata',
      orderBy: 'juz_number ASC',
    );
    return res.map((m) => JuzInfo.fromMap(m)).toList();
  }
}
