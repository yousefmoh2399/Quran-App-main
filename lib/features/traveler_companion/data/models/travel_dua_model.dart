enum TravelDuaCategory {
  mounting('ركوب الدابة والوسيلة', 'عند ركوب السيارة أو الطائرة أو القطار'),
  journey('دعاء السفر العام', 'الدعاء النبوي الشامل عند بدء الرحلة'),
  farewell('توديع المسافر', 'أدعية الوداع بين المسافر والمقيم'),
  arrival('النزول في مكان', 'عند النزول في فندق أو استراحة أو مدينة'),
  takbeer('التكبير والتسبيح', 'سنة التكبير عند الصعود والتسبيح عند الهبوط'),
  returnTrip('الرجوع والقفول', 'أدعية العودة بسلامة الله إلى الوطن');

  final String titleAr;
  final String descriptionAr;

  const TravelDuaCategory(this.titleAr, this.descriptionAr);
}

/// Represents an authentic travel supplication or remembrance from the Sunnah.
class TravelDuaModel {
  final String id;
  final TravelDuaCategory category;
  final String title;
  final String arabicText;
  final String reference; // e.g. صحيح مسلم، سنن أبي داود
  final String? virtue; // فضل الذكر أو لطيفة نبوية
  final int targetCount;

  const TravelDuaModel({
    required this.id,
    required this.category,
    required this.title,
    required this.arabicText,
    required this.reference,
    this.virtue,
    this.targetCount = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'arabicText': arabicText,
      'reference': reference,
      'virtue': virtue,
      'targetCount': targetCount,
    };
  }
}
