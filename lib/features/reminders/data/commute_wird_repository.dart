import 'package:intl/intl.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';

class CommuteWirdState {
  final int currentPage;
  final int streak;
  final String? lastCompletedDate;

  CommuteWirdState({
    required this.currentPage,
    required this.streak,
    this.lastCompletedDate,
  });
}

class CommuteWirdRepository {
  final UserDatabase userDatabase;

  CommuteWirdRepository({UserDatabase? db})
      : userDatabase = db ?? UserDatabase.instance;

  Future<CommuteWirdState> getState() async {
    final db = await userDatabase.database;
    final rows = await db.query('commute_wird_state', where: 'id = ?', whereArgs: [1]);
    if (rows.isNotEmpty) {
      final r = rows.first;
      return CommuteWirdState(
        currentPage: (r['current_page'] as num).toInt(),
        streak: (r['streak'] as num).toInt(),
        lastCompletedDate: r['last_completed_date'] as String?,
      );
    }
    return CommuteWirdState(currentPage: 1, streak: 0);
  }

  Future<void> recordProgress({
    required int pagesRead,
    required int toPage,
    String slotId = 'commute',
    bool countTowardsMain = true,
  }) async {
    final db = await userDatabase.database;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    // 1. Calculate streak
    final currentState = await getState();
    int newStreak = currentState.streak;
    if (currentState.lastCompletedDate == null) {
      newStreak = 1;
    } else {
      final lastDate = DateTime.tryParse(currentState.lastCompletedDate!);
      if (lastDate != null) {
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
        if (diff == 1) {
          newStreak += 1;
        } else if (diff > 1) {
          newStreak = 1;
        }
      }
    }

    // 2. Update commute_wird_state
    await db.update(
      'commute_wird_state',
      {
        'current_page': toPage.clamp(1, 604),
        'streak': newStreak,
        'last_completed_date': todayStr,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    // 3. Insert into commute_wird_log
    await db.insert('commute_wird_log', {
      'date': todayStr,
      'slot_id': slotId,
      'pages_read': pagesRead,
      'completed': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 4. If countTowardsMain is enabled, record in main reading log
    if (countTowardsMain) {
      final userRepo = UserRepository(userDatabase: userDatabase);
      for (int i = 0; i < pagesRead; i++) {
        await userRepo.logPageRead(toPage);
      }
    }

    // 5. Notify Native Reminders Engine
    await NativeRemindersBridge.markCommuteCompleted(slotId: slotId, date: todayStr);
  }
}
