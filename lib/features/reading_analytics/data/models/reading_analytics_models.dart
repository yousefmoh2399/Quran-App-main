import 'package:flutter/material.dart';

/// Represents a single day in the reading heatmap grid
class ReadingHeatmapDay {
  final DateTime date;
  final int pagesRead;
  final int minutesSpent;
  final int intensity; // 0 (none) to 4 (high)
  final bool isToday;

  const ReadingHeatmapDay({
    required this.date,
    required this.pagesRead,
    this.minutesSpent = 0,
    required this.intensity,
    required this.isToday,
  });

  String get dateString =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Represents a breakdown period for peak reading hours
class ReadingPeakHourBucket {
  final String id;
  final String titleAr;
  final String timeRange;
  final IconData icon;
  final int pagesRead;
  final double percentage;

  const ReadingPeakHourBucket({
    required this.id,
    required this.titleAr,
    required this.timeRange,
    required this.icon,
    required this.pagesRead,
    required this.percentage,
  });
}

/// Streak and continuity statistics
class ReadingStreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalActiveDays;
  final DateTime? lastActiveDate;

  const ReadingStreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalActiveDays,
    this.lastActiveDate,
  });
}

/// Aggregated reading analytics summary report
class ReadingAnalyticsSummary {
  final int totalPagesRead;
  final int totalReadingMinutes;
  final double dailyAveragePages;
  final double khatmaProgress; // 0.0 to 1.0 (based on 604 pages)
  final int weeklyGoalPages;
  final int currentWeekPages;
  final ReadingStreakData streak;
  final List<ReadingPeakHourBucket> peakHours;
  final ReadingPeakHourBucket? primaryPeak;
  final List<ReadingHeatmapDay> heatmapDays;

  const ReadingAnalyticsSummary({
    required this.totalPagesRead,
    required this.totalReadingMinutes,
    required this.dailyAveragePages,
    required this.khatmaProgress,
    required this.weeklyGoalPages,
    required this.currentWeekPages,
    required this.streak,
    required this.peakHours,
    this.primaryPeak,
    required this.heatmapDays,
  });
}
