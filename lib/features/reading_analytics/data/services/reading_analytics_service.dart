import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/data/repositories/user_repository.dart';
import '../models/reading_analytics_models.dart';

class ReadingAnalyticsService {
  static ReadingAnalyticsService? _instance;
  static ReadingAnalyticsService get instance =>
      _instance ??= ReadingAnalyticsService();

  final UserRepository _userRepository;

  ReadingAnalyticsService({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  static const String _prefPeakHoursKey = 'reading_analytics_peak_hours';
  static const String _prefWeeklyGoalKey = 'reading_analytics_weekly_goal';
  static const String _prefSeededKey = 'reading_analytics_demo_seeded';

  /// Returns complete analytics summary report
  Future<ReadingAnalyticsSummary> getAnalyticsSummary({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // Ensure demo seed if brand new install with 0 records
    await _ensureInitialSeedingIfNeeded(prefs);

    // 1. Fetch reading logs from local user repository
    final rawLogs = await _userRepository.getReadingLog(limit: 120);
    final Map<String, int> pagesByDate = {};
    for (final l in rawLogs) {
      pagesByDate[l.date] = (pagesByDate[l.date] ?? 0) + l.pagesRead;
    }

    // 2. Build 16 weeks (112 days) heatmap grid ending at today
    final List<ReadingHeatmapDay> heatmapDays = [];
    final startOfGrid = now.subtract(const Duration(days: 111)); // 112 days total

    int totalPages = 0;
    int totalMinutes = 0;
    int activeDays = 0;

    for (int i = 0; i < 112; i++) {
      final day = DateTime(startOfGrid.year, startOfGrid.month, startOfGrid.day).add(Duration(days: i));
      final dateKey = _formatDate(day);
      final pages = pagesByDate[dateKey] ?? 0;
      final minutes = (pages * 2.2).round(); // approx 2.2 mins per page of thoughtful reading

      final intensity = _calcIntensity(pages);
      final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

      if (pages > 0) {
        totalPages += pages;
        totalMinutes += minutes;
        activeDays++;
      }

      heatmapDays.add(
        ReadingHeatmapDay(
          date: day,
          pagesRead: pages,
          minutesSpent: minutes,
          intensity: intensity,
          isToday: isToday,
        ),
      );
    }

    // 3. Compute Streak
    final streakData = _computeStreaks(pagesByDate, now);

    // 4. Compute Daily Average
    final double dailyAverage = activeDays > 0 ? (totalPages / activeDays) : 0.0;

    // 5. Khatma Progress
    final double khatmaProgress = ((totalPages % 604) / 604.0).clamp(0.0, 1.0);

    // 6. Current Week Progress & Goal
    final weeklyGoal = prefs.getInt(_prefWeeklyGoalKey) ?? 70; // 70 pages = 10 pages/day default
    final currentWeekPages = _computeCurrentWeekPages(pagesByDate, now);

    // 7. Peak Reading Hours Breakdown
    final peakHours = await _getPeakHoursDistribution(prefs, totalPages);
    ReadingPeakHourBucket? primaryPeak;
    if (peakHours.isNotEmpty) {
      primaryPeak = peakHours.reduce((curr, next) => curr.pagesRead >= next.pagesRead ? curr : next);
    }

    return ReadingAnalyticsSummary(
      totalPagesRead: totalPages,
      totalReadingMinutes: totalMinutes,
      dailyAveragePages: double.parse(dailyAverage.toStringAsFixed(1)),
      khatmaProgress: khatmaProgress,
      weeklyGoalPages: weeklyGoal,
      currentWeekPages: currentWeekPages,
      streak: streakData,
      peakHours: peakHours,
      primaryPeak: primaryPeak,
      heatmapDays: heatmapDays,
    );
  }

  /// Records a reading session with timestamp and pages read
  Future<void> recordReadingSession({
    required int pagesRead,
    int? minutes,
    DateTime? timestamp,
  }) async {
    final time = timestamp ?? DateTime.now();
    await _userRepository.logDayReading(pagesRead, lastPage: pagesRead, date: time);

    // Update Peak hour counter in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final hour = time.hour;
    String bucketId;
    if (hour >= 4 && hour < 8) {
      bucketId = 'fajr';
    } else if (hour >= 8 && hour < 14) {
      bucketId = 'dhuhr';
    } else if (hour >= 14 && hour < 18) {
      bucketId = 'asr';
    } else if (hour >= 18 && hour < 22) {
      bucketId = 'maghrib';
    } else {
      bucketId = 'night';
    }

    final raw = prefs.getString(_prefPeakHoursKey);
    Map<String, int> counts = {};
    if (raw != null) {
      try {
        counts = Map<String, int>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    counts[bucketId] = (counts[bucketId] ?? 0) + pagesRead;
    await prefs.setString(_prefPeakHoursKey, jsonEncode(counts));
  }

  /// Sets user weekly goal in pages
  Future<void> setWeeklyGoal(int pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefWeeklyGoalKey, pages);
  }

  int _calcIntensity(int pages) {
    if (pages <= 0) return 0;
    if (pages <= 3) return 1;
    if (pages <= 9) return 2;
    if (pages <= 19) return 3;
    return 4;
  }

  ReadingStreakData _computeStreaks(Map<String, int> pagesByDate, DateTime now) {
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    DateTime checkDate = DateTime(now.year, now.month, now.day);
    final todayStr = _formatDate(checkDate);
    final yesterdayStr = _formatDate(checkDate.subtract(const Duration(days: 1)));

    // Current streak evaluation
    if ((pagesByDate[todayStr] ?? 0) > 0) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else if ((pagesByDate[yesterdayStr] ?? 0) > 0) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while ((pagesByDate[_formatDate(checkDate)] ?? 0) > 0) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Longest streak over the recorded period
    final sortedDates = pagesByDate.keys.toList()..sort();
    DateTime? prevDate;
    for (final dStr in sortedDates) {
      if ((pagesByDate[dStr] ?? 0) > 0) {
        final d = DateTime.tryParse(dStr);
        if (d != null) {
          if (prevDate != null && d.difference(prevDate).inDays == 1) {
            tempStreak++;
          } else {
            tempStreak = 1;
          }
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
          prevDate = d;
        }
      }
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    final activeDays = pagesByDate.values.where((p) => p > 0).length;

    return ReadingStreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak > 0 ? longestStreak : currentStreak,
      totalActiveDays: activeDays,
      lastActiveDate: now,
    );
  }

  int _computeCurrentWeekPages(Map<String, int> pagesByDate, DateTime now) {
    int sum = 0;
    // Current week: past 7 days up to today
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      sum += pagesByDate[_formatDate(d)] ?? 0;
    }
    return sum;
  }

  Future<List<ReadingPeakHourBucket>> _getPeakHoursDistribution(
    SharedPreferences prefs,
    int totalPages,
  ) async {
    final raw = prefs.getString(_prefPeakHoursKey);
    Map<String, int> counts = {
      'fajr': 42,
      'dhuhr': 18,
      'asr': 24,
      'maghrib': 35,
      'night': 28,
    };

    if (raw != null) {
      try {
        final loaded = Map<String, int>.from(jsonDecode(raw) as Map);
        if (loaded.isNotEmpty) counts = loaded;
      } catch (_) {}
    }

    final totalCount = counts.values.fold<int>(0, (a, b) => a + b);
    final denom = totalCount > 0 ? totalCount : 1;

    return [
      ReadingPeakHourBucket(
        id: 'fajr',
        titleAr: 'الفجر وبكور اليوم',
        timeRange: '٠٤:٠٠ - ٠٨:٠٠ ص',
        icon: Icons.wb_twilight_rounded,
        pagesRead: counts['fajr'] ?? 0,
        percentage: (counts['fajr'] ?? 0) / denom,
      ),
      ReadingPeakHourBucket(
        id: 'dhuhr',
        titleAr: 'الضحى والظهيرة',
        timeRange: '٠٨:٠٠ ص - ٠٢:٠٠ م',
        icon: Icons.wb_sunny_rounded,
        pagesRead: counts['dhuhr'] ?? 0,
        percentage: (counts['dhuhr'] ?? 0) / denom,
      ),
      ReadingPeakHourBucket(
        id: 'asr',
        titleAr: 'العصر والأصيل',
        timeRange: '٠٢:٠٠ م - ٠٦:٠٠ م',
        icon: Icons.wb_cloudy_rounded,
        pagesRead: counts['asr'] ?? 0,
        percentage: (counts['asr'] ?? 0) / denom,
      ),
      ReadingPeakHourBucket(
        id: 'maghrib',
        titleAr: 'المغرب والعشاء',
        timeRange: '٠٦:٠٠ م - ١٠:٠٠ م',
        icon: Icons.nights_stay_rounded,
        pagesRead: counts['maghrib'] ?? 0,
        percentage: (counts['maghrib'] ?? 0) / denom,
      ),
      ReadingPeakHourBucket(
        id: 'night',
        titleAr: 'جوف الليل والقيام',
        timeRange: '١٠:٠٠ م - ٠٤:٠٠ ص',
        icon: Icons.star_half_rounded,
        pagesRead: counts['night'] ?? 0,
        percentage: (counts['night'] ?? 0) / denom,
      ),
    ];
  }

  Future<void> _ensureInitialSeedingIfNeeded(SharedPreferences prefs) async {
    final seeded = prefs.getBool(_prefSeededKey) ?? false;
    if (seeded) return;

    final existing = await _userRepository.getReadingLog(limit: 5);
    if (existing.isEmpty) {
      // Seed inspiring reading pattern over the last 30 days
      final now = DateTime.now();
      final demoPattern = [
        12, 10, 15, 8, 20, 14, 10, 0, 8, 12, 16, 10, 14, 20, 18, 12, 10, 0, 10, 14, 16, 20, 12, 14, 10, 18, 16, 12, 14, 10,
      ];

      for (int i = 0; i < demoPattern.length; i++) {
        final pages = demoPattern[i];
        if (pages > 0) {
          final d = now.subtract(Duration(days: demoPattern.length - 1 - i));
          await _userRepository.logDayReading(pages, lastPage: pages, date: d);
        }
      }

      await prefs.setString(
        _prefPeakHoursKey,
        jsonEncode({
          'fajr': 148,
          'dhuhr': 42,
          'asr': 65,
          'maghrib': 98,
          'night': 74,
        }),
      );
    }
    await prefs.setBool(_prefSeededKey, true);
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
