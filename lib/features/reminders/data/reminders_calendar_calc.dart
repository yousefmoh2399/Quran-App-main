/// Pure Dart implementation of reminder scheduling & calendar calculations
/// mirroring native HijriCalendarHelper and UnifiedReminderScheduler for tests and client-side timeline logic.
class RemindersCalendarCalc {
  /// Returns the maximum days in a Gregorian month for a given year and month (1..12).
  static int getDaysInGregorianMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month];
  }

  /// Calculates the day of month for a given month/year based on dayType:
  /// - "day_of_month": clamped to actual month length (28/29/30/31)
  /// - "last_thursday": last Thursday of the month
  /// - "last_working_day": last working day (Sun-Thu: steps back from Friday/Saturday)
  static DateTime getGregorianTargetDate({
    required int year,
    required int month,
    required String dayType,
    required int targetDay,
    int hour = 10,
    int minute = 0,
  }) {
    final maxDay = getDaysInGregorianMonth(year, month);

    if (dayType == 'last_thursday') {
      DateTime dt = DateTime(year, month, maxDay, hour, minute);
      while (dt.weekday != DateTime.thursday) {
        dt = dt.subtract(const Duration(days: 1));
      }
      return dt;
    } else if (dayType == 'last_working_day') {
      // In Arab/Islamic work week (Sunday-Thursday): Friday (5) and Saturday (6) are weekend in DateTime (Monday=1, Sunday=7)
      DateTime dt = DateTime(year, month, maxDay, hour, minute);
      while (dt.weekday == DateTime.friday || dt.weekday == DateTime.saturday) {
        dt = dt.subtract(const Duration(days: 1));
      }
      return dt;
    } else {
      // "day_of_month": clamped
      final clampedDay = targetDay.clamp(1, maxDay);
      return DateTime(year, month, clampedDay, hour, minute);
    }
  }

  /// Calculates next monthly trigger timestamp strictly in the future.
  static DateTime getNextGregorianMonthlyTrigger({
    required String dayType,
    required int targetDay,
    required int hour,
    required int minute,
    required DateTime now,
  }) {
    // 1. Try current month
    final currentMonthTarget = getGregorianTargetDate(
      year: now.year,
      month: now.month,
      dayType: dayType,
      targetDay: targetDay,
      hour: hour,
      minute: minute,
    );

    if (currentMonthTarget.isAfter(now)) {
      return currentMonthTarget;
    }

    // 2. Advance to next month
    int nextMonth = now.month + 1;
    int nextYear = now.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }

    return getGregorianTargetDate(
      year: nextYear,
      month: nextMonth,
      dayType: dayType,
      targetDay: targetDay,
      hour: hour,
      minute: minute,
    );
  }

  /// Estimates Hijri month length (alternating 30 and 29 days).
  static int getDaysInHijriMonth(int hijriMonth) {
    // Odd months usually 30 days, even months 29 days (12th month 30 in leap year)
    return (hijriMonth % 2 != 0) ? 30 : 29;
  }

  /// Clamps target day for Hijri calendar.
  static int clampHijriDay(int targetDay, int hijriMonth) {
    final max = getDaysInHijriMonth(hijriMonth);
    return targetDay.clamp(1, max);
  }

  /// Checks cancellation condition for Daily Wird.
  static bool shouldCancelDailyWird({
    required String? lastCompletedDate,
    required String todayDate,
  }) {
    return lastCompletedDate == todayDate;
  }

  /// Checks cancellation condition for Commute slot.
  static bool shouldCancelCommuteWird({
    required bool isSlotCompletedToday,
  }) {
    return isSlotCompletedToday;
  }

  /// Checks cancellation condition for Monthly Sadaqah.
  static bool shouldCancelMonthlySadaqah({
    required bool isDonatedInCurrentCycle,
  }) {
    return isDonatedInCurrentCycle;
  }

  /// Checks cancellation condition for Azkar quiet window around prayer times.
  static bool isNearPrayerQuietWindow({
    required DateTime currentDateTime,
    required List<DateTime> prayerTimes,
    int toleranceMinutes = 10,
  }) {
    final toleranceMillis = toleranceMinutes * 60 * 1000;
    final currentMillis = currentDateTime.millisecondsSinceEpoch;

    for (final pt in prayerTimes) {
      final diff = (currentMillis - pt.millisecondsSinceEpoch).abs();
      if (diff <= toleranceMillis) {
        return true;
      }
    }
    return false;
  }
}
