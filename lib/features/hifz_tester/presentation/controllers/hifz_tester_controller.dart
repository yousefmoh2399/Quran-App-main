import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/surah_entity.dart';
import '../../../../core/data/repositories/quran_repository.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/hifz_test_models.dart';
import '../../data/models/mutashabihat_entry.dart';
import '../../data/services/hifz_question_generator.dart';

enum HifzViewState {
  setup,
  testing,
  results,
  mutashabihatGuide,
}

class HifzTesterController extends GetxController {
  final QuranRepository _quranRepository;
  final HifzQuestionGenerator _questionGenerator;

  HifzTesterController({
    QuranRepository? quranRepository,
    HifzQuestionGenerator? questionGenerator,
  })  : _quranRepository = quranRepository ?? QuranRepository(),
        _questionGenerator =
            questionGenerator ?? HifzQuestionGenerator(quranRepository: quranRepository);

  // View state
  final Rx<HifzViewState> viewState = HifzViewState.setup.obs;
  final RxBool isLoading = false.obs;

  // Configuration observables
  final Rx<HifzTestMode> selectedMode = HifzTestMode.fillBlank.obs;
  final Rx<HifzScopeType> selectedScope = HifzScopeType.singleSurah.obs;
  final Rx<HifzDifficulty> selectedDifficulty = HifzDifficulty.medium.obs;
  final RxInt questionCount = 10.obs;
  final Rxn<SurahEntity> selectedSurah = Rxn<SurahEntity>();
  final RxInt selectedJuz = 30.obs; // Default to Juz 'Amma

  // Surah list for dropdown
  final RxList<SurahEntity> surahs = <SurahEntity>[].obs;

  // Active Test Session
  final RxList<HifzQuestion> questions = <HifzQuestion>[].obs;
  final RxInt currentQuestionIndex = 0.obs;
  final RxInt selectedAnswerIndex = (-1).obs;
  final RxBool isAnswerRevealed = false.obs;
  final RxInt score = 0.obs;
  final RxInt streak = 0.obs;
  final RxList<int> userAnswers = <int>[].obs;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  final RxInt elapsedSeconds = 0.obs;
  Timer? _timer;

  // Mutashabihat browser search query & selected category
  final RxString mutashabihatSearchQuery = ''.obs;
  final RxString selectedCategory = 'الكل'.obs;

  // Final Result
  final Rxn<HifzTestResult> lastResult = Rxn<HifzTestResult>();

  @override
  void onInit() {
    super.onInit();
    _loadSurahs();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.onClose();
  }

  Future<void> _loadSurahs() async {
    try {
      final list = await _quranRepository.getSurahs();
      surahs.assignAll(list);
      if (surahs.isNotEmpty && selectedSurah.value == null) {
        // Default to Al-Baqarah (id: 2) or Al-Fatihah (id: 1)
        selectedSurah.value = surahs.length > 1 ? surahs[1] : surahs.first;
      }
    } catch (e) {
      debugPrint('Error loading surahs in HifzTesterController: $e');
    }
  }

  void initWithArguments({
    int? surahId,
    HifzTestMode? mode,
    HifzScopeType? scope,
  }) {
    if (mode != null) selectedMode.value = mode;
    if (scope != null) selectedScope.value = scope;
    if (surahId != null && surahs.isNotEmpty) {
      final found = surahs.firstWhereOrNull((s) => s.id == surahId);
      if (found != null) {
        selectedSurah.value = found;
        selectedScope.value = HifzScopeType.singleSurah;
      }
    }
  }

  // --- Configuration setters ---

  void setMode(HifzTestMode mode) {
    selectedMode.value = mode;
    if (mode == HifzTestMode.mutashabihat) {
      selectedScope.value = HifzScopeType.mutashabihatOnly;
    }
    AppHaptics.selection();
  }

  void setScope(HifzScopeType scope) {
    selectedScope.value = scope;
    if (scope == HifzScopeType.mutashabihatOnly) {
      selectedMode.value = HifzTestMode.mutashabihat;
    }
    AppHaptics.selection();
  }

  void setDifficulty(HifzDifficulty diff) {
    selectedDifficulty.value = diff;
    AppHaptics.selection();
  }

  void setQuestionCount(int count) {
    questionCount.value = count;
    AppHaptics.selection();
  }

  void setSurah(SurahEntity? surah) {
    selectedSurah.value = surah;
    AppHaptics.selection();
  }

  void setJuz(int juz) {
    selectedJuz.value = juz;
    AppHaptics.selection();
  }

  // --- Test flow ---

  Future<void> startTest() async {
    isLoading.value = true;
    AppHaptics.selection();

    try {
      final generated = await _questionGenerator.generateQuestions(
        mode: selectedMode.value,
        scope: selectedScope.value,
        targetSurah: selectedSurah.value,
        targetJuz: selectedJuz.value,
        count: questionCount.value,
        difficulty: selectedDifficulty.value,
        preloadedSurahs: surahs,
      );

      if (generated.isEmpty) {
        Get.snackbar(
          'تنبيه',
          'تعذر إنشاء أسئلة للنطاق المحدد، يرجى اختيار سورة أخرى أو نطاق أوسع',
          snackPosition: SnackPosition.BOTTOM,
        );
        isLoading.value = false;
        return;
      }

      questions.assignAll(generated);
      currentQuestionIndex.value = 0;
      selectedAnswerIndex.value = -1;
      isAnswerRevealed.value = false;
      score.value = 0;
      streak.value = 0;
      userAnswers.clear();

      _stopwatch.reset();
      _stopwatch.start();
      elapsedSeconds.value = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsedSeconds.value = _stopwatch.elapsed.inSeconds;
      });

      viewState.value = HifzViewState.testing;
    } catch (e) {
      debugPrint('Error starting Hifz test: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ غير متوقع أثناء إعداد الاختبار',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectOption(int index) {
    if (isAnswerRevealed.value) return;

    selectedAnswerIndex.value = index;
    isAnswerRevealed.value = true;
    userAnswers.add(index);

    final currentQ = currentQuestion;
    if (currentQ != null && index == currentQ.correctAnswerIndex) {
      score.value++;
      streak.value++;
      AppHaptics.itemCompleted();
    } else {
      streak.value = 0;
      AppHaptics.selection();
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex.value < questions.length - 1) {
      currentQuestionIndex.value++;
      selectedAnswerIndex.value = -1;
      isAnswerRevealed.value = false;
      AppHaptics.selection();
    } else {
      _finishTest();
    }
  }

  void _finishTest() {
    _timer?.cancel();
    _stopwatch.stop();

    lastResult.value = HifzTestResult(
      totalQuestions: questions.length,
      correctAnswers: score.value,
      duration: _stopwatch.elapsed,
      questions: List<HifzQuestion>.from(questions),
      userAnswers: List<int>.from(userAnswers),
    );

    viewState.value = HifzViewState.results;
    AppHaptics.itemCompleted();
  }

  void retryMistakes() {
    final result = lastResult.value;
    if (result == null) return;

    final wrongIndices = result.incorrectQuestionIndices;
    if (wrongIndices.isEmpty) {
      // Re-run full test if 100% correct
      startTest();
      return;
    }

    final mistakeQuestions = wrongIndices.map((i) => result.questions[i]).toList();
    questions.assignAll(mistakeQuestions);
    currentQuestionIndex.value = 0;
    selectedAnswerIndex.value = -1;
    isAnswerRevealed.value = false;
    score.value = 0;
    streak.value = 0;
    userAnswers.clear();

    _stopwatch.reset();
    _stopwatch.start();
    elapsedSeconds.value = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value = _stopwatch.elapsed.inSeconds;
    });

    viewState.value = HifzViewState.testing;
    AppHaptics.itemCompleted();
  }

  void returnToSetup() {
    _timer?.cancel();
    _stopwatch.stop();
    viewState.value = HifzViewState.setup;
    AppHaptics.selection();
  }

  void openMutashabihatGuide() {
    viewState.value = HifzViewState.mutashabihatGuide;
    AppHaptics.selection();
  }

  // --- Mutashabihat Guide Filtering ---

  List<MutashabihatEntry> get filteredMutashabihat {
    final query = mutashabihatSearchQuery.value.trim().toLowerCase();
    final cat = selectedCategory.value;

    return MutashabihatEntry.authenticMutashabihat.where((entry) {
      final matchesCategory = (cat == 'الكل' || entry.category == cat);
      if (!matchesCategory) return false;

      if (query.isEmpty) return true;
      return entry.title.toLowerCase().contains(query) ||
          entry.surah1Name.toLowerCase().contains(query) ||
          entry.surah2Name.toLowerCase().contains(query) ||
          entry.verse1Text.toLowerCase().contains(query) ||
          entry.verse2Text.toLowerCase().contains(query) ||
          entry.keyDifference.toLowerCase().contains(query) ||
          entry.ruleMnemonic.toLowerCase().contains(query);
    }).toList();
  }

  List<String> get mutashabihatCategories {
    final cats = MutashabihatEntry.authenticMutashabihat
        .map((e) => e.category)
        .toSet()
        .toList();
    return ['الكل', ...cats];
  }

  HifzQuestion? get currentQuestion {
    if (currentQuestionIndex.value >= 0 &&
        currentQuestionIndex.value < questions.length) {
      return questions[currentQuestionIndex.value];
    }
    return null;
  }
}
