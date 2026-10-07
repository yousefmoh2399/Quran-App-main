import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:sqflite/sqflite.dart';

/// Top-level parser function executed inside isolate via [compute].
GuideModel parseGuideJsonIsolate(String jsonString) {
  final Map<String, dynamic> decoded = json.decode(jsonString) as Map<String, dynamic>;
  return GuideModel.fromJson(decoded);
}

/// Generic, offline-first Guide Engine for Umrah, Rawdah, Hajj, and pilgrimage rites.
///
/// Features:
/// - Background isolate parsing via [compute] to prevent UI jank.
/// - Progress persistence into local SQLite `guide_progress` table.
/// - Offline trip diary persistence into local SQLite `trip_diary` table.
class GuideEngine {
  final UserDatabase _userDb;

  GuideEngine({UserDatabase? userDb}) : _userDb = userDb ?? UserDatabase.instance;

  static const String defaultUmrahAssetPath = 'assets/content/umrah_guide.json';

  /// Loads the guide definition from assets (or raw JSON) in an isolate,
  /// then merges any persisted progress from the local SQLite database.
  Future<GuideModel> loadGuide({
    String assetPath = defaultUmrahAssetPath,
    String? rawJsonString,
  }) async {
    String jsonString;
    if (rawJsonString != null && rawJsonString.isNotEmpty) {
      jsonString = rawJsonString;
    } else {
      jsonString = await rootBundle.loadString(assetPath);
    }

    // Parse in background isolate
    final GuideModel parsedGuide = await compute(parseGuideJsonIsolate, jsonString);

    // Merge SQLite persistence
    final progressMap = await getGuideProgressMap(parsedGuide.id);

    final updatedSteps = parsedGuide.steps.map((step) {
      final saved = progressMap[step.id];
      if (saved != null) {
        return step.copyWith(
          isCompleted: saved['is_completed'] == 1,
          completedAt: saved['completed_at'] != null
              ? DateTime.tryParse(saved['completed_at'] as String)
              : null,
          currentLap: (saved['current_lap'] as int?) ?? 0,
        );
      }
      return step;
    }).toList();

    return GuideModel(
      id: parsedGuide.id,
      title: parsedGuide.title,
      subtitle: parsedGuide.subtitle,
      version: parsedGuide.version,
      disclaimer: parsedGuide.disclaimer,
      reviewedAt: parsedGuide.reviewedAt,
      defaultSource: parsedGuide.defaultSource,
      steps: updatedSteps,
      congestion: parsedGuide.congestion,
      sourcesReview: parsedGuide.sourcesReview,
    );
  }

  /// Retrieves a map of step progress for a given guide.
  Future<Map<String, Map<String, dynamic>>> getGuideProgressMap(String guideId) async {
    try {
      final db = await _userDb.database;
      final results = await db.query(
        'guide_progress',
        where: 'guide_id = ?',
        whereArgs: [guideId],
      );

      final map = <String, Map<String, dynamic>>{};
      for (final row in results) {
        final stepId = row['step_id'] as String;
        map[stepId] = row;
      }
      return map;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('GuideEngine.getGuideProgressMap error: $e\n$st');
      }
      return {};
    }
  }

  /// Saves or updates the completion state and current lap for a step.
  Future<void> saveStepProgress({
    required String guideId,
    required String stepId,
    required bool isCompleted,
    int currentLap = 0,
  }) async {
    try {
      final db = await _userDb.database;
      final now = DateTime.now().toIso8601String();

      await db.insert(
        'guide_progress',
        {
          'guide_id': guideId,
          'step_id': stepId,
          'is_completed': isCompleted ? 1 : 0,
          'completed_at': isCompleted ? now : null,
          'current_lap': currentLap,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('GuideEngine.saveStepProgress error: $e\n$st');
      }
    }
  }

  /// Resets progress for an entire guide (e.g. starting a new Umrah).
  Future<void> resetGuideProgress(String guideId) async {
    try {
      final db = await _userDb.database;
      await db.delete(
        'guide_progress',
        where: 'guide_id = ?',
        whereArgs: [guideId],
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('GuideEngine.resetGuideProgress error: $e\n$st');
      }
    }
  }

  // ==========================================
  // TRIP DIARY / NOTES METHODS
  // ==========================================

  /// Inserts a new personal note into the trip diary.
  Future<int> addDiaryEntry(TripDiaryEntry entry) async {
    final db = await _userDb.database;
    return await db.insert(
      'trip_diary',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches trip diary notes, optionally filtered by keyword.
  Future<List<TripDiaryEntry>> getDiaryEntries({String? query}) async {
    final db = await _userDb.database;
    List<Map<String, dynamic>> results;

    if (query != null && query.trim().isNotEmpty) {
      final pattern = '%${query.trim()}%';
      results = await db.query(
        'trip_diary',
        where: 'title LIKE ? OR content LIKE ? OR category LIKE ?',
        whereArgs: [pattern, pattern, pattern],
        orderBy: 'created_at DESC',
      );
    } else {
      results = await db.query(
        'trip_diary',
        orderBy: 'created_at DESC',
      );
    }

    return results.map(TripDiaryEntry.fromMap).toList();
  }

  /// Updates an existing diary entry.
  Future<int> updateDiaryEntry(TripDiaryEntry entry) async {
    if (entry.id == null) return 0;
    final db = await _userDb.database;
    return await db.update(
      'trip_diary',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Deletes a diary entry by ID.
  Future<int> deleteDiaryEntry(int id) async {
    final db = await _userDb.database;
    return await db.delete(
      'trip_diary',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
