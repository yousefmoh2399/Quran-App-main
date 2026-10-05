import 'package:flutter/foundation.dart';

/// Centralized budget management for iOS local scheduled notifications.
///
/// Apple iOS imposes a strict system limit of 64 maximum scheduled local
/// notifications per application. This class defines and guarantees non-overlapping,
/// deterministic ID spaces for all notification categories within the budget.
class NotificationBudget {
  NotificationBudget._();

  /// Hard system limit imposed by iOS UNUserNotificationCenter.
  static const int maxTotalBudget = 64;

  // --- Allocation Quotas ---
  /// 8 days rolling window × 5 daily prayers = 40 slots.
  static const int prayerDays = 8;
  static const int prayersPerDay = 5;
  static const int prayerSlotCount = prayerDays * prayersPerDay; // 40

  /// Daily Quran Wird: next 7 days = 7 slots.
  static const int wirdSlotCount = 7;

  /// Commuting / Transit reminder: next 7 days = 7 slots.
  static const int transitSlotCount = 7;

  /// Monthly Sadaqah: 1 slot (next occurrence).
  static const int sadaqahSlotCount = 1;

  /// Periodic Azkar: 8 rotating daytime slots = 8 slots.
  static const int azkarPeriodicSlotCount = 8;

  /// Total allocated slots across all features: 40 + 7 + 7 + 1 + 8 = 63.
  static const int totalAllocated = prayerSlotCount +
      wirdSlotCount +
      transitSlotCount +
      sadaqahSlotCount +
      azkarPeriodicSlotCount;

  // --- Deterministic Base IDs ---
  static const int prayerBaseId = 1000;       // Range: 1000..1039
  static const int wirdBaseId = 2000;         // Range: 2000..2006
  static const int transitBaseId = 2100;      // Range: 2100..2106
  static const int sadaqahBaseId = 2200;      // Range: 2200
  static const int azkarPeriodicBaseId = 2300;// Range: 2300..2307

  /// Verifies that total allocated notification slots never exceed iOS hard limit of 64.
  static bool validateBudget() {
    assert(
      totalAllocated <= maxTotalBudget,
      'Total scheduled notifications ($totalAllocated) exceeds iOS maximum of $maxTotalBudget',
    );
    if (totalAllocated > maxTotalBudget) {
      debugPrint(
        '⚠️ [NotificationBudget] VIOLATION: $totalAllocated allocated, max is $maxTotalBudget!',
      );
      return false;
    }
    return true;
  }

  /// Calculates deterministic ID for a prayer notification.
  /// [dayOffset] range: 0..7.
  /// [prayerIndex] range: 0..4 (0: Fajr, 1: Dhuhr, 2: Asr, 3: Maghrib, 4: Isha).
  static int getPrayerId(int dayOffset, int prayerIndex) {
    assert(dayOffset >= 0 && dayOffset < prayerDays, 'dayOffset must be 0..${prayerDays - 1}');
    assert(prayerIndex >= 0 && prayerIndex < prayersPerDay, 'prayerIndex must be 0..${prayersPerDay - 1}');
    return prayerBaseId + (dayOffset * prayersPerDay) + prayerIndex;
  }

  /// Returns list of all 40 prayer notification IDs.
  static List<int> getAllPrayerIds() {
    return List.generate(prayerSlotCount, (index) => prayerBaseId + index);
  }

  /// Calculates deterministic ID for daily Quran Wird notification.
  /// [dayOffset] range: 0..6.
  static int getWirdId(int dayOffset) {
    assert(dayOffset >= 0 && dayOffset < wirdSlotCount, 'dayOffset must be 0..${wirdSlotCount - 1}');
    return wirdBaseId + dayOffset;
  }

  /// Returns list of all 7 daily wird notification IDs.
  static List<int> getAllWirdIds() {
    return List.generate(wirdSlotCount, (index) => wirdBaseId + index);
  }

  /// Calculates deterministic ID for commuting/transit reminder.
  /// [dayOffset] range: 0..6.
  static int getTransitId(int dayOffset) {
    assert(dayOffset >= 0 && dayOffset < transitSlotCount, 'dayOffset must be 0..${transitSlotCount - 1}');
    return transitBaseId + dayOffset;
  }

  /// Returns list of all 7 transit reminder notification IDs.
  static List<int> getAllTransitIds() {
    return List.generate(transitSlotCount, (index) => transitBaseId + index);
  }

  /// Deterministic ID for monthly Sadaqah reminder.
  static int getSadaqahId() => sadaqahBaseId;

  /// Calculates deterministic ID for periodic rotating Azkar slot.
  /// [slotIndex] range: 0..7.
  static int getAzkarId(int slotIndex) {
    assert(
      slotIndex >= 0 && slotIndex < azkarPeriodicSlotCount,
      'slotIndex must be 0..${azkarPeriodicSlotCount - 1}',
    );
    return azkarPeriodicBaseId + slotIndex;
  }

  /// Returns list of all 8 periodic azkar notification IDs.
  static List<int> getAllAzkarIds() {
    return List.generate(azkarPeriodicSlotCount, (index) => azkarPeriodicBaseId + index);
  }

  /// Returns all 63 notification IDs currently defined in the budget.
  static List<int> getAllAllocatedIds() {
    return [
      ...getAllPrayerIds(),
      ...getAllWirdIds(),
      ...getAllTransitIds(),
      getSadaqahId(),
      ...getAllAzkarIds(),
    ];
  }
}
