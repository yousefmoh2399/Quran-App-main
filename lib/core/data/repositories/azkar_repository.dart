import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../arabic_normalizer.dart';
import '../models/azkar_entity.dart';

class AzkarRepository {
  final AppDatabase _appDatabase;

  AzkarRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db => _appDatabase.database;

  /// Retrieves all Azkar categories.
  Future<List<AzkarCategoryEntity>> getCategories() async {
    final db = await _db;
    final results = await db.query(
      'azkar_categories',
      orderBy: 'id ASC',
    );
    return results.map((m) => AzkarCategoryEntity.fromMap(m)).toList();
  }

  /// Retrieves all Azkar items for a specific category ID.
  Future<List<AzkarItemEntity>> getAzkarByCategory(int categoryId) async {
    final db = await _db;
    final results = await db.query(
      'azkar',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'id ASC',
    );
    return results.map((m) => AzkarItemEntity.fromMap(m)).toList();
  }

  /// Retrieves all categories with their associated Azkar items.
  Future<List<AzkarCategoryWithItems>> getAllCategoriesWithItems() async {
    final db = await _db;
    final categories = await getCategories();
    final allItemsRaw = await db.query('azkar', orderBy: 'category_id ASC, id ASC');

    final Map<int, List<AzkarItemEntity>> grouped = {};
    for (final raw in allItemsRaw) {
      final item = AzkarItemEntity.fromMap(raw);
      grouped.putIfAbsent(item.categoryId, () => []).add(item);
    }

    return categories.map((cat) {
      return AzkarCategoryWithItems(
        category: cat,
        items: grouped[cat.id] ?? [],
      );
    }).toList();
  }

  /// Searches Azkar by query using FTS5 with fallback to LIKE on normalized text.
  Future<List<AzkarItemEntity>> searchAzkar(String query) async {
    final normalized = ArabicNormalizer.normalize(query);
    if (normalized.isEmpty) return [];

    final db = await _db;

    try {
      final ftsResults = await db.rawQuery('''
        SELECT a.* FROM azkar a
        JOIN azkar_fts f ON a.id = f.rowid
        WHERE f.text_search MATCH ?
        LIMIT 100;
      ''', ['"$normalized"']);

      if (ftsResults.isNotEmpty) {
        return ftsResults.map((m) => AzkarItemEntity.fromMap(m)).toList();
      }
    } catch (_) {
      // Fallback
    }

    final likeResults = await db.query(
      'azkar',
      where: 'text_search LIKE ?',
      whereArgs: ['%$normalized%'],
      orderBy: 'id ASC',
      limit: 100,
    );
    return likeResults.map((m) => AzkarItemEntity.fromMap(m)).toList();
  }
}
