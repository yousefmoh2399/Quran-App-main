/// Model representing the active or stored state of the Khuffain/Socks Wiping Timer (مؤقت المسح على الخفين والجوربين).
class WipingTimerState {
  final bool isActive;
  final bool isTraveler; // true = 72 hours (3 days & nights), false = 24 hours (1 day & night)
  final DateTime startedAt;
  final int durationHours; // 24 or 72
  final String? notes;

  const WipingTimerState({
    required this.isActive,
    required this.isTraveler,
    required this.startedAt,
    required this.durationHours,
    this.notes,
  });

  /// Factory constructor for a newly started timer
  factory WipingTimerState.start({
    required bool isTraveler,
    DateTime? startTime,
    String? notes,
  }) {
    final start = startTime ?? DateTime.now();
    return WipingTimerState(
      isActive: true,
      isTraveler: isTraveler,
      startedAt: start,
      durationHours: isTraveler ? 72 : 24,
      notes: notes,
    );
  }

  /// Timestamp when the wiping period expires
  DateTime get expiresAt => startedAt.add(Duration(hours: durationHours));

  /// Remaining duration from a given reference point (defaulting to now)
  Duration remaining([DateTime? now]) {
    final current = now ?? DateTime.now();
    final rem = expiresAt.difference(current);
    return rem.isNegative ? Duration.zero : rem;
  }

  /// Total duration in milliseconds
  int get totalDurationMs => durationHours * 3600 * 1000;

  /// Elapsed duration in milliseconds
  int elapsedMs([DateTime? now]) {
    final current = now ?? DateTime.now();
    final diff = current.difference(startedAt).inMilliseconds;
    if (diff < 0) return 0;
    if (diff > totalDurationMs) return totalDurationMs;
    return diff;
  }

  /// Progress fraction from 0.0 (just started) to 1.0 (expired)
  double progress([DateTime? now]) {
    if (totalDurationMs == 0) return 1.0;
    final elapsed = elapsedMs(now);
    return (elapsed / totalDurationMs).clamp(0.0, 1.0);
  }

  /// Whether the timer has exceeded the allocated time
  bool isExpired([DateTime? now]) {
    final current = now ?? DateTime.now();
    return current.isAfter(expiresAt);
  }

  /// Whether the timer is in the warning state (less than 2 hours left)
  bool isWarning([DateTime? now]) {
    final rem = remaining(now);
    return !isExpired(now) && rem.inMinutes <= 120;
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'isTraveler': isTraveler,
      'startedAt': startedAt.toIso8601String(),
      'durationHours': durationHours,
      'notes': notes,
    };
  }

  factory WipingTimerState.fromMap(Map<String, dynamic> map) {
    return WipingTimerState(
      isActive: map['isActive'] as bool? ?? false,
      isTraveler: map['isTraveler'] as bool? ?? false,
      startedAt: DateTime.tryParse(map['startedAt'] as String? ?? '') ?? DateTime.now(),
      durationHours: map['durationHours'] as int? ?? 24,
      notes: map['notes'] as String?,
    );
  }
}
