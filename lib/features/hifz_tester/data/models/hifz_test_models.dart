import 'package:flutter/material.dart';

/// Test mode variations for the Quran Memorization Tester
enum HifzTestMode {
  /// Hide a key word/phrase from an Ayah and choose the correct missing word
  fillBlank,

  /// Display an Ayah and ask what the next Ayah begins with or is
  nextAyah,

  /// Present an Ayah or passage and ask which Surah it belongs to
  surahIdentify,

  /// Challenge verbal similarities and scholar mnemonic rules
  mutashabihat,
}

extension HifzTestModeExtension on HifzTestMode {
  String get titleAr {
    switch (this) {
      case HifzTestMode.fillBlank:
        return 'إكمال الفراغ القرآني';
      case HifzTestMode.nextAyah:
        return 'تحدي الآية التالية';
      case HifzTestMode.surahIdentify:
        return 'من أي سورة؟';
      case HifzTestMode.mutashabihat:
        return 'تحدي المتشابهات اللفظية';
    }
  }

  String get descriptionAr {
    switch (this) {
      case HifzTestMode.fillBlank:
        return 'تحديد الكلمة المحجوبة في نص الآية بدقة رسم المصحف';
      case HifzTestMode.nextAyah:
        return 'استحضار مطلع الآية التالية واختبار ترابط السورة';
      case HifzTestMode.surahIdentify:
        return 'معرفة اسم السورة وموضع الآية وترتيبها';
      case HifzTestMode.mutashabihat:
        return 'ضبط الفروق بين المواضع المتشابهة بقواعد السلف';
    }
  }

  IconData get icon {
    switch (this) {
      case HifzTestMode.fillBlank:
        return Icons.edit_note_rounded;
      case HifzTestMode.nextAyah:
        return Icons.skip_next_rounded;
      case HifzTestMode.surahIdentify:
        return Icons.menu_book_rounded;
      case HifzTestMode.mutashabihat:
        return Icons.compare_arrows_rounded;
    }
  }
}

/// Difficulty settings
enum HifzDifficulty {
  easy,
  medium,
  hard,
}

extension HifzDifficultyExtension on HifzDifficulty {
  String get labelAr {
    switch (this) {
      case HifzDifficulty.easy:
        return 'مبتدئ / ميسّر';
      case HifzDifficulty.medium:
        return 'متوسط';
      case HifzDifficulty.hard:
        return 'متقن / كتاتيب';
    }
  }

  String get shortLabel {
    switch (this) {
      case HifzDifficulty.easy:
        return 'ميسّر';
      case HifzDifficulty.medium:
        return 'متوسط';
      case HifzDifficulty.hard:
        return 'متقن';
    }
  }
}

/// Scope of testing
enum HifzScopeType {
  singleSurah,
  juz,
  entireQuran,
  mutashabihatOnly,
}

extension HifzScopeTypeExtension on HifzScopeType {
  String get titleAr {
    switch (this) {
      case HifzScopeType.singleSurah:
        return 'سورة محددة';
      case HifzScopeType.juz:
        return 'جزء من القرآن (1-30)';
      case HifzScopeType.entireQuran:
        return 'كامل المصحف الشريف';
      case HifzScopeType.mutashabihatOnly:
        return 'بنك المتشابهات المعتمد';
    }
  }
}

/// Individual question generated for a Hifz test session
class HifzQuestion {
  final String id;
  final HifzTestMode mode;
  final String prompt;
  final String ayahText;
  final String displayText;
  final String? hiddenWord;
  final List<String> options;
  final int correctAnswerIndex;
  final String surahName;
  final int surahId;
  final int ayahNumber;
  final String? tafsir;
  final String? ruleExplanation;

  const HifzQuestion({
    required this.id,
    required this.mode,
    required this.prompt,
    required this.ayahText,
    required this.displayText,
    this.hiddenWord,
    required this.options,
    required this.correctAnswerIndex,
    required this.surahName,
    required this.surahId,
    required this.ayahNumber,
    this.tafsir,
    this.ruleExplanation,
  });

  String get correctAnswer => options[correctAnswerIndex];
}

/// Test Session Results Summary
class HifzTestResult {
  final int totalQuestions;
  final int correctAnswers;
  final Duration duration;
  final List<HifzQuestion> questions;
  final List<int> userAnswers;

  const HifzTestResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.duration,
    required this.questions,
    required this.userAnswers,
  });

  int get wrongAnswers => totalQuestions - correctAnswers;

  double get accuracyRate =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) : 0.0;

  int get accuracyPercentage => (accuracyRate * 100).round();

  String get gradeTitle {
    if (accuracyPercentage >= 95) return 'حافظ متقن كالسهم 🏹';
    if (accuracyPercentage >= 80) return 'ممتاز ومتقن 🌟';
    if (accuracyPercentage >= 65) return 'جيد جداً ومجتهد 📖';
    if (accuracyPercentage >= 50) return 'يحتاج مراجعة وتثبيت 🤲';
    return 'بداية طيبة، داوم على التكرار 🌱';
  }

  String get gradeDescription {
    if (accuracyPercentage >= 95) {
      return 'ما شاء الله تبارك الله، حفظك متين وثابت كالجبال الرواسي. هنيئاً لك هذا الإتقان!';
    }
    if (accuracyPercentage >= 80) {
      return 'أداء رائع جداً وثبات متميز، مع تثبيت قليل للمواضع الدقيقة تصبح من المتقنين كالسهم.';
    }
    if (accuracyPercentage >= 65) {
      return 'حفظ طيب، ننصحك بمراجعة الآيات التي أخطأت فيها وتكرار السورة مرتين على الأقل.';
    }
    return 'لا تيأس، إن القرآن عزيز ويحتاج تعاهداً مستمراً. راجع أخطاءك وأعد الاختبار لتثبيته.';
  }

  List<int> get incorrectQuestionIndices {
    final list = <int>[];
    for (int i = 0; i < questions.length; i++) {
      if (i >= userAnswers.length ||
          userAnswers[i] != questions[i].correctAnswerIndex) {
        list.add(i);
      }
    }
    return list;
  }
}
