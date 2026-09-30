class SurahEntity {
  final int id;
  final String nameAr;
  final String nameEn;
  final String transliteration;
  final String type;
  final int totalVerses;

  const SurahEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.transliteration,
    required this.type,
    required this.totalVerses,
  });

  factory SurahEntity.fromMap(Map<String, dynamic> map) {
    return SurahEntity(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      transliteration: map['transliteration'] as String,
      type: map['type'] as String,
      totalVerses: map['total_verses'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'transliteration': transliteration,
      'type': type,
      'total_verses': totalVerses,
    };
  }
}
