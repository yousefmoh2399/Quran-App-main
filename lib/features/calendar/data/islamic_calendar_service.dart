import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

/// Represents an Islamic occasion/event
class IslamicEvent {
  final String title;
  final String description;
  final int hijriMonth;
  final int hijriDay;
  final IconData icon;
  final Color color;
  final bool isFastingRecommended;

  const IslamicEvent({
    required this.title,
    required this.description,
    required this.hijriMonth,
    required this.hijriDay,
    required this.icon,
    required this.color,
    this.isFastingRecommended = false,
  });
}

class IslamicCalendarService {
  IslamicCalendarService._();
  static final IslamicCalendarService instance = IslamicCalendarService._();

  /// Comprehensive list of major Islamic occasions
  static const List<IslamicEvent> majorOccasions = [
    IslamicEvent(
      title: 'رأس السنة الهجرية',
      description: 'بداية العام الهجري الجديد',
      hijriMonth: 1,
      hijriDay: 1,
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF0F5C4A),
    ),
    IslamicEvent(
      title: 'تاسوعاء',
      description: 'سنة نبوية مؤكدة صيام اليوم التاسع من محرم',
      hijriMonth: 1,
      hijriDay: 9,
      icon: Icons.wb_twilight_rounded,
      color: Color(0xFFD35400),
      isFastingRecommended: true,
    ),
    IslamicEvent(
      title: 'يوم عاشوراء',
      description: 'اليوم العاشر من محرم، يكفر ذنوب السنة الماضية',
      hijriMonth: 1,
      hijriDay: 10,
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFB8892B),
      isFastingRecommended: true,
    ),
    IslamicEvent(
      title: 'المولد النبوي الشريف',
      description: 'ذكرى مولد خير البرية ﷺ',
      hijriMonth: 3,
      hijriDay: 12,
      icon: Icons.favorite_rounded,
      color: Color(0xFF1E824C),
    ),
    IslamicEvent(
      title: 'الإسراء والمعراج',
      description: 'ذكرى معجزة الإسراء والمعراج وفرض الصلاة',
      hijriMonth: 7,
      hijriDay: 27,
      icon: Icons.nightlight_round,
      color: Color(0xFF2980B9),
    ),
    IslamicEvent(
      title: 'ليلة النصف من شعبان',
      description: 'ليلة مباركة يستحب فيها قيام الليل والدعاء',
      hijriMonth: 8,
      hijriDay: 15,
      icon: Icons.brightness_medium_rounded,
      color: Color(0xFF8E44AD),
      isFastingRecommended: true,
    ),
    IslamicEvent(
      title: 'أول أيام شهر رمضان المبارك',
      description: 'شهر الصيام والقرآن والرحمة والمغفرة',
      hijriMonth: 9,
      hijriDay: 1,
      icon: Icons.nightlight_round,
      color: Color(0xFF0F5C4A),
      isFastingRecommended: true,
    ),
    IslamicEvent(
      title: 'ليالي القدر المرجوة',
      description: 'العشر الأواخر من رمضان، خير من ألف شهر',
      hijriMonth: 9,
      hijriDay: 27,
      icon: Icons.stars_rounded,
      color: Color(0xFFD9A036),
      isFastingRecommended: true,
    ),
    IslamicEvent(
      title: 'عيد الفطر المبارك',
      description: 'أول شوال، يوم الجائزة والفرح بإتمام الصيام',
      hijriMonth: 10,
      hijriDay: 1,
      icon: Icons.celebration_rounded,
      color: Color(0xFF27AE60),
    ),
    IslamicEvent(
      title: 'يوم عرفة',
      description: 'خير يوم طلعت عليه الشمس، صيامه يكفر سنتين',
      hijriMonth: 12,
      hijriDay: 9,
      icon: Icons.landscape_rounded,
      color: Color(0xFFB8892B),
      isFastingRecommended: true,
    ),
    IslamicEvent(
      title: 'عيد الأضحى المبارك',
      description: 'يوم النحر وأعظم الأيام عند الله',
      hijriMonth: 12,
      hijriDay: 10,
      icon: Icons.celebration_rounded,
      color: Color(0xFF16A085),
    ),
  ];

  /// Arabic names of Hijri months
  static const List<String> hijriMonthNames = [
    '',
    'مُحَرَّم',
    'صَفَر',
    'رَبِيع الأَوَّل',
    'رَبِيع الآخِر',
    'جُمَادَى الأُولَى',
    'جُمَادَى الآخِرَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو القَعْدَة',
    'ذُو الحِجَّة',
  ];

  /// Get current Hijri date
  HijriCalendar getTodayHijri() {
    HijriCalendar.setLocal('ar');
    return HijriCalendar.now();
  }

  /// Convert Gregorian to Hijri
  HijriCalendar fromGregorian(DateTime dt) {
    HijriCalendar.setLocal('ar');
    return HijriCalendar.fromDate(dt);
  }

  /// Convert Hijri to Gregorian
  DateTime toGregorian(int year, int month, int day) {
    final hijri = HijriCalendar();
    return hijri.hijriToGregorian(year, month, day);
  }

  /// Checks if given date is one of the White Days (13, 14, 15 of Hijri month)
  bool isWhiteDay(HijriCalendar hijri) {
    return hijri.hDay == 13 || hijri.hDay == 14 || hijri.hDay == 15;
  }

  /// Checks if given date is Monday or Thursday
  bool isMondayOrThursday(DateTime dt) {
    return dt.weekday == DateTime.monday || dt.weekday == DateTime.thursday;
  }

  /// Checks if given date is Friday (Sunnah of Al-Kahf & Salawat)
  bool isFriday(DateTime dt) {
    return dt.weekday == DateTime.friday;
  }

  /// Finds any special Islamic event for a given Hijri month & day
  IslamicEvent? getEventForDate(int month, int day) {
    for (final event in majorOccasions) {
      if (event.hijriMonth == month && event.hijriDay == day) {
        return event;
      }
    }
    return null;
  }

  /// Suggests fasting status for a given Gregorian date
  String? getFastingRecommendation(DateTime dt) {
    final h = fromGregorian(dt);
    if (h.hMonth == 9) return 'صيام رمضان المبارك (فريضة)';
    if (h.hMonth == 12 && h.hDay == 9) return 'صيام يوم عرفة (يكفر سنتين)';
    if (h.hMonth == 1 && (h.hDay == 9 || h.hDay == 10)) return 'صيام عاشوراء وتاسوعاء';
    if (isWhiteDay(h)) return 'صيام الأيام البيض (${h.hDay} ${hijriMonthNames[h.hMonth]})';
    if (isMondayOrThursday(dt)) return 'صيام سنة ${dt.weekday == DateTime.monday ? "الاثنين" : "الخميس"}';
    return null;
  }
}
