import 'package:flutter/material.dart';

/// Type of bookmark: Whole page or specific Ayah.
enum BookmarkType {
  page,
  ayah;

  static BookmarkType fromString(String val) {
    return val == 'ayah' ? BookmarkType.ayah : BookmarkType.page;
  }
}

/// Color preset for bookmarks and highlights.
enum BookmarkColor {
  gold(Color(0xFFD9A036), 'gold', 'ذهبي'),
  emerald(Color(0xFF1E824C), 'green', 'أخضر'),
  blue(Color(0xFF2980B9), 'blue', 'أزرق'),
  ruby(Color(0xFFC0392B), 'ruby', 'ياقوتي'),
  amber(Color(0xFFD35400), 'amber', 'كهرماني');

  final Color color;
  final String key;
  final String labelAr;

  const BookmarkColor(this.color, this.key, this.labelAr);

  static BookmarkColor fromKey(String? key) {
    for (final c in BookmarkColor.values) {
      if (c.key == key) return c;
    }
    return BookmarkColor.gold;
  }
}

/// A saved user bookmark for a page or an ayah.
class BookmarkItem {
  final int? id;
  final BookmarkType type;
  final int page;
  final int? surah;
  final int? ayah;
  final BookmarkColor color;
  final String? note;
  final DateTime createdAt;

  const BookmarkItem({
    this.id,
    required this.type,
    required this.page,
    this.surah,
    this.ayah,
    this.color = BookmarkColor.gold,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'page': page,
      'surah': surah,
      'ayah': ayah,
      'color': color.key,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BookmarkItem.fromMap(Map<String, dynamic> map) {
    return BookmarkItem(
      id: map['id'] as int?,
      type: BookmarkType.fromString(map['type'] as String? ?? 'page'),
      page: map['page'] as int? ?? 1,
      surah: map['surah'] as int?,
      ayah: map['ayah'] as int?,
      color: BookmarkColor.fromKey(map['color'] as String?),
      note: map['note'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Status of Quran memorization for a page or verse.
enum MemorizeStatus {
  learning('learning', 'بيحفظ', Color(0xFFE67E22)),
  memorized('memorized', 'محفوظ', Color(0xFF27AE60)),
  needsReview('needs_review', 'يحتاج مراجعة', Color(0xFF8E44AD));

  final String key;
  final String labelAr;
  final Color badgeColor;

  const MemorizeStatus(this.key, this.labelAr, this.badgeColor);

  static MemorizeStatus fromKey(String? key) {
    for (final s in MemorizeStatus.values) {
      if (s.key == key) return s;
    }
    return MemorizeStatus.learning;
  }
}

/// Memorization record for a page or an ayah.
class MemorizedItem {
  final int? id;
  final BookmarkType type;
  final int page;
  final int? surah;
  final int? ayah;
  final MemorizeStatus status;
  final DateTime updatedAt;

  const MemorizedItem({
    this.id,
    required this.type,
    required this.page,
    this.surah,
    this.ayah,
    required this.status,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'page': page,
      'surah': surah,
      'ayah': ayah,
      'status': status.key,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MemorizedItem.fromMap(Map<String, dynamic> map) {
    return MemorizedItem(
      id: map['id'] as int?,
      type: BookmarkType.fromString(map['type'] as String? ?? 'page'),
      page: map['page'] as int? ?? 1,
      surah: map['surah'] as int?,
      ayah: map['ayah'] as int?,
      status: MemorizeStatus.fromKey(map['status'] as String?),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Daily reading log entry.
class ReadingLogEntry {
  final int? id;
  final String date; // YYYY-MM-DD
  final int pagesRead;
  final int lastPage;

  const ReadingLogEntry({
    this.id,
    required this.date,
    required this.pagesRead,
    required this.lastPage,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'pages_read': pagesRead,
      'last_page': lastPage,
    };
  }

  factory ReadingLogEntry.fromMap(Map<String, dynamic> map) {
    return ReadingLogEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      pagesRead: map['pages_read'] as int? ?? 0,
      lastPage: map['last_page'] as int? ?? 1,
    );
  }
}

/// Type of Daily Wird plan.
enum WirdType {
  pagesPerDay('pages_per_day', 'عدد صفحات يومياً'),
  khatmaInDays('khatma_in_days', 'ختمة في عدد أيام'),
  juzPerDay('juz_per_day', 'جزء يومياً');

  final String key;
  final String labelAr;

  const WirdType(this.key, this.labelAr);

  static WirdType fromKey(String? key) {
    for (final t in WirdType.values) {
      if (t.key == key) return t;
    }
    return WirdType.pagesPerDay;
  }
}

/// User's Daily Wird Plan.
class WirdPlan {
  final int? id;
  final WirdType type;
  final int target; // e.g. 10 pages, 30 days, or 1 juz
  final String startDate; // YYYY-MM-DD
  final String reminderTime; // HH:mm
  final String? secondReminderTime; // HH:mm
  final bool enabled;
  final int startPage;
  final int endPage;
  final int streak;
  final String? lastCompletedDate;

  const WirdPlan({
    this.id,
    required this.type,
    required this.target,
    required this.startDate,
    this.reminderTime = '09:00',
    this.secondReminderTime = '22:00',
    this.enabled = true,
    this.startPage = 1,
    this.endPage = 10,
    this.streak = 0,
    this.lastCompletedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type.key,
      'target': target,
      'start_date': startDate,
      'reminder_time': reminderTime,
      'second_reminder_time': secondReminderTime,
      'enabled': enabled ? 1 : 0,
      'start_page': startPage,
      'end_page': endPage,
      'streak': streak,
      'last_completed_date': lastCompletedDate,
    };
  }

  factory WirdPlan.fromMap(Map<String, dynamic> map) {
    return WirdPlan(
      id: map['id'] as int?,
      type: WirdType.fromKey(map['type'] as String?),
      target: map['target'] as int? ?? 10,
      startDate: map['start_date'] as String? ?? DateTime.now().toIso8601String().substring(0, 10),
      reminderTime: map['reminder_time'] as String? ?? '09:00',
      secondReminderTime: map['second_reminder_time'] as String? ?? '22:00',
      enabled: (map['enabled'] as int? ?? 1) == 1,
      startPage: map['start_page'] as int? ?? 1,
      endPage: map['end_page'] as int? ?? 10,
      streak: map['streak'] as int? ?? 0,
      lastCompletedDate: map['last_completed_date'] as String?,
    );
  }

  WirdPlan copyWith({
    int? id,
    WirdType? type,
    int? target,
    String? startDate,
    String? reminderTime,
    String? secondReminderTime,
    bool? enabled,
    int? startPage,
    int? endPage,
    int? streak,
    String? lastCompletedDate,
  }) {
    return WirdPlan(
      id: id ?? this.id,
      type: type ?? this.type,
      target: target ?? this.target,
      startDate: startDate ?? this.startDate,
      reminderTime: reminderTime ?? this.reminderTime,
      secondReminderTime: secondReminderTime ?? this.secondReminderTime,
      enabled: enabled ?? this.enabled,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      streak: streak ?? this.streak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }
}
