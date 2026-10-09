import 'dart:convert';
import 'package:sqflite/sqflite.dart';
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

  // ==========================================
  // OFFLINE QR CODE SYNC SYSTEM
  // ==========================================

  static const String qrCirclePrefix = 'taqarrab:circle:';
  static const String qrProgressPrefix = 'taqarrab:progress:';

  /// Generates a compact offline QR string for the entire Khatma Circle.
  String generateCircleQrPayload(KhatmaCircle circle) {
    final map = {
      'v': 1,
      'id': circle.id,
      't': circle.title,
      'd': circle.description,
      'td': circle.targetDate,
      'ca': circle.createdAt.toIso8601String(),
      'ic': circle.isCompleted ? 1 : 0,
      'j': circle.juzList.map((j) {
        String stCode = 'a';
        if (j.isCompleted) {
          stCode = 'c';
        } else if (j.isInProgress) {
          stCode = 'p';
        }
        return [j.juzNumber, j.assignedTo, stCode];
      }).toList(),
    };
    return '$qrCirclePrefix${jsonEncode(map)}';
  }

  /// Parses a compact offline QR string into a KhatmaCircle model.
  KhatmaCircle? parseCircleQrPayload(String raw) {
    try {
      String jsonStr = raw.trim();
      if (jsonStr.startsWith(qrCirclePrefix)) {
        jsonStr = jsonStr.substring(qrCirclePrefix.length);
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final id = map['id'] as String;
      final title = (map['t'] as String? ?? 'ختمة العائلة').trim();
      final desc = (map['d'] as String? ?? '').trim();
      final td = map['td'] as String?;
      final ca = DateTime.tryParse(map['ca'] as String? ?? '') ?? DateTime.now();
      final ic = (map['ic'] as int? ?? 0) == 1;

      final rawJ = map['j'] as List<dynamic>? ?? [];
      final List<KhatmaCircleJuz> juzList = [];

      for (int i = 1; i <= 30; i++) {
        String assigned = '';
        String status = 'available';

        if (i - 1 < rawJ.length) {
          final item = rawJ[i - 1] as List<dynamic>;
          if (item.length >= 3) {
            assigned = item[1]?.toString() ?? '';
            final stCode = item[2]?.toString() ?? 'a';
            if (stCode == 'c') {
              status = 'completed';
            } else if (stCode == 'p') {
              status = 'in_progress';
            } else {
              status = 'available';
            }
          }
        }

        juzList.add(KhatmaCircleJuz(
          circleId: id,
          juzNumber: i,
          assignedTo: assigned,
          status: status,
        ));
      }

      return KhatmaCircle(
        id: id,
        title: title,
        description: desc,
        targetDate: td,
        createdAt: ca,
        isCompleted: ic,
        juzList: juzList,
      );
    } catch (_) {
      return null;
    }
  }

  /// Imports or updates a full Khatma Circle from a scanned QR code into the local database.
  Future<KhatmaCircle> importOrUpdateCircle(KhatmaCircle circle) async {
    final db = await _userDb.database;
    final existing = await getCircleById(circle.id);

    await db.transaction((txn) async {
      if (existing == null) {
        await txn.insert('khatma_circles', circle.toMap());
        for (final j in circle.juzList) {
          await txn.insert('khatma_circle_juz', j.toMap());
        }
      } else {
        await txn.update(
          'khatma_circles',
          {
            'title': circle.title,
            'description': circle.description,
            'target_date': circle.targetDate,
            'is_completed': circle.isCompleted ? 1 : 0,
            'completed_at': circle.completedAt?.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [circle.id],
        );
        for (final j in circle.juzList) {
          await txn.insert(
            'khatma_circle_juz',
            j.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    await _checkAndSyncCircleCompletion(circle.id);
    return (await getCircleById(circle.id)) ?? circle;
  }

  /// Generates a lightweight QR string for a member's daily reading progress.
  String generateMemberProgressQrPayload({
    required String circleId,
    required String memberName,
    required List<int> juzNumbers,
    required String status,
  }) {
    final map = {
      'v': 1,
      'cid': circleId,
      'm': memberName.trim(),
      'j': juzNumbers,
      's': status == 'completed' ? 'c' : 'p',
      'ts': DateTime.now().toIso8601String(),
    };
    return '$qrProgressPrefix${jsonEncode(map)}';
  }

  /// Parses a member's daily reading progress QR string.
  Map<String, dynamic>? parseMemberProgressQrPayload(String raw) {
    try {
      String jsonStr = raw.trim();
      if (jsonStr.startsWith(qrProgressPrefix)) {
        jsonStr = jsonStr.substring(qrProgressPrefix.length);
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (!map.containsKey('cid') || !map.containsKey('m') || !map.containsKey('j')) {
        return null;
      }
      final circleId = map['cid'] as String;
      final memberName = map['m'] as String;
      final rawJ = map['j'] as List<dynamic>;
      final juzNumbers = rawJ.map((e) => (e as num).toInt()).toList();
      final stCode = map['s'] as String? ?? 'c';
      final status = stCode == 'c' ? 'completed' : 'in_progress';

      return {
        'circleId': circleId,
        'memberName': memberName,
        'juzNumbers': juzNumbers,
        'status': status,
        'timestamp': map['ts'] as String?,
      };
    } catch (_) {
      return null;
    }
  }

  /// Applies scanned member reading progress to the local database circle.
  Future<bool> applyMemberProgress({
    required String circleId,
    required String memberName,
    required List<int> juzNumbers,
    required String status,
  }) async {
    final db = await _userDb.database;
    final circle = await getCircleById(circleId);
    if (circle == null) return false;

    final now = DateTime.now().toIso8601String();
    final completedAt = status == 'completed' ? now : null;

    for (final jNum in juzNumbers) {
      await db.update(
        'khatma_circle_juz',
        {
          'assigned_to': memberName.trim(),
          'status': status,
          'completed_at': completedAt,
        },
        where: 'circle_id = ? AND juz_number = ?',
        whereArgs: [circleId, jNum],
      );
    }

    await _checkAndSyncCircleCompletion(circleId);
    return true;
  }
}
