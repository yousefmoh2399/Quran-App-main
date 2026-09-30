library;

/// Utility functions for the authentic Mushaf display.

/// Converts an integer to Eastern Arabic digits (٠, ١, ٢, ٣...).
String toArabicDigits(int number) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number.toString().split('').map((char) {
    final digit = int.tryParse(char);
    return digit != null ? digits[digit] : char;
  }).join();
}

/// Computes the approximate Hizb number (1..60) based on page and juz number.
int calculateHizbNumber(int pageNumber, int juzNumber) {
  // Each Juz has exactly 2 Ahzab (approx 10 pages each in the 604-page Mushaf)
  final hizb = ((pageNumber - 1) ~/ 10) + 1;
  return hizb.clamp(1, 60);
}

/// Names of the 30 Ajza' in traditional Arabic.
const List<String> kAjzaNamesArabic = [
  'الأول',
  'الثاني',
  'الثالث',
  'الرابع',
  'الخامس',
  'السادس',
  'السابع',
  'الثامن',
  'التاسع',
  'العاشر',
  'الحادي عشر',
  'الثاني عشر',
  'الثالث عشر',
  'الرابع عشر',
  'الخامس عشر',
  'السادس عشر',
  'السابع عشر',
  'الثامن عشر',
  'التاسع عشر',
  'العشرون',
  'الحادي والعشرون',
  'الثاني والعشرون',
  'الثالث والعشرون',
  'الرابع والعشرون',
  'الخامس والعشرون',
  'السادس والعشرون',
  'السابع والعشرون',
  'الثامن والعشرون',
  'التاسع والعشرون',
  'الثلاثون',
];

String getJuzNameArabic(int juzNumber) {
  if (juzNumber >= 1 && juzNumber <= 30) {
    return kAjzaNamesArabic[juzNumber - 1];
  }
  return '$juzNumber';
}
