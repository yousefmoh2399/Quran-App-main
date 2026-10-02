/// Utility class for normalizing Arabic text for Quranic search and indexing.
class ArabicNormalizer {
  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u065F]');
  static final RegExp _quranicAnnotationsRegex = RegExp(r'[\u0610-\u061A\u06D6-\u06ED]');
  static final RegExp _alefRegex = RegExp(r'[إأآٱ]');

  /// Normalizes Arabic text by resolving Uthmanic orthography,
  /// removing tashkeel, and unifying letter variations.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    var s = text;

    // 1. Convert Uthmanic waw-dagger-alef to Alef (e.g. الصلوة -> الصلاة)
    s = s.replaceAll('و\u0670', 'ا');
    s = s.replaceAll('وٰ', 'ا');

    // 2. Small high Yaa (ۧ) -> ي (e.g. إبرٰهيۧم -> إبراهيم)
    s = s.replaceAll('\u06E7', 'ي');
    // Small high Waw (ۥ) -> و (e.g. داوۥد -> داوود)
    s = s.replaceAll('\u06E5', 'و');

    // 3. Remove diacritics / tashkeel FIRST (fatha, damma, kasra, sukun, shaddah)
    // while keeping dagger-alef (\u0670 / ٰ)
    s = s.replaceAll(_diacriticsRegex, '');

    // 4. Remove Quranic annotation signs & pause marks
    s = s.replaceAll(_quranicAnnotationsRegex, '');

    // 5. Handle words where dagger alef is pronounced but NEVER written in standard Arabic:
    // - Ilah: إلٰه / لٰه -> له
    s = s.replaceAll(RegExp(r'ل[ـ\u0640]?[\u0670ٰ]ه'), 'له');
    // - Demonstrative / Tanbih: هٰذ -> هذ, هٰؤ -> هؤ, ذٰل -> ذل, لٰك -> لك, لٰئ -> لئ
    s = s.replaceAll(RegExp(r'ه[ـ\u0640]?[\u0670ٰ]ذ'), 'هذ');
    s = s.replaceAll(RegExp(r'ه[ـ\u0640]?[\u0670ٰ]ؤ'), 'هؤ');
    s = s.replaceAll(RegExp(r'ذ[ـ\u0640]?[\u0670ٰ]ل'), 'ذل');
    s = s.replaceAll(RegExp(r'ل[ـ\u0640]?[\u0670ٰ]ك'), 'لك');
    s = s.replaceAll(RegExp(r'ل[ـ\u0640]?[\u0670ٰ]ئ'), 'لئ');
    // - Rahman: رحـٰمن -> رحمن
    s = s.replaceAll(RegExp(r'م[ـ\u0640]?[\u0670ٰ]ن'), 'من');

    // 6. Remaining dagger alef (\u0670 / ٰ) -> ا (e.g. إبراهيم, إسماعيل, السماوات, صادقين)
    s = s.replaceAll('\u0670', 'ا');
    s = s.replaceAll('ٰ', 'ا');

    // 7. Normalize Alef variants to bare Alef
    s = s.replaceAll(_alefRegex, 'ا');

    // 8. Standalone hamza followed by alef: ءا -> ا (ءادم -> ادم, ءامنوا -> امنوا)
    s = s.replaceAll('ءا', 'ا');

    // 9. Normalize Yaa / Alef Maqsura: ى -> ي
    s = s.replaceAll('ى', 'ي');

    // 10. Normalize Taa Marbuta: ة -> ه
    s = s.replaceAll('ة', 'ه');

    // 11. Normalize Tatweel: ـ -> ''
    s = s.replaceAll('ـ', '');

    // 12. Modern common misspellings or phonetics
    s = s.replaceAll('رحمان', 'رحمن');
    s = s.replaceAll('الاه', 'اله');
    s = s.replaceAll('هاذا', 'هذا');
    s = s.replaceAll('هاذه', 'هذه');
    s = s.replaceAll('هاؤلاء', 'هؤلاء');
    s = s.replaceAll('ذالك', 'ذلك');
    s = s.replaceAll('لاكن', 'لكن');

    // 13. Unify whitespaces
    s = s.replaceAll('\u00A0', ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    return s.trim();
  }

  /// Generates normalized search variants including common Quranic/modern spelling alternatives.
  static List<String> generateSearchVariants(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return [];

    final variants = <String>{normalized};

    // Add common variants where modern Arabic and Uthmanic script diverge
    if (normalized.contains('سماوات')) {
      variants.add(normalized.replaceAll('سماوات', 'سموات'));
    } else if (normalized.contains('سموات')) {
      variants.add(normalized.replaceAll('سموات', 'سماوات'));
    }

    if (normalized.contains('داوود')) {
      variants.add(normalized.replaceAll('داوود', 'داود'));
    } else if (normalized.contains('داود')) {
      variants.add(normalized.replaceAll('داود', 'داوود'));
    }

    if (normalized.contains('الصلاه')) {
      variants.add(normalized.replaceAll('الصلاه', 'الصلوه'));
    } else if (normalized.contains('الصلوه')) {
      variants.add(normalized.replaceAll('الصلوه', 'الصلاه'));
    }

    if (normalized.contains('الزكاه')) {
      variants.add(normalized.replaceAll('الزكاه', 'الزكوه'));
    } else if (normalized.contains('الزكوه')) {
      variants.add(normalized.replaceAll('الزكوه', 'الزكاه'));
    }

    if (normalized.contains('ابراهيم')) {
      variants.add(normalized.replaceAll('ابراهيم', 'ابرهم'));
    } else if (normalized.contains('ابرهم')) {
      variants.add(normalized.replaceAll('ابرهم', 'ابراهيم'));
    }

    if (normalized.contains('اسماعيل')) {
      variants.add(normalized.replaceAll('اسماعيل', 'اسمعيل'));
    } else if (normalized.contains('اسمعيل')) {
      variants.add(normalized.replaceAll('اسمعيل', 'اسماعيل'));
    }

    if (normalized.contains('اسحاق')) {
      variants.add(normalized.replaceAll('اسحاق', 'اسحق'));
    } else if (normalized.contains('اسحق')) {
      variants.add(normalized.replaceAll('اسحق', 'اسحاق'));
    }

    if (normalized.contains('هارون')) {
      variants.add(normalized.replaceAll('هارون', 'هرون'));
    } else if (normalized.contains('هرون')) {
      variants.add(normalized.replaceAll('هرون', 'هارون'));
    }

    if (normalized.contains('سليمان')) {
      variants.add(normalized.replaceAll('سليمان', 'سليمن'));
    } else if (normalized.contains('سليمن')) {
      variants.add(normalized.replaceAll('سليمن', 'سليمان'));
    }

    // Hamza variants (e.g. هؤلاء <-> هولاء, شيء <-> شيئ <-> شي)
    if (normalized.contains('هؤلاء')) {
      variants.add(normalized.replaceAll('هؤلاء', 'هولاء'));
    } else if (normalized.contains('هولاء')) {
      variants.add(normalized.replaceAll('هولاء', 'هؤلاء'));
    }

    if (normalized.contains('ء')) {
      variants.add(normalized.replaceAll('ء', ''));
    }

    return variants.toList();
  }
}
