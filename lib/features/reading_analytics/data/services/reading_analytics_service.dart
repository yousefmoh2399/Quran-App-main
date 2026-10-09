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
  static const String _prefTotalMinutesKey = 'reading_analytics_total_minutes';
  static const String _prefSeededKey = 'reading_analytics_demo_seeded';

  /// Returns complete analytics summary report based strictly on real user data
  Future<ReadingAnalyticsSummary> getAnalyticsSummary({DateTime? referenceDate}) async {
    final now = referenceDate ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // Clean up any previously seeded fake demo data
    await _cleanSeededDemoDataIfNeeded(prefs);

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
    int calculatedMinutes = 0;
    int activeDays = 0;

    for (int i = 0; i < 112; i++) {
      final day = DateTime(startOfGrid.year, startOfGrid.month, startOfGrid.day).add(Duration(days: i));
      final dateKey = _formatDate(day);
      final pages = pagesByDate[dateKey] ?? 0;
      final minutes = (pages * 2.0).round(); // 2 mins per page of thoughtful reading

      final intensity = _calcIntensity(pages);
      final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

      if (pages > 0) {
        totalPages += pages;
        calculatedMinutes += minutes;
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

    // If explicit reading minutes were tracked in SharedPreferences, prioritize them if higher
    final storedMinutes = prefs.getInt(_prefTotalMinutesKey) ?? 0;
    final totalMinutes = storedMinutes > calculatedMinutes ? storedMinutes : calculatedMinutes;

    // 3. Compute Streak
    final streakData = _computeStreaks(pagesByDate, now);

    // 4. Compute Daily Average
    final double dailyAverage = activeDays > 0 ? (totalPages / activeDays) : 0.0;

    // 5. Khatma Progress (Exact percentage of 604 pages)
    final double khatmaProgress = totalPages > 0 ? ((totalPages % 604) / 604.0).clamp(0.0, 1.0) : 0.0;

    // 6. Current Week Progress & Goal
    final weeklyGoal = prefs.getInt(_prefWeeklyGoalKey) ?? 70; // 70 pages = 10 pages/day default
    final currentWeekPages = _computeCurrentWeekPages(pagesByDate, now);

    // 7. Peak Reading Hours Breakdown (Real distribution based on actual reading events)
    final peakHours = await _getPeakHoursDistribution(prefs, totalPages);
    ReadingPeakHourBucket? primaryPeak;
    final activePeaks = peakHours.where((p) => p.pagesRead > 0).toList();
    if (activePeaks.isNotEmpty) {
      primaryPeak = activePeaks.reduce((curr, next) => curr.pagesRead >= next.pagesRead ? curr : next);
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
    await recordReadingEvent(pagesRead: pagesRead, minutes: minutes, timestamp: time);
  }

  /// Records a reading event (updates peak hours distribution and minutes in preferences)
  Future<void> recordReadingEvent({
    required int pagesRead,
    int? minutes,
    DateTime? timestamp,
  }) async {
    final time = timestamp ?? DateTime.now();
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
    Map<String, int> counts = {
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'night': 0,
    };
    if (raw != null) {
      try {
        final decoded = Map<String, int>.from(jsonDecode(raw) as Map);
        counts.addAll(decoded);
      } catch (_) {}
    }
    counts[bucketId] = (counts[bucketId] ?? 0) + pagesRead;
    await prefs.setString(_prefPeakHoursKey, jsonEncode(counts));

    if (minutes != null && minutes > 0) {
      final currentTotal = prefs.getInt(_prefTotalMinutesKey) ?? 0;
      await prefs.setInt(_prefTotalMinutesKey, currentTotal + minutes);
    }
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
      'fajr': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'night': 0,
    };

    if (raw != null) {
      try {
        final loaded = Map<String, int>.from(jsonDecode(raw) as Map);
        counts.addAll(loaded);
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
        percentage: totalCount > 0 ? (counts['fajr'] ?? 0) / denom : 0.0,
      ),
      ReadingPeakHourBucket(
        id: 'dhuhr',
        titleAr: 'الضحى والظهيرة',
        timeRange: '٠٨:٠٠ ص - ٠٢:٠٠ م',
        icon: Icons.wb_sunny_rounded,
        pagesRead: counts['dhuhr'] ?? 0,
        percentage: totalCount > 0 ? (counts['dhuhr'] ?? 0) / denom : 0.0,
      ),
      ReadingPeakHourBucket(
        id: 'asr',
        titleAr: 'العصر والأصيل',
        timeRange: '٠٢:٠٠ م - ٠٦:٠٠ م',
        icon: Icons.wb_cloudy_rounded,
        pagesRead: counts['asr'] ?? 0,
        percentage: totalCount > 0 ? (counts['asr'] ?? 0) / denom : 0.0,
      ),
      ReadingPeakHourBucket(
        id: 'maghrib',
        titleAr: 'المغرب والعشاء',
        timeRange: '٠٦:٠٠ م - ١٠:٠٠ م',
        icon: Icons.nights_stay_rounded,
        pagesRead: counts['maghrib'] ?? 0,
        percentage: totalCount > 0 ? (counts['maghrib'] ?? 0) / denom : 0.0,
      ),
      ReadingPeakHourBucket(
        id: 'night',
        titleAr: 'جوف الليل والقيام',
        timeRange: '١٠:٠٠ م - ٠٤:٠٠ ص',
        icon: Icons.star_half_rounded,
        pagesRead: counts['night'] ?? 0,
        percentage: totalCount > 0 ? (counts['night'] ?? 0) / denom : 0.0,
      ),
    ];
  }

  /// Cleans up any fake demo data previously seeded by mistake
  Future<void> _cleanSeededDemoDataIfNeeded(SharedPreferences prefs) async {
    final seeded = prefs.getBool(_prefSeededKey) ?? false;
    if (seeded) {
      final raw = prefs.getString(_prefPeakHoursKey);
      if (raw != null && raw.contains('"fajr":148')) {
        await prefs.remove(_prefPeakHoursKey);
      }
      await prefs.setBool(_prefSeededKey, false);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
