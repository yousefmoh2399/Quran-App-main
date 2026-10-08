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
  static const String defaultHajjAssetPath = 'assets/content/hajj_guide.json';

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

  static const List<Map<String, String>> defaultChecklistSeed = [
    {'title': 'إزار ورداء أبيضين قطنيين نظيفين', 'category': 'ملابس الإحرام'},
    {'title': 'حزام إحرام جلدي أو قماشي مع جيب', 'category': 'ملابس الإحرام'},
    {'title': 'نعل مريح خفيف بدون تغطية للكعبين', 'category': 'ملابس الإحرام'},
    {'title': 'دبابيس وملاقط لتثبيت رداء الإحرام', 'category': 'ملابس الإحرام'},
    {'title': 'إحرام إضافي احتياطي', 'category': 'ملابس الإحرام'},
    {'title': 'جواز السفر وتأشيرة العمرة أو الحج', 'category': 'المستندات'},
    {'title': 'تصريح نسك وباركود الدخول للروضة والحرم', 'category': 'المستندات'},
    {'title': 'كرت التطعيمات والشهادة الصحية', 'category': 'المستندات'},
    {'title': 'عناوين وأرقام الفندق ومرشد الحملة', 'category': 'المستندات'},
    {'title': 'الأدوية الشخصية والمزمنة بكمية كافية', 'category': 'الحقيبة الطبية'},
    {'title': 'مسكن للألم وخافض للحرارة', 'category': 'الحقيبة الطبية'},
    {'title': 'مرهم مضاد للتسلخات والالتهابات', 'category': 'الحقيبة الطبية'},
    {'title': 'لاصقات طبية للجروح وبثور المشي', 'category': 'الحقيبة الطبية'},
    {'title': 'معقم يدين وصابون غير معطر للإحرام', 'category': 'الحقيبة الطبية'},
    {'title': 'مظلة شمسية خفيفة واقية من الحرارة', 'category': 'الأغراض الشخصية'},
    {'title': 'مقص أظافر وشعر للتحلل بعد السعي', 'category': 'الأغراض الشخصية'},
    {'title': 'شاحن متنقل (باور بانك) للهاتف', 'category': 'الأغراض الشخصية'},
    {'title': 'كيس قماشي لحفظ الحذاء في الحرم', 'category': 'الأغراض الشخصية'},
    {'title': 'نظارة شمسية لحماية العينين من الوهج', 'category': 'الأغراض الشخصية'},
    {'title': 'تقليم الأظافر وإزالة الشعر الزائد', 'category': 'سنن قبل الإحرام'},
    {'title': 'الاغتسال الكامل بنية النظافة للإحرام', 'category': 'سنن قبل الإحرام'},
    {'title': 'التطيب في البدن واللحية قبل عقد النية', 'category': 'سنن قبل الإحرام'},
  ];

  /// Fetches checklist items, seeding defaults if database table is empty.
  Future<List<PilgrimChecklistItem>> getChecklistItems() async {
    final db = await _userDb.database;
    final results = await db.query('pilgrim_checklist', orderBy: 'created_at ASC');

    if (results.isEmpty) {
      final now = DateTime.now();
      for (int i = 0; i < defaultChecklistSeed.length; i++) {
        final seed = defaultChecklistSeed[i];
        final id = 'seed_$i';
        await db.insert('pilgrim_checklist', {
          'id': id,
          'title': seed['title']!,
          'category': seed['category']!,
          'is_checked': 0,
          'is_custom': 0,
          'created_at': now.add(Duration(milliseconds: i)).toIso8601String(),
        });
      }
      final reloaded = await db.query('pilgrim_checklist', orderBy: 'created_at ASC');
      return reloaded.map(PilgrimChecklistItem.fromMap).toList();
    }

    return results.map(PilgrimChecklistItem.fromMap).toList();
  }

  /// Toggles checked state of a checklist item.
  Future<void> toggleChecklistItem(String id, bool isChecked) async {
    final db = await _userDb.database;
    await db.update(
      'pilgrim_checklist',
      {'is_checked': isChecked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Adds a custom checklist item.
  Future<void> addChecklistItem(PilgrimChecklistItem item) async {
    final db = await _userDb.database;
    await db.insert(
      'pilgrim_checklist',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes a checklist item.
  Future<void> deleteChecklistItem(String id) async {
    final db = await _userDb.database;
    await db.delete(
      'pilgrim_checklist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Resets all items to unchecked.
  Future<void> resetChecklist() async {
    final db = await _userDb.database;
    await db.update('pilgrim_checklist', {'is_checked': 0});
  }
}
