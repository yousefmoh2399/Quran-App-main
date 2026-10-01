/// Safe, standalone Arabic and Islamic date/time formatter.
///
/// Does NOT rely on `intl` locale symbol tables, preventing any
/// [LocaleDataException] or uninitialized locale errors at runtime.
class ArabicDateFormatter {
  static const List<String> weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Formats date to Arabic full text, e.g. "الخميس، 1 أكتوبر 2026"
  static String formatFullDate(DateTime dt) {
    final weekdayName = weekdays[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$weekdayName، ${dt.day} $monthName ${dt.year}';
  }

  /// Formats time in 12-hour format with Arabic AM/PM, e.g. "04:30 ص" or "07:15 م"
  static String formatTime12h(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'ص' : 'م';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Formats date as YYYY-MM-DD
  static String formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
