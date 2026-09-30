/// Utility class for normalizing Arabic text for search purposes.
class ArabicNormalizer {
  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');
  static final RegExp _quranicAnnotationsRegex = RegExp(r'[\u0610-\u061A\u06D6-\u06ED]');
  static final RegExp _alefRegex = RegExp(r'[إأآٱ]');

  /// Normalizes Arabic text by removing tashkeel/diacritics and unifying letters.
  static String normalize(String text) {
    return text
        // Remove diacritics / tashkeel
        .replaceAll(_diacriticsRegex, '')
        // Remove Quranic annotation signs
        .replaceAll(_quranicAnnotationsRegex, '')
        // Normalize Alef variants to bare Alef
        .replaceAll(_alefRegex, 'ا')
        // Normalize Yaa
        .replaceAll('ى', 'ي')
        // Normalize Taa Marbuta
        .replaceAll('ة', 'ه')
        // Normalize Tatweel
        .replaceAll('ـ', '')
        // Replace non-breaking space
        .replaceAll('\u00A0', ' ')
        .trim();
  }
}
