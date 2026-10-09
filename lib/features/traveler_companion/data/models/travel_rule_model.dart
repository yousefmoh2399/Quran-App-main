enum TravelRuleCategory {
  shorteningAndCombining('الجمع والقصر', 'رخص الصلوات الرباعية والجمع بين الصلاتين'),
  travelDistance('مسافة السفر', 'المسافة المعتبرة شرعاً وضابط العرف ومحل البداية'),
  planeAndTrain('في الطائرة والقطار', 'كيفية الصلاة والقبلة في وسائل النقل الحديثة'),
  sunnahPrayers('السنن والنوافل', 'ما يسقط من السنن وما يسن الحفاظ عليه للمسافر'),
  fastingConcession('رخصة الصيام', 'أحكام الفطر في رمضان للمسافر وضوابط القضاء'),
  wipingKhuffain('المسح على الخفين', 'شروط الطهارة والمدة ومبطلات المسح الشرعية');

  final String titleAr;
  final String descriptionAr;

  const TravelRuleCategory(this.titleAr, this.descriptionAr);
}

/// Represents an authentic, verified Islamic Fiqh rule and concession for travelers.
class TravelRuleModel {
  final String id;
  final TravelRuleCategory category;
  final String title;
  final String summary;
  final String? dalil; // الأثر أو الدليل من الكتاب والسنة
  final String practicalRule; // الضابط العملي المبسط
  final String? scholarlyNotes; // أقوال وتوجيهات أئمة الفقه المعتمدين

  const TravelRuleModel({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    this.dalil,
    required this.practicalRule,
    this.scholarlyNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'summary': summary,
      'dalil': dalil,
      'practicalRule': practicalRule,
      'scholarlyNotes': scholarlyNotes,
    };
  }
}
