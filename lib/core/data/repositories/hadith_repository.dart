import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../arabic_normalizer.dart';
import '../models/hadith_entity.dart';

class HadithRepository {
  final AppDatabase _appDatabase;

  HadithRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db => _appDatabase.database;

  /// Retrieves all Hadith sections (chapters) in order.
  Future<List<HadithSectionEntity>> getSections() async {
    final db = await _db;
    final results = await db.query(
      'hadith_sections',
      orderBy: 'id ASC',
    );
    return results.map((m) => HadithSectionEntity.fromMap(m)).toList();
  }

  /// Retrieves Hadiths belonging to a specific section ID.
  Future<List<HadithItemEntity>> getHadithsBySection(int sectionId) async {
    final db = await _db;
    final results = await db.query(
      'hadiths',
      where: 'section_id = ?',
      whereArgs: [sectionId],
      orderBy: 'id ASC',
    );
    return results.map((m) => HadithItemEntity.fromMap(m)).toList();
  }

  /// Retrieves all sections along with their hadiths (compatible with legacy view model).
  Future<List<HadithSectionWithHadiths>> getAllSectionsWithHadiths() async {
    final db = await _db;
    final sections = await getSections();
    final allHadithsRaw = await db.query('hadiths', orderBy: 'section_id ASC, id ASC');

    final Map<int, List<HadithItemEntity>> grouped = {};
    for (final raw in allHadithsRaw) {
      final item = HadithItemEntity.fromMap(raw);
      grouped.putIfAbsent(item.sectionId, () => []).add(item);
    }

    return sections.map((sec) {
      return HadithSectionWithHadiths(
        section: sec,
        hadiths: grouped[sec.id] ?? [],
      );
    }).toList();
  }

  /// Searches Hadiths by query using FTS5 with fallback to LIKE on normalized text.
  Future<List<HadithItemEntity>> searchHadiths(String query) async {
    final normalized = ArabicNormalizer.normalize(query);
    if (normalized.isEmpty) return [];

    final db = await _db;

    try {
      final ftsResults = await db.rawQuery('''
        SELECT h.* FROM hadiths h
        JOIN hadiths_fts f ON h.id = f.rowid
        WHERE f.text_search MATCH ?
        LIMIT 100;
      ''', ['"$normalized"']);

      if (ftsResults.isNotEmpty) {
        return ftsResults.map((m) => HadithItemEntity.fromMap(m)).toList();
      }
    } catch (_) {
      // Fallback
    }

    final likeResults = await db.query(
      'hadiths',
      where: 'text_search LIKE ?',
      whereArgs: ['%$normalized%'],
      orderBy: 'id ASC',
      limit: 100,
    );
    return likeResults.map((m) => HadithItemEntity.fromMap(m)).toList();
  }
}
