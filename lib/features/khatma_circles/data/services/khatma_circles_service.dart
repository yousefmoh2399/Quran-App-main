import 'dart:convert';
import 'package:quran_app_android/core/data/user_database.dart';
import '../models/khatma_circle_model.dart';

class KhatmaCirclesService {
  final UserDatabase _userDb;
  static final KhatmaCirclesService instance = KhatmaCirclesService();

  KhatmaCirclesService({UserDatabase? userDb})
      : _userDb = userDb ?? UserDatabase.instance;

  static const List<String> juzSurahNames = [
    'الجزء الأول (الفاتحة - البقرة 141)',
    'الجزء الثاني (البقرة 142 - 252)',
    'الجزء الثالث (البقرة 253 - آل عمران 92)',
    'الجزء الرابع (آل عمران 93 - النساء 23)',
    'الجزء الخامس (النساء 24 - النساء 147)',
    'الجزء السادس (النساء 148 - المائدة 81)',
    'الجزء السابع (المائدة 82 - الأنعام 110)',
    'الجزء الثامن (الأنعام 111 - الأعراف 87)',
    'الجزء التاسع (الأعراف 88 - الأنفال 40)',
    'الجزء العاشر (الأنفال 41 - التوبة 92)',
    'الجزء الحادي عشر (التوبة 93 - هود 5)',
    'الجزء الثاني عشر (هود 6 - يوسف 52)',
    'الجزء الثالث عشر (يوسف 53 - إبراهيم 52)',
    'الجزء الرابع عشر (الحجر 1 - النحل 128)',
    'الجزء الخامس عشر (الإسراء 1 - الكهف 74)',
    'الجزء السادس عشر (الكهف 75 - طه 135)',
    'الجزء السابع عشر (الأنبياء 1 - الحج 78)',
    'الجزء الثامن عشر (المؤمنون 1 - الفرقان 20)',
    'الجزء التاسع عشر (الفرقان 21 - النمل 55)',
    'الجزء العشرون (النمل 56 - العنكبوت 45)',
    'الجزء الحادي والعشرون (العنكبوت 46 - الأحزاب 30)',
    'الجزء الثاني والعشرون (الأحزاب 31 - يس 27)',
    'الجزء الثالث والعشرون (يس 28 - الزمر 31)',
    'الجزء الرابع والعشرون (الزمر 32 - فصلت 46)',
    'الجزء الخامس والعشرون (فصلت 47 - الجاثية 37)',
    'الجزء السادس والعشرون (الأحقاف 1 - الذاريات 30)',
    'الجزء السابع والعشرون (الذاريات 31 - الحديد 29)',
    'الجزء الثامن والعشرون (المجادلة 1 - التحريم 12)',
    'الجزء التاسع والعشرون (الملك 1 - المرسلات 50)',
    'الجزء الثلاثون (النبأ 1 - الناس 6)',
  ];

  static String getJuzTitle(int juzNumber) {
    if (juzNumber >= 1 && juzNumber <= juzSurahNames.length) {
      return juzSurahNames[juzNumber - 1];
    }
    return 'الجزء $juzNumber';
  }

  /// Fetches all Khatma Circles with their 30 Juz assignments.
  Future<List<KhatmaCircle>> getCircles() async {
    final db = await _userDb.database;
    final circlesData = await db.query(
      'khatma_circles',
      orderBy: 'created_at DESC',
    );

    final List<KhatmaCircle> circles = [];
    for (final cMap in circlesData) {
      final circleId = cMap['id'] as String;
      final juzData = await db.query(
        'khatma_circle_juz',
        where: 'circle_id = ?',
        whereArgs: [circleId],
        orderBy: 'juz_number ASC',
      );
      final juzList = juzData.map(KhatmaCircleJuz.fromMap).toList();
      circles.add(KhatmaCircle.fromMap(cMap, juzList));
    }
    return circles;
  }

  /// Creates a new Khatma Circle and prepopulates all 30 Juz records.
  Future<KhatmaCircle> createCircle({
    required String title,
    String description = '',
    String? targetDate,
  }) async {
    final db = await _userDb.database;
    final id = 'circle_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final circle = KhatmaCircle(
      id: id,
      title: title.trim(),
      description: description.trim(),
      targetDate: targetDate,
      createdAt: now,
      isCompleted: false,
    );

    await db.transaction((txn) async {
      await txn.insert('khatma_circles', circle.toMap());
      for (int j = 1; j <= 30; j++) {
        await txn.insert('khatma_circle_juz', {
          'circle_id': id,
          'juz_number': j,
          'assigned_to': '',
          'status': 'available',
          'completed_at': null,
        });
      }
    });

    final created = await getCircleById(id);
    return created ?? circle;
  }

  /// Fetches a single Khatma Circle by its ID.
  Future<KhatmaCircle?> getCircleById(String id) async {
    final db = await _userDb.database;
    final circles = await db.query(
      'khatma_circles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (circles.isEmpty) return null;

    final juzData = await db.query(
      'khatma_circle_juz',
      where: 'circle_id = ?',
      whereArgs: [id],
      orderBy: 'juz_number ASC',
    );
    final juzList = juzData.map(KhatmaCircleJuz.fromMap).toList();
    return KhatmaCircle.fromMap(circles.first, juzList);
  }

  /// Updates person assignment and status for a specific Juz.
  Future<void> updateJuzAssignment(
    String circleId,
    int juzNumber, {
    required String assignedTo,
    required String status,
  }) async {
    final db = await _userDb.database;
    final now = DateTime.now();
    final completedAt = status == 'completed' ? now.toIso8601String() : null;

    await db.update(
      'khatma_circle_juz',
      {
        'assigned_to': assignedTo.trim(),
        'status': status,
        'completed_at': completedAt,
      },
      where: 'circle_id = ? AND juz_number = ?',
      whereArgs: [circleId, juzNumber],
    );

    await _checkAndSyncCircleCompletion(circleId);
  }

  /// Toggles completion of a Juz directly.
  Future<void> toggleJuzCompleted(
    String circleId,
    int juzNumber,
    bool isCompleted,
  ) async {
    final db = await _userDb.database;
    final status = isCompleted ? 'completed' : 'in_progress';
    final completedAt = isCompleted ? DateTime.now().toIso8601String() : null;

    await db.update(
      'khatma_circle_juz',
      {
        'status': status,
        'completed_at': completedAt,
      },
      where: 'circle_id = ? AND juz_number = ?',
      whereArgs: [circleId, juzNumber],
    );

    await _checkAndSyncCircleCompletion(circleId);
  }

  /// Deletes a Khatma Circle and its 30 Juz records.
  Future<void> deleteCircle(String circleId) async {
    final db = await _userDb.database;
    await db.transaction((txn) async {
      await txn.delete(
        'khatma_circle_juz',
        where: 'circle_id = ?',
        whereArgs: [circleId],
      );
      await txn.delete(
        'khatma_circles',
        where: 'id = ?',
        whereArgs: [circleId],
      );
    });
  }

  /// Checks if all 30 Juz are completed and updates the circle state.
  Future<void> _checkAndSyncCircleCompletion(String circleId) async {
    final db = await _userDb.database;
    final uncompleted = await db.query(
      'khatma_circle_juz',
      where: 'circle_id = ? AND status != ?',
      whereArgs: [circleId, 'completed'],
    );

    final isAllDone = uncompleted.isEmpty;
    await db.update(
      'khatma_circles',
      {
        'is_completed': isAllDone ? 1 : 0,
        'completed_at': isAllDone ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [circleId],
    );
  }

  /// Generates a rich formatted WhatsApp sharing text for family/friends.
  String generateWhatsAppShareText(KhatmaCircle circle) {
    final buffer = StringBuffer();
    buffer.writeln('🌙 *ختمة القرآن الجماعية: ${circle.title}*');
    if (circle.description.isNotEmpty) {
      buffer.writeln('🕊️ _${circle.description}_');
    }
    buffer.writeln();

    final percent = (circle.progressPercentage * 100).toInt();
    buffer.writeln('📊 *نسبة الإنجاز:* ${circle.completedJuzCount}/30 جزء ($percent%)');
    buffer.writeln();

    // Available
    final available = circle.juzList.where((j) => j.isAvailable).toList();
    if (available.isNotEmpty) {
      buffer.writeln('▫️ *الأجزاء المتاحة للحجز والاشتراك:*');
      for (final j in available) {
        buffer.writeln('   • الجزء ${j.juzNumber}: ${getJuzTitle(j.juzNumber)}');
      }
      buffer.writeln();
    }

    // In Progress
    final inProgress = circle.juzList.where((j) => j.isInProgress).toList();
    if (inProgress.isNotEmpty) {
      buffer.writeln('📖 *الأجزاء قيد القراءة:*');
      for (final j in inProgress) {
        final who = j.assignedTo.isNotEmpty ? ' (${j.assignedTo})' : '';
        buffer.writeln('   • الجزء ${j.juzNumber}$who');
      }
      buffer.writeln();
    }

    // Completed
    final completed = circle.juzList.where((j) => j.isCompleted).toList();
    if (completed.isNotEmpty) {
      buffer.writeln('✅ *الأجزاء التي تم إتمامها:*');
      for (final j in completed) {
        final who = j.assignedTo.isNotEmpty ? ' (${j.assignedTo})' : '';
        buffer.writeln('   • الجزء ${j.juzNumber}$who');
      }
      buffer.writeln();
    }

    buffer.writeln('✨ _تقبل الله منا ومنكم صالح الأعمال_');
    buffer.writeln('📱 تطبيق تقرب - رفيقك القرآني');
    return buffer.toString();
  }

  /// Exports circle as clean offline JSON string.
  String exportCircleToJson(KhatmaCircle circle) {
    final map = circle.toMap();
    map['juzList'] = circle.juzList.map((j) => j.toMap()).toList();
    return jsonEncode(map);
  }

  /// Imports circle from offline JSON string into database.
  Future<KhatmaCircle> importCircleFromJson(String jsonString) async {
    final db = await _userDb.database;
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final newId = 'circle_imported_${DateTime.now().millisecondsSinceEpoch}';

    final circle = KhatmaCircle(
      id: newId,
      title: (map['title'] as String? ?? 'ختمة مستوردة').trim(),
      description: (map['description'] as String? ?? '').trim(),
      targetDate: map['target_date'] as String?,
      createdAt: DateTime.now(),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
    );

    final rawJuz = (map['juzList'] as List<dynamic>? ?? []);

    await db.transaction((txn) async {
      await txn.insert('khatma_circles', circle.toMap());
      if (rawJuz.isNotEmpty) {
        for (final item in rawJuz) {
          final jMap = Map<String, dynamic>.from(item as Map);
          jMap['circle_id'] = newId;
          await txn.insert('khatma_circle_juz', jMap);
        }
      } else {
        for (int j = 1; j <= 30; j++) {
          await txn.insert('khatma_circle_juz', {
            'circle_id': newId,
            'juz_number': j,
            'assigned_to': '',
            'status': 'available',
            'completed_at': null,
          });
        }
      }
    });

    return (await getCircleById(newId)) ?? circle;
  }
}
