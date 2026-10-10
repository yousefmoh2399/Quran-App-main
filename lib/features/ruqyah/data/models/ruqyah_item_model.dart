enum RuqyahSource {
  quran,
  sunnah,
}

enum RuqyahCategory {
  tahseen, // تحصين وحفظ
  shifa, // علاج وشفاء
  ainHasad, // علاج العين والحسد
  sihrMass, // إبطال السحر والمس
}

class RuqyahItem {
  final int id;
  final String title;
  final String arabicText;
  final String sourceReference;
  final RuqyahSource source;
  final RuqyahCategory category;
  final int targetCount; // 1, 3, or 7
  final String? virture;

  const RuqyahItem({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.sourceReference,
    required this.source,
    required this.category,
    required this.targetCount,
    this.virture,
  });
}
