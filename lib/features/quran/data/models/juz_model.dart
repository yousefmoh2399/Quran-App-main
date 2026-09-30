class JuzModel {
  final int number;
  final String title;
  final String startSurahName;
  final int startSurahIndex; // 0-based index
  final int startAyah;

  const JuzModel({
    required this.number,
    required this.title,
    required this.startSurahName,
    required this.startSurahIndex,
    required this.startAyah,
  });

  static const List<JuzModel> allJuz = [
    JuzModel(number: 1, title: 'الجزء الأول', startSurahName: 'الفاتحة', startSurahIndex: 0, startAyah: 1),
    JuzModel(number: 2, title: 'الجزء الثاني', startSurahName: 'البقرة', startSurahIndex: 1, startAyah: 142),
    JuzModel(number: 3, title: 'الجزء الثالث', startSurahName: 'البقرة', startSurahIndex: 1, startAyah: 253),
    JuzModel(number: 4, title: 'الجزء الرابع', startSurahName: 'آل عمران', startSurahIndex: 2, startAyah: 93),
    JuzModel(number: 5, title: 'الجزء الخامس', startSurahName: 'النساء', startSurahIndex: 3, startAyah: 24),
    JuzModel(number: 6, title: 'الجزء السادس', startSurahName: 'النساء', startSurahIndex: 3, startAyah: 148),
    JuzModel(number: 7, title: 'الجزء السابع', startSurahName: 'المائدة', startSurahIndex: 4, startAyah: 82),
    JuzModel(number: 8, title: 'الجزء الثامن', startSurahName: 'الأنعام', startSurahIndex: 5, startAyah: 111),
    JuzModel(number: 9, title: 'الجزء التاسع', startSurahName: 'الأعراف', startSurahIndex: 6, startAyah: 88),
    JuzModel(number: 10, title: 'الجزء العاشر', startSurahName: 'الأنفال', startSurahIndex: 7, startAyah: 41),
    JuzModel(number: 11, title: 'الجزء الحادي عشر', startSurahName: 'التوبة', startSurahIndex: 8, startAyah: 93),
    JuzModel(number: 12, title: 'الجزء الثاني عشر', startSurahName: 'هود', startSurahIndex: 10, startAyah: 6),
    JuzModel(number: 13, title: 'الجزء الثالث عشر', startSurahName: 'يوسف', startSurahIndex: 11, startAyah: 53),
    JuzModel(number: 14, title: 'الجزء الرابع عشر', startSurahName: 'الحجر', startSurahIndex: 14, startAyah: 1),
    JuzModel(number: 15, title: 'الجزء الخامس عشر', startSurahName: 'الإسراء', startSurahIndex: 16, startAyah: 1),
    JuzModel(number: 16, title: 'الجزء السادس عشر', startSurahName: 'الكهف', startSurahIndex: 17, startAyah: 75),
    JuzModel(number: 17, title: 'الجزء السابع عشر', startSurahName: 'الأنبياء', startSurahIndex: 20, startAyah: 1),
    JuzModel(number: 18, title: 'الجزء الثامن عشر', startSurahName: 'المؤمنون', startSurahIndex: 22, startAyah: 1),
    JuzModel(number: 19, title: 'الجزء التاسع عشر', startSurahName: 'الفرقان', startSurahIndex: 24, startAyah: 21),
    JuzModel(number: 20, title: 'الجزء العشرون', startSurahName: 'النمل', startSurahIndex: 26, startAyah: 56),
    JuzModel(number: 21, title: 'الجزء الحادي والعشرون', startSurahName: 'العنكبوت', startSurahIndex: 28, startAyah: 46),
    JuzModel(number: 22, title: 'الجزء الثاني والعشرون', startSurahName: 'الأحزاب', startSurahIndex: 32, startAyah: 31),
    JuzModel(number: 23, title: 'الجزء الثالث والعشرون', startSurahName: 'يس', startSurahIndex: 35, startAyah: 28),
    JuzModel(number: 24, title: 'الجزء الرابع والعشرون', startSurahName: 'الزمر', startSurahIndex: 38, startAyah: 32),
    JuzModel(number: 25, title: 'الجزء الخامس والعشرون', startSurahName: 'فصلت', startSurahIndex: 40, startAyah: 47),
    JuzModel(number: 26, title: 'الجزء السادس والعشرون', startSurahName: 'الأحقاف', startSurahIndex: 45, startAyah: 1),
    JuzModel(number: 27, title: 'الجزء السابع والعشرون', startSurahName: 'الذاريات', startSurahIndex: 50, startAyah: 31),
    JuzModel(number: 28, title: 'الجزء الثامن والعشرون', startSurahName: 'المجادلة', startSurahIndex: 57, startAyah: 1),
    JuzModel(number: 29, title: 'الجزء التاسع والعشرون', startSurahName: 'الملك', startSurahIndex: 66, startAyah: 1),
    JuzModel(number: 30, title: 'الجزء الثلاثون', startSurahName: 'النبأ', startSurahIndex: 77, startAyah: 1),
  ];
}
