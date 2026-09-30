class AyahEntity {
  final int id;
  final int surahId;
  final int ayahNumber;
  final int? pageNumber;
  final String textAr;
  final String? textEn;
  final String? tafsirMuyassar;
  final String textSearch;

  const AyahEntity({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    this.pageNumber,
    required this.textAr,
    this.textEn,
    this.tafsirMuyassar,
    required this.textSearch,
  });

  factory AyahEntity.fromMap(Map<String, dynamic> map) {
    return AyahEntity(
      id: map['id'] as int,
      surahId: map['surah_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      pageNumber: map['page_number'] as int?,
      textAr: map['text_ar'] as String,
      textEn: map['text_en'] as String?,
      tafsirMuyassar: map['tafsir_muyassar'] as String?,
      textSearch: (map['text_search'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surah_id': surahId,
      'ayah_number': ayahNumber,
      'page_number': pageNumber,
      'text_ar': textAr,
      'text_en': textEn,
      'tafsir_muyassar': tafsirMuyassar,
      'text_search': textSearch,
    };
  }
}
