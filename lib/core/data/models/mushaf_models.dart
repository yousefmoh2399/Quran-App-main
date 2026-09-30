class MushafWord {
  final int pageNumber;
  final int lineNumber;
  final int wordIndex;
  final int surahNumber;
  final int ayahNumber;
  final String location;
  final String textUthmani;
  final String glyphCode;

  const MushafWord({
    required this.pageNumber,
    required this.lineNumber,
    required this.wordIndex,
    required this.surahNumber,
    required this.ayahNumber,
    required this.location,
    required this.textUthmani,
    required this.glyphCode,
  });

  factory MushafWord.fromMap(Map<String, dynamic> map) {
    return MushafWord(
      pageNumber: map['page_number'] as int,
      lineNumber: map['line_number'] as int,
      wordIndex: map['word_index'] as int,
      surahNumber: map['surah_number'] as int,
      ayahNumber: map['ayah_number'] as int,
      location: map['location'] as String,
      textUthmani: map['text_uthmani'] as String,
      glyphCode: map['glyph_code'] as String,
    );
  }
}

enum MushafLineType {
  ayah,
  surahHeader,
  basmalah;

  static MushafLineType fromString(String val) {
    switch (val) {
      case 'surah_header':
        return MushafLineType.surahHeader;
      case 'basmalah':
        return MushafLineType.basmalah;
      case 'ayah':
      default:
        return MushafLineType.ayah;
    }
  }
}

class MushafLine {
  final int id;
  final int pageNumber;
  final int lineNumber;
  final MushafLineType lineType;
  final int? surahNumber;
  final String? text;
  final String? qpcV2;
  final List<MushafWord> words;

  const MushafLine({
    required this.id,
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    this.surahNumber,
    this.text,
    this.qpcV2,
    this.words = const [],
  });

  factory MushafLine.fromMap(Map<String, dynamic> map, {List<MushafWord> words = const []}) {
    return MushafLine(
      id: map['id'] as int,
      pageNumber: map['page_number'] as int,
      lineNumber: map['line_number'] as int,
      lineType: MushafLineType.fromString(map['line_type'] as String),
      surahNumber: map['surah_number'] as int?,
      text: map['text'] as String?,
      qpcV2: map['qpc_v2'] as String?,
      words: words,
    );
  }
}

class MushafPage {
  final int pageNumber;
  final List<MushafLine> lines;
  final int surahNumber;
  final String surahNameAr;
  final int juzNumber;

  const MushafPage({
    required this.pageNumber,
    required this.lines,
    required this.surahNumber,
    required this.surahNameAr,
    required this.juzNumber,
  });
}

class JuzInfo {
  final int juzNumber;
  final String nameAr;
  final int startSurah;
  final int startAyah;
  final int startPage;

  const JuzInfo({
    required this.juzNumber,
    required this.nameAr,
    required this.startSurah,
    required this.startAyah,
    required this.startPage,
  });

  factory JuzInfo.fromMap(Map<String, dynamic> map) {
    return JuzInfo(
      juzNumber: map['juz_number'] as int,
      nameAr: map['name_ar'] as String,
      startSurah: map['start_surah'] as int,
      startAyah: map['start_ayah'] as int,
      startPage: map['start_page'] as int,
    );
  }
}

class SajdahInfo {
  final int sajdahNumber;
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final String type; // obligatory / recommended

  const SajdahInfo({
    required this.sajdahNumber,
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.type,
  });

  factory SajdahInfo.fromMap(Map<String, dynamic> map) {
    return SajdahInfo(
      sajdahNumber: map['sajdah_number'] as int,
      surahNumber: map['surah_number'] as int,
      ayahNumber: map['ayah_number'] as int,
      pageNumber: map['page_number'] as int,
      type: map['type'] as String,
    );
  }
}
