/// Represents a rare or difficult vocabulary word in the Holy Quran (غريب القرآن)
/// with verified lexical meanings, roots, context, and rhetorical benefits.
class QuranVocabularyWord {
  final String id;
  final String word; // Word with Tashkeel as in Mushaf (e.g. عَسْعَسَ)
  final String root; // Arabic root (e.g. ع-س-س)
  final String meaning; // Precise contextual meaning
  final int surahId;
  final String surahName;
  final int ayahNumber;
  final int pageNumber;
  final String ayahSnippet; // The verse containing the word
  final String? linguisticBenefit; // لطيفة بيانية أو لغوية
  final String source; // e.g. السراج في غريب القرآن، مفردات الراغب

  const QuranVocabularyWord({
    required this.id,
    required this.word,
    required this.root,
    required this.meaning,
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.pageNumber,
    required this.ayahSnippet,
    this.linguisticBenefit,
    this.source = 'السراج في بيان غريب القرآن',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'root': root,
      'meaning': meaning,
      'surahId': surahId,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'pageNumber': pageNumber,
      'ayahSnippet': ayahSnippet,
      'linguisticBenefit': linguisticBenefit,
      'source': source,
    };
  }
}
