import 'dart:math';
import '../../../../core/data/models/ayah_entity.dart';
import '../../../../core/data/models/surah_entity.dart';
import '../../../../core/data/repositories/quran_repository.dart';
import '../models/hifz_test_models.dart';
import '../models/mutashabihat_entry.dart';

/// Offline Algorithmic Generator for Quran Memorization Questions.
/// Generates varied, authentic questions with zero internet connection.
class HifzQuestionGenerator {
  final QuranRepository _quranRepository;
  final Random _random;

  HifzQuestionGenerator({
    QuranRepository? quranRepository,
    Random? random,
  })  : _quranRepository = quranRepository ?? QuranRepository(),
        _random = random ?? Random();

  /// Curated Quranic fallback words with Tashkeel for generating natural distractors
  static const List<String> _quranicKeywordsPool = [
    'عَلِيمٌ',
    'حَكِيمٌ',
    'غَفُورٌ',
    'رَّحِيمٌ',
    'خَبِيرٌ',
    'بَصِيرٌ',
    'قَدِيرٌ',
    'تَوَّابٌ',
    'عَظِيمٌ',
    'كَرِيمٌ',
    'مُّبِينٌ',
    'شَكُورٌ',
    'حَلِيمٌ',
    'عَزِيزٌ',
    'سَمِيعٌ',
    'مُّهْتَدُونَ',
    'ظَالِمُونَ',
    'مُفْلِحُونَ',
    'كَافِرُونَ',
    'مُؤْمِنُونَ',
    'يَعْلَمُونَ',
    'يَعْقِلُونَ',
    'يَتَفَكَّرُونَ',
    'يَتَّقُونَ',
    'يَشْكُرُونَ',
    'يَسْمَعُونَ',
  ];

  /// Stop-words to avoid blanking out when possible
  static const Set<String> _commonStopWords = {
    'في', 'من', 'عن', 'على', 'إلى', 'مع', 'أو', 'ثم', 'هو', 'هي', 'ما', 'لا',
    'إن', 'أن', 'إنما', 'بل', 'كل', 'إذا', 'إذ', 'قد', 'بلى', 'حتى',
  };

  /// Clean word by removing non-alphabetic characters / verse markers
  String cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\u0621-\u064A\u064B-\u065F\u0670]'), '').trim();
  }

  /// Strip Tashkeel for comparison purposes
  String stripTashkeel(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
  }

  /// Generates a complete set of [count] questions based on the requested mode and scope
  Future<List<HifzQuestion>> generateQuestions({
    required HifzTestMode mode,
    required HifzScopeType scope,
    SurahEntity? targetSurah,
    int? targetJuz,
    int count = 10,
    HifzDifficulty difficulty = HifzDifficulty.medium,
    List<SurahEntity>? preloadedSurahs,
    List<AyahEntity>? preloadedAyahs,
  }) async {
    final questions = <HifzQuestion>[];

    // If Mutashabihat test mode is chosen, pull directly from the Mutashabihat repository
    if (mode == HifzTestMode.mutashabihat || scope == HifzScopeType.mutashabihatOnly) {
      return generateMutashabihatQuestions(count: count);
    }

    // Load Surahs and Ayahs according to scope
    List<SurahEntity> surahs = preloadedSurahs ?? [];
    if (surahs.isEmpty) {
      try {
        surahs = await _quranRepository.getSurahs();
      } catch (_) {
        // Fallback for tests or missing DB
        surahs = _getFallbackSurahs();
      }
    }

    if (surahs.isEmpty) {
      return generateMutashabihatQuestions(count: count);
    }

    // Determine candidate Surahs
    List<SurahEntity> candidateSurahs;
    if (scope == HifzScopeType.singleSurah && targetSurah != null) {
      candidateSurahs = [targetSurah];
    } else if (scope == HifzScopeType.juz && targetJuz != null) {
      // Find surahs in that Juz
      candidateSurahs = _filterSurahsByJuz(surahs, targetJuz);
      if (candidateSurahs.isEmpty) candidateSurahs = surahs;
    } else {
      candidateSurahs = surahs;
    }

    // Cache of ayahs by surah ID
    final Map<int, List<AyahEntity>> ayahsBySurah = {};
    if (preloadedAyahs != null && preloadedAyahs.isNotEmpty) {
      for (final a in preloadedAyahs) {
        ayahsBySurah.putIfAbsent(a.surahId, () => []).add(a);
      }
    }

    int attempts = 0;
    final int maxAttempts = count * 4;

    while (questions.length < count && attempts < maxAttempts) {
      attempts++;
      final surah = candidateSurahs[_random.nextInt(candidateSurahs.length)];

      List<AyahEntity> surahAyahs = ayahsBySurah[surah.id] ?? [];
      if (surahAyahs.isEmpty) {
        try {
          surahAyahs = await _quranRepository.getAyahs(surah.id);
          ayahsBySurah[surah.id] = surahAyahs;
        } catch (_) {
          // fallback
          surahAyahs = _getFallbackAyahsForSurah(surah.id);
          ayahsBySurah[surah.id] = surahAyahs;
        }
      }

      if (surahAyahs.isEmpty) continue;

      HifzQuestion? q;
      switch (mode) {
        case HifzTestMode.fillBlank:
          q = _generateFillBlankQuestion(
            surahAyahs: surahAyahs,
            surah: surah,
            difficulty: difficulty,
            questionId: 'fb_${questions.length + 1}',
          );
          break;
        case HifzTestMode.nextAyah:
          q = _generateNextAyahQuestion(
            surahAyahs: surahAyahs,
            surah: surah,
            allSurahs: surahs,
            ayahsBySurah: ayahsBySurah,
            difficulty: difficulty,
            questionId: 'na_${questions.length + 1}',
          );
          break;
        case HifzTestMode.surahIdentify:
          q = _generateSurahIdentifyQuestion(
            surahAyahs: surahAyahs,
            surah: surah,
            allSurahs: surahs,
            questionId: 'si_${questions.length + 1}',
          );
          break;
        case HifzTestMode.mutashabihat:
          // Handled separately above
          break;
      }

      if (q != null) {
        // Prevent duplicate questions in same session
        final alreadyExists = questions.any((existing) => existing.ayahText == q!.ayahText);
        if (!alreadyExists) {
          questions.add(q);
        }
      }
    }

    // If still short of questions, fill remaining with Mutashabihat
    if (questions.length < count) {
      final additional = generateMutashabihatQuestions(count: count - questions.length);
      questions.addAll(additional);
    }

    return questions;
  }

  /// Generates questions for the Fill-in-the-Blank mode
  HifzQuestion? _generateFillBlankQuestion({
    required List<AyahEntity> surahAyahs,
    required SurahEntity surah,
    required HifzDifficulty difficulty,
    required String questionId,
  }) {
    // Pick an ayah with at least 5 words
    final eligibleAyahs = surahAyahs.where((a) {
      final words = a.textAr.split(RegExp(r'\s+'));
      return words.length >= 4;
    }).toList();

    if (eligibleAyahs.isEmpty) return null;
    final ayah = eligibleAyahs[_random.nextInt(eligibleAyahs.length)];
    final rawWords = ayah.textAr.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (rawWords.length < 3) return null;

    // Filter candidate words to hide
    final candidateIndices = <int>[];
    for (int i = 0; i < rawWords.length; i++) {
      final clean = cleanWord(rawWords[i]);
      final stripped = stripTashkeel(clean);
      if (stripped.length >= 3 && !_commonStopWords.contains(stripped)) {
        candidateIndices.add(i);
      }
    }

    int targetIndex;
    if (candidateIndices.isNotEmpty) {
      if (difficulty == HifzDifficulty.hard) {
        // Prefer the last word / rhyme word in hard mode
        final lastCandidate = candidateIndices.lastWhere(
          (idx) => idx >= rawWords.length - 2,
          orElse: () => candidateIndices.last,
        );
        targetIndex = lastCandidate;
      } else {
        targetIndex = candidateIndices[_random.nextInt(candidateIndices.length)];
      }
    } else {
      targetIndex = rawWords.length - 1;
    }

    final targetWord = cleanWord(rawWords[targetIndex]);
    if (targetWord.isEmpty) return null;

    // Create display text with hidden blank
    final displayWords = List<String>.from(rawWords);
    displayWords[targetIndex] = '﴿ ........ ﴾';
    final displayText = displayWords.join(' ');

    // Gather distractors
    final distractors = <String>{};

    // 1. Other words in the same Surah
    for (final otherAyah in surahAyahs) {
      if (distractors.length >= 3) break;
      final otherWords = otherAyah.textAr.split(RegExp(r'\s+'));
      for (final w in otherWords) {
        final cw = cleanWord(w);
        if (cw.isNotEmpty &&
            cw != targetWord &&
            stripTashkeel(cw) != stripTashkeel(targetWord) &&
            cw.length >= 3) {
          distractors.add(cw);
          if (distractors.length >= 3) break;
        }
      }
    }

    // 2. Fallback to Quranic keywords pool
    final shuffledPool = List<String>.from(_quranicKeywordsPool)..shuffle(_random);
    for (final kw in shuffledPool) {
      if (distractors.length >= 3) break;
      if (kw != targetWord && stripTashkeel(kw) != stripTashkeel(targetWord)) {
        distractors.add(kw);
      }
    }

    final optionsList = <String>[targetWord, ...distractors.take(3)]..shuffle(_random);
    final correctIdx = optionsList.indexOf(targetWord);

    return HifzQuestion(
      id: questionId,
      mode: HifzTestMode.fillBlank,
      prompt: 'أكمل الكلمة المحجوبة في قوله تعالى من سورة ${surah.nameAr}:',
      ayahText: ayah.textAr,
      displayText: displayText,
      hiddenWord: targetWord,
      options: optionsList,
      correctAnswerIndex: correctIdx,
      surahName: surah.nameAr,
      surahId: surah.id,
      ayahNumber: ayah.ayahNumber,
      tafsir: ayah.tafsirMuyassar,
      ruleExplanation: 'الآية الكريمة: ﴿${ayah.textAr}﴾ [${surah.nameAr}: ${ayah.ayahNumber}]',
    );
  }

  /// Generates questions for the Next Ayah Challenge
  HifzQuestion? _generateNextAyahQuestion({
    required List<AyahEntity> surahAyahs,
    required SurahEntity surah,
    required List<SurahEntity> allSurahs,
    required Map<int, List<AyahEntity>> ayahsBySurah,
    required HifzDifficulty difficulty,
    required String questionId,
  }) {
    if (surahAyahs.length < 2) return null;

    // Pick an ayah that has a next ayah (ayahNumber < total)
    final maxIndex = surahAyahs.length - 1;
    final currentIdx = _random.nextInt(maxIndex);
    final currentAyah = surahAyahs[currentIdx];
    final nextAyah = surahAyahs[currentIdx + 1];

    final correctAnswerText = _formatAyahChoice(nextAyah.textAr);

    // Collect 3 distractor ayahs
    final distractorTexts = <String>{};

    // Try other ayahs from the same Surah first
    final candidateIndices = List<int>.generate(surahAyahs.length, (i) => i)
      ..remove(currentIdx)
      ..remove(currentIdx + 1)
      ..shuffle(_random);

    for (final idx in candidateIndices) {
      if (distractorTexts.length >= 3) break;
      final text = _formatAyahChoice(surahAyahs[idx].textAr);
      if (text != correctAnswerText) {
        distractorTexts.add(text);
      }
    }

    // If still need distractors, draw from another Surah
    int fallbackAttempt = 0;
    while (distractorTexts.length < 3 && fallbackAttempt < 10) {
      fallbackAttempt++;
      final randomSurah = allSurahs[_random.nextInt(allSurahs.length)];
      final otherAyahs = ayahsBySurah[randomSurah.id] ?? _getFallbackAyahsForSurah(randomSurah.id);
      if (otherAyahs.isNotEmpty) {
        final picked = otherAyahs[_random.nextInt(otherAyahs.length)];
        final text = _formatAyahChoice(picked.textAr);
        if (text != correctAnswerText) {
          distractorTexts.add(text);
        }
      }
    }

    if (distractorTexts.length < 3) return null;

    final options = <String>[correctAnswerText, ...distractorTexts.take(3)]..shuffle(_random);
    final correctIdx = options.indexOf(correctAnswerText);

    return HifzQuestion(
      id: questionId,
      mode: HifzTestMode.nextAyah,
      prompt: 'ما هي الآية التالية لقوله تعالى في سورة ${surah.nameAr}؟',
      ayahText: currentAyah.textAr,
      displayText: '﴿ ${currentAyah.textAr} ﴾',
      options: options,
      correctAnswerIndex: correctIdx,
      surahName: surah.nameAr,
      surahId: surah.id,
      ayahNumber: currentAyah.ayahNumber,
      tafsir: nextAyah.tafsirMuyassar,
      ruleExplanation: 'الآية التالية هي: ﴿${nextAyah.textAr}﴾ [الآية ${nextAyah.ayahNumber}]',
    );
  }

  /// Formats an Ayah text to fit cleanly as a multiple-choice button
  String _formatAyahChoice(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 12) {
      return text.trim();
    }
    return '${words.take(10).join(' ')} ...';
  }

  /// Generates questions for Surah Identification
  HifzQuestion? _generateSurahIdentifyQuestion({
    required List<AyahEntity> surahAyahs,
    required SurahEntity surah,
    required List<SurahEntity> allSurahs,
    required String questionId,
  }) {
    if (surahAyahs.isEmpty) return null;
    final ayah = surahAyahs[_random.nextInt(surahAyahs.length)];

    final correctSurahName = 'سورة ${surah.nameAr}';
    final distractors = <String>{};

    final otherSurahs = allSurahs.where((s) => s.id != surah.id).toList()..shuffle(_random);
    for (final s in otherSurahs) {
      distractors.add('سورة ${s.nameAr}');
      if (distractors.length >= 3) break;
    }

    final options = <String>[correctSurahName, ...distractors]..shuffle(_random);
    final correctIdx = options.indexOf(correctSurahName);

    return HifzQuestion(
      id: questionId,
      mode: HifzTestMode.surahIdentify,
      prompt: 'في أي سورة من كتاب الله وردت هذه الآية الكريمة؟',
      ayahText: ayah.textAr,
      displayText: '﴿ ${ayah.textAr} ﴾',
      options: options,
      correctAnswerIndex: correctIdx,
      surahName: surah.nameAr,
      surahId: surah.id,
      ayahNumber: ayah.ayahNumber,
      tafsir: ayah.tafsirMuyassar,
      ruleExplanation: 'هذه الآية الكريمة في سورة ${surah.nameAr}، الآية رقم (${ayah.ayahNumber}).',
    );
  }

  /// Generates questions based on the authentic Mutashabihat repository
  List<HifzQuestion> generateMutashabihatQuestions({int count = 10}) {
    final list = List<MutashabihatEntry>.from(MutashabihatEntry.authenticMutashabihat)
      ..shuffle(_random);
    final chosen = list.take(count).toList();

    final questions = <HifzQuestion>[];
    for (int i = 0; i < chosen.length; i++) {
      final entry = chosen[i];
      // Generate question variant asking to distinguish verse 1 vs verse 2
      final question = _buildMutashabihatQuestion(entry, 'mut_${i + 1}');
      questions.add(question);
    }
    return questions;
  }

  HifzQuestion _buildMutashabihatQuestion(MutashabihatEntry entry, String id) {
    final isAskingVerse1 = _random.nextBool();
    final targetSurahName = isAskingVerse1 ? entry.surah1Name : entry.surah2Name;
    final targetAyahNum = isAskingVerse1 ? entry.ayah1Number : entry.ayah2Number;
    final targetText = isAskingVerse1 ? entry.verse1Text : entry.verse2Text;
    final otherText = isAskingVerse1 ? entry.verse2Text : entry.verse1Text;

    final prompt = 'كيف ضُبط هذا الموضع في سورة $targetSurahName؟';
    final snippet1 = _formatAyahChoice(targetText);
    final snippet2 = _formatAyahChoice(otherText);

    final otherEntries = MutashabihatEntry.authenticMutashabihat
        .where((e) => e.id != entry.id)
        .toList()
      ..shuffle(_random);

    final distractor3 = _formatAyahChoice(
      otherEntries.isNotEmpty ? otherEntries.first.verse1Text : 'وَاللَّهُ عَلِيمٌ حَكِيمٌ',
    );
    final distractor4 = _formatAyahChoice(
      otherEntries.length > 1 ? otherEntries[1].verse2Text : 'إِنَّ فِي ذَٰلِكَ لَآيَةً لِّلْمُؤْمِنِينَ',
    );

    final rawOptions = <String>{snippet1, snippet2, distractor3, distractor4};
    while (rawOptions.length < 4) {
      rawOptions.add('وَاللَّهُ غَفُورٌ رَّحِيمٌ (${rawOptions.length})');
    }

    final options = rawOptions.toList()..shuffle(_random);
    final correctIdx = options.indexOf(snippet1);

    return HifzQuestion(
      id: id,
      mode: HifzTestMode.mutashabihat,
      prompt: prompt,
      ayahText: targetText,
      displayText: '﴿ $targetText ﴾',
      options: options,
      correctAnswerIndex: correctIdx,
      surahName: targetSurahName,
      surahId: isAskingVerse1 ? entry.surah1Id : entry.surah2Id,
      ayahNumber: targetAyahNum,
      tafsir: entry.keyDifference,
      ruleExplanation: '${entry.ruleMnemonic}\nالمصدر: ${entry.referenceBook}',
    );
  }

  /// Helper to filter Surahs by Juz number (1 to 30)
  List<SurahEntity> _filterSurahsByJuz(List<SurahEntity> surahs, int juz) {
    if (juz == 30) {
      // Juz Amma: Surah 78 to 114
      return surahs.where((s) => s.id >= 78 && s.id <= 114).toList();
    } else if (juz == 29) {
      // Juz Tabarak: Surah 67 to 77
      return surahs.where((s) => s.id >= 67 && s.id <= 77).toList();
    } else if (juz == 1) {
      return surahs.where((s) => s.id <= 2).toList();
    } else {
      // General proportional distribution across the 114 Surahs
      final approxStart = ((juz - 1) * 3.8).round().clamp(1, 114);
      final approxEnd = (juz * 3.8 + 2).round().clamp(1, 114);
      return surahs.where((s) => s.id >= approxStart && s.id <= approxEnd).toList();
    }
  }

  /// Embedded fallback Surahs for testing or environments where SQLite factory is mock
  List<SurahEntity> _getFallbackSurahs() {
    return const [
      SurahEntity(id: 1, nameAr: 'الفاتحة', nameEn: 'Al-Fatihah', transliteration: 'Al-Fatihah', type: 'Meccan', totalVerses: 7),
      SurahEntity(id: 2, nameAr: 'البقرة', nameEn: 'Al-Baqarah', transliteration: 'Al-Baqarah', type: 'Medinan', totalVerses: 286),
      SurahEntity(id: 3, nameAr: 'آل عمران', nameEn: 'Ali \'Imran', transliteration: 'Ali \'Imran', type: 'Medinan', totalVerses: 200),
      SurahEntity(id: 112, nameAr: 'الإخلاص', nameEn: 'Al-Ikhlas', transliteration: 'Al-Ikhlas', type: 'Meccan', totalVerses: 4),
      SurahEntity(id: 113, nameAr: 'الفلق', nameEn: 'Al-Falaq', transliteration: 'Al-Falaq', type: 'Meccan', totalVerses: 5),
      SurahEntity(id: 114, nameAr: 'الناس', nameEn: 'An-Nas', transliteration: 'An-Nas', type: 'Meccan', totalVerses: 6),
    ];
  }

  /// Embedded fallback Ayahs for testing or fallback
  List<AyahEntity> _getFallbackAyahsForSurah(int surahId) {
    if (surahId == 1) {
      return const [
        AyahEntity(id: 1, surahId: 1, ayahNumber: 1, textAr: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', textSearch: 'بسم الله الرحمن الرحيم'),
        AyahEntity(id: 2, surahId: 1, ayahNumber: 2, textAr: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', textSearch: 'الحمد لله رب العالمين'),
        AyahEntity(id: 3, surahId: 1, ayahNumber: 3, textAr: 'الرَّحْمَٰنِ الرَّحِيمِ', textSearch: 'الرحمن الرحيم'),
        AyahEntity(id: 4, surahId: 1, ayahNumber: 4, textAr: 'مَالِكِ يَوْمِ الدِّينِ', textSearch: 'مالك يوم الدين'),
        AyahEntity(id: 5, surahId: 1, ayahNumber: 5, textAr: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', textSearch: 'إياك نعبد وإياك نستعين'),
        AyahEntity(id: 6, surahId: 1, ayahNumber: 6, textAr: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', textSearch: 'اهدنا الصراط المستقيم'),
        AyahEntity(id: 7, surahId: 1, ayahNumber: 7, textAr: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', textSearch: 'صراط الذين أنعمت عليهم غير المغضوب عليهم ولا الضالين'),
      ];
    } else if (surahId == 112) {
      return const [
        AyahEntity(id: 6222, surahId: 112, ayahNumber: 1, textAr: 'قُلْ هُوَ اللَّهُ أَحَدٌ', textSearch: 'قل هو الله أحد'),
        AyahEntity(id: 6223, surahId: 112, ayahNumber: 2, textAr: 'اللَّهُ الصَّمَدُ', textSearch: 'الله الصمد'),
        AyahEntity(id: 6224, surahId: 112, ayahNumber: 3, textAr: 'لَمْ يَلِدْ وَلَمْ يُولَدْ', textSearch: 'لم يلد ولم يولد'),
        AyahEntity(id: 6225, surahId: 112, ayahNumber: 4, textAr: 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ', textSearch: 'ولم يكن له كفوا أحد'),
      ];
    }
    return const [];
  }
}
