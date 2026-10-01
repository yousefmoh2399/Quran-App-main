import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/features/reminders/data/reminders_calendar_calc.dart';

void main() {
  group('Reminders Engine - Day of Month Clamping (28/29/30/31)', () {
    test('Clamps day 31 to 28 in February non-leap year (e.g. 2026)', () {
      final target = RemindersCalendarCalc.getGregorianTargetDate(
        year: 2026,
        month: 2,
        dayType: 'day_of_month',
        targetDay: 31,
      );
      expect(target.year, 2026);
      expect(target.month, 2);
      expect(target.day, 28);
    });

    test('Clamps day 31 to 29 in February leap year (e.g. 2028)', () {
      final target = RemindersCalendarCalc.getGregorianTargetDate(
        year: 2028,
        month: 2,
        dayType: 'day_of_month',
        targetDay: 31,
      );
      expect(target.year, 2028);
      expect(target.month, 2);
      expect(target.day, 29);
    });

    test('Clamps day 31 to 30 in 30-day months (April, June, Sept, Nov)', () {
      for (final m in [4, 6, 9, 11]) {
        final target = RemindersCalendarCalc.getGregorianTargetDate(
          year: 2026,
          month: m,
          dayType: 'day_of_month',
          targetDay: 31,
        );
        expect(target.month, m);
        expect(target.day, 30, reason: 'Month $m should clamp day 31 to 30');
      }
    });

    test('Preserves day 31 in 31-day months (Jan, March, May, July, Aug, Oct, Dec)', () {
      for (final m in [1, 3, 5, 7, 8, 10, 12]) {
        final target = RemindersCalendarCalc.getGregorianTargetDate(
          year: 2026,
          month: m,
          dayType: 'day_of_month',
          targetDay: 31,
        );
        expect(target.month, m);
        expect(target.day, 31, reason: 'Month $m should allow day 31');
      }
    });
  });

  group('Reminders Engine - Last Working Day & Last Thursday', () {
    test('Last working day steps back to Thursday when month ends on Friday (July 2026)', () {
      // In July 2026: July 31 is Friday (DateTime.friday == 5)
      // Arab working week (Sun-Thu): last working day should be Thursday July 30
      final target = RemindersCalendarCalc.getGregorianTargetDate(
        year: 2026,
        month: 7,
        dayType: 'last_working_day',
        targetDay: 1,
      );
      expect(target.month, 7);
      expect(target.day, 30);
      expect(target.weekday, DateTime.thursday);
    });

    test('Last working day steps back to Thursday when month ends on Saturday (October 2026)', () {
      // In October 2026: October 31 is Saturday (DateTime.saturday == 6)
      // Arab working week (Sun-Thu): last working day should be Thursday Oct 29
      final target = RemindersCalendarCalc.getGregorianTargetDate(
        year: 2026,
        month: 10,
        dayType: 'last_working_day',
        targetDay: 1,
      );
      expect(target.month, 10);
      expect(target.day, 29);
      expect(target.weekday, DateTime.thursday);
    });

    test('Last working day remains the last day when it falls on weekday (Sept 2026)', () {
      // Sept 30, 2026 is Wednesday
      final target = RemindersCalendarCalc.getGregorianTargetDate(
        year: 2026,
        month: 9,
        dayType: 'last_working_day',
        targetDay: 1,
      );
      expect(target.month, 9);
      expect(target.day, 30);
      expect(target.weekday, DateTime.wednesday);
    });

    test('Last Thursday finds the accurate Thursday in any month', () {
      // In September 2026, Sept 30 is Wednesday -> Last Thursday is Sept 24
      final target = RemindersCalendarCalc.getGregorianTargetDate(
        year: 2026,
        month: 9,
        dayType: 'last_thursday',
        targetDay: 1,
      );
      expect(target.month, 9);
      expect(target.day, 24);
      expect(target.weekday, DateTime.thursday);
    });
  });

  group('Reminders Engine - Hijri Calendar Logic', () {
    test('Clamps day 30 to 29 in even (29-day) Hijri months', () {
      final clampedDay = RemindersCalendarCalc.clampHijriDay(30, 2); // Safar (month 2)
      expect(clampedDay, 29);
    });

    test('Preserves day 30 in odd (30-day) Hijri months', () {
      final clampedDay = RemindersCalendarCalc.clampHijriDay(30, 1); // Muharram (month 1)
      expect(clampedDay, 30);
    });
  });

  group('Reminders Engine - Rescheduling Across Months & Days', () {
    test('Advances to next month if target date in current month has already passed', () {
      // Now is Sept 26, 2026, target was Sept 20, 2026 at 10:00
      final now = DateTime(2026, 9, 26, 12, 0);
      final nextTrigger = RemindersCalendarCalc.getNextGregorianMonthlyTrigger(
        dayType: 'day_of_month',
        targetDay: 20,
        hour: 10,
        minute: 0,
        now: now,
      );

      expect(nextTrigger.isAfter(now), isTrue);
      expect(nextTrigger.year, 2026);
      expect(nextTrigger.month, 10);
      expect(nextTrigger.day, 20);
      expect(nextTrigger.hour, 10);
      expect(nextTrigger.minute, 0);
    });

    test('Stays in current month if target date is in the future', () {
      // Now is Sept 10, 2026, target is Sept 25, 2026 at 10:00
      final now = DateTime(2026, 9, 10, 8, 0);
      final nextTrigger = RemindersCalendarCalc.getNextGregorianMonthlyTrigger(
        dayType: 'day_of_month',
        targetDay: 25,
        hour: 10,
        minute: 0,
        now: now,
      );

      expect(nextTrigger.isAfter(now), isTrue);
      expect(nextTrigger.year, 2026);
      expect(nextTrigger.month, 9);
      expect(nextTrigger.day, 25);
    });
  });

  group('Reminders Engine - Cancellation Conditions', () {
    test('Daily wird is cancelled/suppressed if lastCompletedDate equals today', () {
      final shouldCancel = RemindersCalendarCalc.shouldCancelDailyWird(
        lastCompletedDate: '2026-09-30',
        todayDate: '2026-09-30',
      );
      expect(shouldCancel, isTrue);
    });

    test('Daily wird is NOT cancelled if lastCompletedDate was yesterday', () {
      final shouldCancel = RemindersCalendarCalc.shouldCancelDailyWird(
        lastCompletedDate: '2026-09-29',
        todayDate: '2026-09-30',
      );
      expect(shouldCancel, isFalse);
    });

    test('Commute wird is cancelled if slot was marked completed today', () {
      expect(RemindersCalendarCalc.shouldCancelCommuteWird(isSlotCompletedToday: true), isTrue);
      expect(RemindersCalendarCalc.shouldCancelCommuteWird(isSlotCompletedToday: false), isFalse);
    });

    test('Monthly sadaqah is cancelled if already donated in this cycle', () {
      expect(RemindersCalendarCalc.shouldCancelMonthlySadaqah(isDonatedInCurrentCycle: true), isTrue);
      expect(RemindersCalendarCalc.shouldCancelMonthlySadaqah(isDonatedInCurrentCycle: false), isFalse);
    });

    test('Azkar is suppressed within ±10 minutes of prayer time', () {
      final prayerTimes = [
        DateTime(2026, 9, 30, 4, 30),  // Fajr
        DateTime(2026, 9, 30, 12, 0),  // Dhuhr
        DateTime(2026, 9, 30, 15, 15), // Asr
        DateTime(2026, 9, 30, 17, 45), // Maghrib
        DateTime(2026, 9, 30, 19, 15), // Isha
      ];

      // 12:05 is 5 mins after Dhuhr -> within ±10 mins -> suppressed!
      final nearTime = DateTime(2026, 9, 30, 12, 5);
      expect(
        RemindersCalendarCalc.isNearPrayerQuietWindow(
          currentDateTime: nearTime,
          prayerTimes: prayerTimes,
          toleranceMinutes: 10,
        ),
        isTrue,
      );

      // 12:15 is 15 mins after Dhuhr -> outside ±10 mins -> NOT suppressed!
      final farTime = DateTime(2026, 9, 30, 12, 15);
      expect(
        RemindersCalendarCalc.isNearPrayerQuietWindow(
          currentDateTime: farTime,
          prayerTimes: prayerTimes,
          toleranceMinutes: 10,
        ),
        isFalse,
      );
    });
  });
}
