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

  BookmarkItem({
    this.id,
    required this.type,
    required this.page,
    this.surah,
    this.ayah,
    this.color = BookmarkColor.gold,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BookmarkItem copyWith({
    int? id,
    BookmarkType? type,
    int? page,
    int? surah,
    int? ayah,
    BookmarkColor? color,
    String? note,
    DateTime? createdAt,
  }) {
    return BookmarkItem(
      id: id ?? this.id,
      type: type ?? this.type,
      page: page ?? this.page,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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

  MemorizedItem({
    this.id,
    required this.type,
    required this.page,
    this.surah,
    this.ayah,
    required this.status,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  MemorizedItem copyWith({
    int? id,
    BookmarkType? type,
    int? page,
    int? surah,
    int? ayah,
    MemorizeStatus? status,
    DateTime? updatedAt,
  }) {
    return MemorizedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      page: page ?? this.page,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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

/// Status of prayer performance
enum PrayerStatus {
  onTime('on_time', 'في وقتها', Color(0xFF0F5C4A)),
  jamaah('jamaah', 'في جماعة', Color(0xFF1E824C)),
  late('late', 'متأخرة', Color(0xFFD35400)),
  missed('missed', 'فائتة', Color(0xFFB3261E)),
  qadaa('qadaa', 'قضاء', Color(0xFF7B1FA2));

  final String key;
  final String labelAr;
  final Color color;

  const PrayerStatus(this.key, this.labelAr, this.color);

  static PrayerStatus fromKey(String? key) {
    for (final s in PrayerStatus.values) {
      if (s.key == key) return s;
    }
    return PrayerStatus.onTime;
  }
}

/// Daily prayer log entry
class PrayerLog {
  final int? id;
  final String date; // YYYY-MM-DD
  final String prayer; // fajr, dhuhr, asr, maghrib, isha
  final PrayerStatus status;
  final DateTime createdAt;

  PrayerLog({
    this.id,
    required this.date,
    required this.prayer,
    required this.status,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'prayer': prayer,
      'status': status.key,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PrayerLog.fromMap(Map<String, dynamic> map) {
    return PrayerLog(
      id: map['id'] as int?,
      date: map['date'] as String,
      prayer: map['prayer'] as String,
      status: PrayerStatus.fromKey(map['status'] as String?),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Fasting type
enum FastingType {
  ramadan('ramadan', 'رمضان'),
  whiteDays('white_days', 'الأيام البيض'),
  mondayThursday('monday_thursday', 'الاثنين والخميس'),
  arafah('arafah', 'عرفة'),
  ashura('ashura', 'عاشوراء / تاسوعاء'),
  voluntary('voluntary', 'صيام تطوع'),
  qadaa('qadaa', 'قضاء فريضة');

  final String key;
  final String labelAr;

  const FastingType(this.key, this.labelAr);

  static FastingType fromKey(String? key) {
    for (final t in FastingType.values) {
      if (t.key == key) return t;
    }
    return FastingType.voluntary;
  }
}

/// Fasting log entry
class FastingLog {
  final int? id;
  final String date; // YYYY-MM-DD
  final FastingType type;
  final bool completed;
  final DateTime createdAt;

  FastingLog({
    this.id,
    required this.date,
    required this.type,
    this.completed = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'type': type.key,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FastingLog.fromMap(Map<String, dynamic> map) {
    return FastingLog(
      id: map['id'] as int?,
      date: map['date'] as String,
      type: FastingType.fromKey(map['type'] as String?),
      completed: (map['completed'] as int? ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Achievement Badge Definition
class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<AchievementBadge> all = [
    AchievementBadge(
      id: 'first_page',
      title: 'فاتحة الخير',
      description: 'قراءة أول صفحة من كتاب الله',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF0F5C4A),
    ),
    AchievementBadge(
      id: 'streak_3',
      title: 'بصيرة البدايات',
      description: '3 أيام متتالية من القراءة',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFB8892B),
    ),
    AchievementBadge(
      id: 'streak_7',
      title: 'حامل الورد',
      description: 'أسبوع كامل من المواظبة على الورد',
      icon: Icons.stars_rounded,
      color: Color(0xFF2980B9),
    ),
    AchievementBadge(
      id: 'streak_30',
      title: 'صاحب القرآن',
      description: '30 يوماً من الصحبة المتواصلة',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF8E44AD),
    ),
    AchievementBadge(
      id: 'prayers_day',
      title: 'حارس الفريضة',
      description: 'تسجيل الصلوات الخمس في وقتها ليوم كامل',
      icon: Icons.mosque_rounded,
      color: Color(0xFF1E824C),
    ),
    AchievementBadge(
      id: 'fasting_day',
      title: 'صائم محتسب',
      description: 'إتمام يوم صيام سنة أو فريضة',
      icon: Icons.wb_twilight_rounded,
      color: Color(0xFFD35400),
    ),
    AchievementBadge(
      id: 'commute_reader',
      title: 'قارئ الأوقات',
      description: 'إنجاز قراءة في ورد التنقل والمواصلات',
      icon: Icons.directions_transit_rounded,
      color: Color(0xFF16A085),
    ),
    AchievementBadge(
      id: 'first_khatma',
      title: 'ختمة النور',
      description: 'إتمام ختمة كاملة لكتاب الله المبارك',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFD9A036),
    ),
  ];
}

