import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/models/ayah_entity.dart';
import 'package:quran_app_android/core/data/models/surah_entity.dart';
import 'package:quran_app_android/features/hifz_tester/data/models/hifz_test_models.dart';
import 'package:quran_app_android/features/hifz_tester/data/models/mutashabihat_entry.dart';
import 'package:quran_app_android/features/hifz_tester/data/services/hifz_question_generator.dart';
import 'package:quran_app_android/features/hifz_tester/presentation/controllers/hifz_tester_controller.dart';
import 'package:quran_app_android/features/hifz_tester/presentation/widgets/hifz_setup_view.dart';
import 'package:quran_app_android/features/hifz_tester/presentation/widgets/hifz_testing_view.dart';
import 'package:quran_app_android/features/hifz_tester/presentation/widgets/hifz_result_view.dart';
import 'package:quran_app_android/features/hifz_tester/presentation/widgets/mutashabihat_browser_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<SurahEntity> sampleSurahs = [
    const SurahEntity(id: 1, nameAr: 'الفاتحة', nameEn: 'Al-Fatihah', transliteration: 'Al-Fatihah', type: 'Meccan', totalVerses: 7),
    const SurahEntity(id: 112, nameAr: 'الإخلاص', nameEn: 'Al-Ikhlas', transliteration: 'Al-Ikhlas', type: 'Meccan', totalVerses: 4),
    const SurahEntity(id: 113, nameAr: 'الفلق', nameEn: 'Al-Falaq', transliteration: 'Al-Falaq', type: 'Meccan', totalVerses: 5),
    const SurahEntity(id: 114, nameAr: 'الناس', nameEn: 'An-Nas', transliteration: 'An-Nas', type: 'Meccan', totalVerses: 6),
  ];

  final sampleAyahs = [
    const AyahEntity(id: 1, surahId: 1, ayahNumber: 1, textAr: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', textSearch: 'بسم الله الرحمن الرحيم'),
    const AyahEntity(id: 2, surahId: 1, ayahNumber: 2, textAr: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', textSearch: 'الحمد لله رب العالمين'),
    const AyahEntity(id: 3, surahId: 1, ayahNumber: 3, textAr: 'الرَّحْمَٰنِ الرَّحِيمِ', textSearch: 'الرحمن الرحيم'),
    const AyahEntity(id: 4, surahId: 1, ayahNumber: 4, textAr: 'مَالِكِ يَوْمِ الدِّينِ', textSearch: 'مالك يوم الدين'),
    const AyahEntity(id: 5, surahId: 1, ayahNumber: 5, textAr: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', textSearch: 'إياك نعبد وإياك نستعين'),
    const AyahEntity(id: 6, surahId: 1, ayahNumber: 6, textAr: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', textSearch: 'اهدنا الصراط المستقيم'),
    const AyahEntity(id: 7, surahId: 1, ayahNumber: 7, textAr: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', textSearch: 'صراط الذين أنعمت عليهم غير المغضوب عليهم ولا الضالين'),
  ];

  group('Mutashabihat Repository & Model Tests', () {
    test('MutashabihatEntry repository has verified entries with all fields', () {
      final list = MutashabihatEntry.authenticMutashabihat;
      expect(list.length, greaterThanOrEqualTo(10));

      for (final entry in list) {
        expect(entry.id.isNotEmpty, isTrue);
        expect(entry.title.isNotEmpty, isTrue);
        expect(entry.category.isNotEmpty, isTrue);
        expect(entry.surah1Name.isNotEmpty, isTrue);
        expect(entry.verse1Text.isNotEmpty, isTrue);
        expect(entry.surah2Name.isNotEmpty, isTrue);
        expect(entry.verse2Text.isNotEmpty, isTrue);
        expect(entry.keyDifference.isNotEmpty, isTrue);
        expect(entry.ruleMnemonic.isNotEmpty, isTrue);
        expect(entry.referenceBook.isNotEmpty, isTrue);
      }
    });
  });

  group('HifzTestModels and Grading Metrics Tests', () {
    test('HifzTestResult calculates correct percentages and grades', () {
      final questions = List.generate(
        10,
        (i) => HifzQuestion(
          id: 'q_$i',
          mode: HifzTestMode.fillBlank,
          prompt: 'سؤال $i',
          ayahText: 'نص الآية $i',
          displayText: 'عرض $i',
          options: const ['أ', 'ب', 'ج', 'د'],
          correctAnswerIndex: 0,
          surahName: 'الفاتحة',
          surahId: 1,
          ayahNumber: i + 1,
        ),
      );

      // 10/10 correct = 100%
      final resultPerfect = HifzTestResult(
        totalQuestions: 10,
        correctAnswers: 10,
        duration: const Duration(seconds: 45),
        questions: questions,
        userAnswers: List.filled(10, 0),
      );
      expect(resultPerfect.accuracyPercentage, 100);
      expect(resultPerfect.gradeTitle, contains('كالسهم'));
      expect(resultPerfect.incorrectQuestionIndices.isEmpty, isTrue);
      expect(resultPerfect.wrongAnswers, 0);

      // 8/10 correct = 80%
      final resultGood = HifzTestResult(
        totalQuestions: 10,
        correctAnswers: 8,
        duration: const Duration(minutes: 1),
        questions: questions,
        userAnswers: [0, 0, 0, 0, 0, 0, 0, 0, 1, 2],
      );
      expect(resultGood.accuracyPercentage, 80);
      expect(resultGood.gradeTitle, contains('ممتاز'));
      expect(resultGood.incorrectQuestionIndices, [8, 9]);
      expect(resultGood.wrongAnswers, 2);

      // 5/10 correct = 50%
      final resultReview = HifzTestResult(
        totalQuestions: 10,
        correctAnswers: 5,
        duration: const Duration(minutes: 2),
        questions: questions,
        userAnswers: [0, 0, 0, 0, 0, 1, 1, 1, 1, 1],
      );
      expect(resultReview.accuracyPercentage, 50);
      expect(resultReview.gradeTitle, contains('مراجعة'));
      expect(resultReview.incorrectQuestionIndices.length, 5);
    });
  });

  group('HifzQuestionGenerator Algorithmic Tests', () {
    final generator = HifzQuestionGenerator();

    test('generateMutashabihatQuestions generates non-empty 4-option questions', () {
      final questions = generator.generateMutashabihatQuestions(count: 5);
      expect(questions.length, 5);

      for (final q in questions) {
        expect(q.mode, HifzTestMode.mutashabihat);
        expect(q.options.length, 4);
        expect(q.correctAnswerIndex, inInclusiveRange(0, 3));
        expect(q.correctAnswer, q.options[q.correctAnswerIndex]);
        // All options must be distinct
        expect(q.options.toSet().length, 4);
        expect(q.ruleExplanation, isNotNull);
      }
    });

    test('generateQuestions for fillBlank mode hides a word and provides valid choices', () async {
      final questions = await generator.generateQuestions(
        mode: HifzTestMode.fillBlank,
        scope: HifzScopeType.singleSurah,
        targetSurah: sampleSurahs.first,
        count: 3,
        preloadedSurahs: sampleSurahs,
        preloadedAyahs: sampleAyahs,
      );

      expect(questions.isNotEmpty, isTrue);
      for (final q in questions) {
        expect(q.mode, HifzTestMode.fillBlank);
        expect(q.displayText, contains('﴿ ........ ﴾'));
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.correctAnswer, q.options[q.correctAnswerIndex]);
      }
    });

    test('generateQuestions for nextAyah mode sets next verse as correct option', () async {
      final questions = await generator.generateQuestions(
        mode: HifzTestMode.nextAyah,
        scope: HifzScopeType.singleSurah,
        targetSurah: sampleSurahs.first,
        count: 3,
        preloadedSurahs: sampleSurahs,
        preloadedAyahs: sampleAyahs,
      );

      expect(questions.isNotEmpty, isTrue);
      for (final q in questions) {
        expect(q.mode, HifzTestMode.nextAyah);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options.contains(q.correctAnswer), isTrue);
      }
    });

    test('generateQuestions for surahIdentify mode provides surah names choices', () async {
      final questions = await generator.generateQuestions(
        mode: HifzTestMode.surahIdentify,
        scope: HifzScopeType.singleSurah,
        targetSurah: sampleSurahs.first,
        count: 2,
        preloadedSurahs: sampleSurahs,
        preloadedAyahs: sampleAyahs,
      );

      expect(questions.isNotEmpty, isTrue);
      for (final q in questions) {
        expect(q.mode, HifzTestMode.surahIdentify);
        expect(q.correctAnswer, 'سورة الفاتحة');
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
      }
    });

    test('cleanWord preserves Alef Wasla (ٱ) and Tashkeel completely without truncation', () {
      expect(generator.cleanWord('ٱلرَّحْمَـٰنِ'), 'ٱلرَّحْمَـٰنِ');
      expect(generator.cleanWord('ٱللَّهِ'), 'ٱللَّهِ');
      expect(generator.cleanWord('ٱلْحَمْدُ'), 'ٱلْحَمْدُ');
      expect(generator.cleanWord('عَلِيمٌ ۗ'), 'عَلِيمٌ');
      expect(generator.cleanWord('﴿قُلْ﴾'), 'قُلْ');
    });

    test('generateQuestions for single surah strictly returns 100% questions from that surah only', () async {
      final questions = await generator.generateQuestions(
        mode: HifzTestMode.fillBlank,
        scope: HifzScopeType.singleSurah,
        targetSurah: sampleSurahs.first, // Al-Fatihah
        count: 10,
        preloadedSurahs: sampleSurahs,
        preloadedAyahs: sampleAyahs,
      );

      expect(questions.isNotEmpty, isTrue);
      for (final q in questions) {
        expect(q.surahId, 1, reason: 'Question ${q.id} must strictly be from Surah Al-Fatihah (id: 1)');
        expect(q.surahName, 'الفاتحة');
        expect(q.options.length, 4);
      }
    });

    test('generateQuestions for nextAyah in single surah strictly returns 100% questions from that surah', () async {
      final questions = await generator.generateQuestions(
        mode: HifzTestMode.nextAyah,
        scope: HifzScopeType.singleSurah,
        targetSurah: sampleSurahs.first, // Al-Fatihah
        count: 10,
        preloadedSurahs: sampleSurahs,
        preloadedAyahs: sampleAyahs,
      );

      expect(questions.isNotEmpty, isTrue);
      for (final q in questions) {
        expect(q.surahId, 1, reason: 'All questions must be from Surah 1');
        expect(q.surahName, 'الفاتحة');
      }
    });
  });

  group('HifzTesterController State Management Tests', () {
    late HifzTesterController controller;

    setUp(() {
      Get.reset();
      controller = HifzTesterController();
      controller.surahs.assignAll(sampleSurahs);
      controller.selectedSurah.value = sampleSurahs.first;
    });

    test('Initializes with default setup state and configuration setters work', () {
      expect(controller.viewState.value, HifzViewState.setup);
      expect(controller.selectedMode.value, HifzTestMode.fillBlank);

      controller.setMode(HifzTestMode.nextAyah);
      expect(controller.selectedMode.value, HifzTestMode.nextAyah);

      controller.setDifficulty(HifzDifficulty.hard);
      expect(controller.selectedDifficulty.value, HifzDifficulty.hard);

      controller.setQuestionCount(15);
      expect(controller.questionCount.value, 15);

      controller.setJuz(29);
      expect(controller.selectedJuz.value, 29);
    });

    test('Test session answering, streak, and completion flow', () {
      final mockQuestions = [
        const HifzQuestion(
          id: 'q1',
          mode: HifzTestMode.fillBlank,
          prompt: 'أكمل 1',
          ayahText: 'آية 1',
          displayText: 'عرض 1',
          options: ['خيار 0', 'خيار 1', 'خيار 2', 'خيار 3'],
          correctAnswerIndex: 1,
          surahName: 'الفاتحة',
          surahId: 1,
          ayahNumber: 1,
        ),
        const HifzQuestion(
          id: 'q2',
          mode: HifzTestMode.fillBlank,
          prompt: 'أكمل 2',
          ayahText: 'آية 2',
          displayText: 'عرض 2',
          options: ['خيار 0', 'خيار 1', 'خيار 2', 'خيار 3'],
          correctAnswerIndex: 3,
          surahName: 'الفاتحة',
          surahId: 1,
          ayahNumber: 2,
        ),
      ];

      controller.questions.assignAll(mockQuestions);
      controller.currentQuestionIndex.value = 0;
      controller.viewState.value = HifzViewState.testing;

      // Answer question 1 correctly (option 1)
      controller.selectOption(1);
      expect(controller.isAnswerRevealed.value, isTrue);
      expect(controller.selectedAnswerIndex.value, 1);
      expect(controller.score.value, 1);
      expect(controller.streak.value, 1);

      // Attempting to select another option when already revealed should be ignored
      controller.selectOption(0);
      expect(controller.selectedAnswerIndex.value, 1);

      // Go to question 2
      controller.nextQuestion();
      expect(controller.currentQuestionIndex.value, 1);
      expect(controller.isAnswerRevealed.value, isFalse);
      expect(controller.selectedAnswerIndex.value, -1);

      // Answer question 2 incorrectly (choose 0 instead of 3)
      controller.selectOption(0);
      expect(controller.isAnswerRevealed.value, isTrue);
      expect(controller.score.value, 1);
      expect(controller.streak.value, 0); // streak reset

      // Next question finishes the test because it's the last question
      controller.nextQuestion();
      expect(controller.viewState.value, HifzViewState.results);
      expect(controller.lastResult.value, isNotNull);
      expect(controller.lastResult.value!.correctAnswers, 1);
      expect(controller.lastResult.value!.wrongAnswers, 1);
      expect(controller.lastResult.value!.incorrectQuestionIndices, [1]);
    });

    test('Mutashabihat filtering works properly', () {
      controller.selectedCategory.value = 'الكل';
      final allCount = controller.filteredMutashabihat.length;
      expect(allCount, greaterThanOrEqualTo(10));

      controller.mutashabihatSearchQuery.value = 'البقرة';
      expect(controller.filteredMutashabihat.isNotEmpty, isTrue);

      controller.mutashabihatSearchQuery.value = 'غير موجود قطعا';
      expect(controller.filteredMutashabihat.isEmpty, isTrue);
    });
  });

  group('Hifz Tester Widgets Rendering Tests', () {
    late HifzTesterController controller;

    setUp(() {
      Get.reset();
      controller = Get.put(HifzTesterController());
      controller.surahs.assignAll(sampleSurahs);
      controller.selectedSurah.value = sampleSurahs.first;
    });

    testWidgets('HifzSetupView renders cleanly with mode options and start button', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: HifzSetupView(controller: controller),
          ),
        ),
      );

      expect(find.text('اختبار وتثبيت الحفظ القرآني'), findsOneWidget);
      expect(find.text('إكمال الفراغ القرآني'), findsOneWidget);
      expect(find.text('تحدي الآية التالية'), findsOneWidget);
      expect(find.text('من أي سورة؟'), findsOneWidget);
      expect(find.text('تحدي المتشابهات اللفظية'), findsOneWidget);
      expect(find.text('ابدأ اختبار الحفظ الآن'), findsOneWidget);
    });

    testWidgets('HifzTestingView renders active question and choices', (tester) async {
      controller.questions.assignAll([
        const HifzQuestion(
          id: 'test_q',
          mode: HifzTestMode.fillBlank,
          prompt: 'أكمل الكلمة المحجوبة:',
          ayahText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
          displayText: 'الْحَمْدُ ﴿ ........ ﴾ رَبِّ الْعَالَمِينَ',
          options: ['لِلَّهِ', 'لِلرَّحْمَٰنِ', 'لِلْعَزِيزِ', 'لِلْحَكِيمِ'],
          correctAnswerIndex: 0,
          surahName: 'الفاتحة',
          surahId: 1,
          ayahNumber: 2,
        ),
      ]);
      controller.currentQuestionIndex.value = 0;
      controller.viewState.value = HifzViewState.testing;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: HifzTestingView(controller: controller),
          ),
        ),
      );

      expect(find.text('السؤال 1 من 1'), findsOneWidget);
      expect(find.text('أكمل الكلمة المحجوبة:'), findsOneWidget);
      expect(find.text('لِلَّهِ'), findsOneWidget);

      // Tap option 'لِلَّهِ' (index 0)
      await tester.tap(find.text('لِلَّهِ'));
      await tester.pumpAndSettle();

      expect(controller.isAnswerRevealed.value, isTrue);
      expect(controller.score.value, 1);
      expect(find.text('عرض النتيجة النهائية'), findsOneWidget);
    });

    testWidgets('HifzResultView renders score, grade, and retry button', (tester) async {
      controller.lastResult.value = const HifzTestResult(
        totalQuestions: 5,
        correctAnswers: 4,
        duration: Duration(seconds: 40),
        questions: [
          HifzQuestion(
            id: 'q1',
            mode: HifzTestMode.fillBlank,
            prompt: 'سؤال تجريبي',
            ayahText: 'آية تجريبية',
            displayText: 'عرض تجريبي',
            options: ['أ', 'ب', 'ج', 'د'],
            correctAnswerIndex: 0,
            surahName: 'الفاتحة',
            surahId: 1,
            ayahNumber: 1,
          ),
        ],
        userAnswers: [0],
      );
      controller.viewState.value = HifzViewState.results;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: HifzResultView(controller: controller),
          ),
        ),
      );

      expect(find.text('80%'), findsOneWidget);
      expect(find.text('اختبار جديد'), findsOneWidget);
      expect(find.text('صحيحة'), findsOneWidget);
      expect(find.text('خاطئة'), findsOneWidget);
    });

    testWidgets('MutashabihatBrowserView renders search bar and entry cards', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: MutashabihatBrowserView(controller: controller),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('هداية المرتاب للسخاوي'), findsWidgets);
    });
  });
}
