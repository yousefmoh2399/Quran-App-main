class HadithSectionEntity {
  final int id;
  final String source;
  final String name;

  const HadithSectionEntity({
    required this.id,
    required this.source,
    required this.name,
  });

  factory HadithSectionEntity.fromMap(Map<String, dynamic> map) {
    return HadithSectionEntity(
      id: map['id'] as int,
      source: map['source'] as String,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source': source,
      'name': name,
    };
  }
}

class HadithItemEntity {
  final int id;
  final int sectionId;
  final String source;
  final String chapter;
  final int? hadithNumber;
  final int? arabicNumber;
  final String textAr;
  final String? grade;

  const HadithItemEntity({
    required this.id,
    required this.sectionId,
    required this.source,
    required this.chapter,
    this.hadithNumber,
    this.arabicNumber,
    required this.textAr,
    this.grade,
  });

  factory HadithItemEntity.fromMap(Map<String, dynamic> map) {
    return HadithItemEntity(
      id: map['id'] as int,
      sectionId: map['section_id'] as int,
      source: map['source'] as String,
      chapter: map['chapter'] as String,
      hadithNumber: map['hadith_number'] as int?,
      arabicNumber: map['arabic_number'] as int?,
      textAr: map['text_ar'] as String,
      grade: map['grade'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'section_id': sectionId,
      'source': source,
      'chapter': chapter,
      'hadith_number': hadithNumber,
      'arabic_number': arabicNumber,
      'text_ar': textAr,
      'grade': grade,
    };
  }
}

class HadithSectionWithHadiths {
  final HadithSectionEntity section;
  final List<HadithItemEntity> hadiths;

  const HadithSectionWithHadiths({
    required this.section,
    required this.hadiths,
  });
}
