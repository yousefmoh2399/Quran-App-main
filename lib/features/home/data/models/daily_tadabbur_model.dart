class DailyTadabburItem {
  final int id;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final String ayahText;
  final String reflection;
  final String scholar;
  final String source;

  const DailyTadabburItem({
    required this.id,
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.ayahText,
    required this.reflection,
    required this.scholar,
    required this.source,
  });

  String get reference => '$surahName: آية $ayahNumber';
  String get attribution => '$scholar - $source';
}
