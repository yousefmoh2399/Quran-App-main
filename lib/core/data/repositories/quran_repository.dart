import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../arabic_normalizer.dart';
import '../models/ayah_entity.dart';
import '../models/surah_entity.dart';

class QuranRepository {
  final AppDatabase _appDatabase;

  QuranRepository({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<Database> get _db => _appDatabase.database;

  /// Retrieves all 114 Surahs ordered by ID.
  Future<List<SurahEntity>> getSurahs() async {
    final db = await _db;
    final results = await db.query(
      'surahs',
      orderBy: 'id ASC',
    );
    return results.map((m) => SurahEntity.fromMap(m)).toList();
  }

  /// Retrieves a specific Surah by its ID.
  Future<SurahEntity?> getSurahById(int id) async {
    final db = await _db;
    final results = await db.query(
      'surahs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SurahEntity.fromMap(results.first);
  }

  /// Retrieves all Ayahs for a given Surah ID ordered by ayah_number.
  Future<List<AyahEntity>> getAyahs(int surahId) async {
    final db = await _db;
    final results = await db.query(
      'ayahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'ayah_number ASC',
    );
    return results.map((m) => AyahEntity.fromMap(m)).toList();
  }

  /// Retrieves the Muyassar Tafsir for a specific Surah and Ayah number.
  Future<String?> getTafsir(int surahId, int ayahNumber) async {
    final db = await _db;
    final results = await db.query(
      'ayahs',
      columns: ['tafsir_muyassar'],
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['tafsir_muyassar'] as String?;
  }

  /// Retrieves a specific Ayah by its Surah ID and Ayah number.
  Future<AyahEntity?> getAyah(int surahId, int ayahNumber) async {
    final db = await _db;
    final results = await db.query(
      'ayahs',
      where: 'surah_id = ? AND ayah_number = ?',
      whereArgs: [surahId, ayahNumber],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return AyahEntity.fromMap(results.first);
  }

  /// Searches Ayahs by query using FTS5 with fallback to LIKE on normalized text.
  Future<List<AyahEntity>> searchAyahs(String query) async {
    final normalized = ArabicNormalizer.normalize(query);
    if (normalized.isEmpty) return [];

    final db = await _db;

    try {
      // 1. Attempt FTS5 search
      final ftsResults = await db.rawQuery('''
        SELECT a.* FROM ayahs a
        JOIN ayahs_fts f ON a.id = f.rowid
        WHERE f.text_search MATCH ?
        ORDER TO MATCH
        LIMIT 100;
      ''', ['"$normalized"']);

      if (ftsResults.isNotEmpty) {
        return ftsResults.map((m) => AyahEntity.fromMap(m)).toList();
      }
    } catch (_) {
      // Fallback below if FTS query syntax error or no results
    }

    // 2. Substring LIKE search on normalized text
    final likeResults = await db.query(
      'ayahs',
      where: 'text_search LIKE ?',
      whereArgs: ['%$normalized%'],
      orderBy: 'surah_id ASC, ayah_number ASC',
      limit: 100,
    );
    return likeResults.map((m) => AyahEntity.fromMap(m)).toList();
  }

  /// Retrieves all Surahs paired with their Ayahs.
  Future<List<Map<String, dynamic>>> getAllSurahsWithAyahsRaw() async {
    final db = await _db;
    final surahs = await getSurahs();
    final ayahs = await db.query(
      'ayahs',
      orderBy: 'surah_id ASC, ayah_number ASC',
    );

    final Map<int, List<Map<String, dynamic>>> groupedAyahs = {};
    for (final a in ayahs) {
      final surahId = a['surah_id'] as int;
      groupedAyahs.putIfAbsent(surahId, () => []).add(a);
    }

    return surahs.map((s) {
      return {
        'surah': s,
        'ayahs': groupedAyahs[s.id] ?? [],
      };
    }).toList();
  }
}
