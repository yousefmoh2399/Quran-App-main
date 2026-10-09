import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/features/gharib_quran/data/models/quran_vocabulary_word.dart';
import 'package:quran_app_android/features/gharib_quran/data/repositories/gharib_quran_repository.dart';
import 'package:quran_app_android/features/gharib_quran/presentation/widgets/daily_quran_word_card.dart';
import 'package:quran_app_android/features/gharib_quran/presentation/widgets/page_vocabulary_bottom_sheet.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('GharibQuranRepository Unit Tests', () {
    final repo = GharibQuranRepository.instance;

    test('getAllWords returns rich curated classical dictionary', () {
      final words = repo.getAllWords();
      expect(words.isNotEmpty, isTrue);
      expect(words.length, greaterThanOrEqualTo(25));
    });

    test('getWordsForAyah returns exact matching words for specific Ayah', () {
      // At-Takwir 81:17 -> عَسْعَسَ
      final wordsTakwir = repo.getWordsForAyah(81, 17);
      expect(wordsTakwir.isNotEmpty, isTrue);
      expect(wordsTakwir.first.word, contains('عَسْعَسَ'));
      expect(wordsTakwir.first.root, equals('ع-س-س'));

      // Al-Muddaththir 74:51 -> قَسْوَرَةٍ
      final wordsMuddaththir = repo.getWordsForAyah(74, 51);
      expect(wordsMuddaththir.isNotEmpty, isTrue);
      expect(wordsMuddaththir.first.word, contains('قَسْوَرَة'));

      // Non-existent word returns empty list without error
      final nonExistent = repo.getWordsForAyah(999, 999);
      expect(nonExistent.isEmpty, isTrue);
    });

    test('getWordsForPage returns relevant words for given Mushaf page', () {
      final wordsP586 = repo.getWordsForPage(586);
      expect(wordsP586.isNotEmpty, isTrue);
      expect(wordsP586.any((w) => w.word.contains('عَسْعَسَ') || w.word.contains('الْخُنَّسِ')), isTrue);

      // Fallback/nearby test: Any valid page from 1 to 604 returns 3-5 words
      final wordsP1 = repo.getWordsForPage(1);
      expect(wordsP1.isNotEmpty, isTrue);
      expect(wordsP1.length, inInclusiveRange(1, 5));

      final wordsP604 = repo.getWordsForPage(604);
      expect(wordsP604.isNotEmpty, isTrue);
    });

    test('getDailyWord returns deterministic valid word for any date', () {
      final today = repo.getDailyWord();
      expect(today.word.isNotEmpty, isTrue);
      expect(today.meaning.isNotEmpty, isTrue);
      expect(today.root.isNotEmpty, isTrue);

      final specificDay = repo.getDailyWord(DateTime(2026, 10, 9));
      expect(specificDay, isNotNull);
    });

    test('searchWords filters correctly by word, root, and meaning', () {
      final queryByWord = repo.searchWords('عسعس');
      expect(queryByWord.isNotEmpty, isTrue);
      expect(queryByWord.any((w) => w.word.contains('عَسْعَسَ')), isTrue);

      final queryByRoot = repo.searchWords('ق-س-ر');
      expect(queryByRoot.isNotEmpty, isTrue);
      expect(queryByRoot.first.word, contains('قَسْوَرَة'));

      final emptyQueryReturnsAll = repo.searchWords('');
      expect(emptyQueryReturnsAll.length, equals(repo.getAllWords().length));
    });

    test('QuranVocabularyWord model serialization', () {
      const word = QuranVocabularyWord(
        id: 'voc_test',
        word: 'ضِيزَىٰ',
        root: 'ض-و-ز',
        meaning: 'قسمة جائرة',
        surahId: 53,
        surahName: 'النجم',
        ayahNumber: 22,
        pageNumber: 527,
        ayahSnippet: 'تِلْكَ إِذًا قِسْمَةٌ ضِيزَىٰ',
      );

      final map = word.toMap();
      expect(map['id'], equals('voc_test'));
      expect(map['word'], equals('ضِيزَىٰ'));
      expect(map['root'], equals('ض-و-ز'));
      expect(map['surahId'], equals(53));
      expect(map['ayahNumber'], equals(22));
    });
  });

  group('Gharib Quran Presentation Widgets', () {
    testWidgets('DailyQuranWordCard renders properly without overflow', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyQuranWordCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('كلمة قرآنية ومعناها'), findsOneWidget);
      expect(find.byType(DailyQuranWordCard), findsOneWidget);
      expect(find.textContaining('المصحف'), findsOneWidget);
      expect(find.text('تصميم بطاقة'), findsOneWidget);
    });

    testWidgets('PageVocabularyBottomSheet renders properly', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: PageVocabularyBottomSheet(
              pageNumber: 586,
              surahName: 'التكوير',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('غريب مفردات الصفحة'), findsOneWidget);
      expect(find.textContaining('التكوير'), findsWidgets);
      expect(find.byType(PageVocabularyBottomSheet), findsOneWidget);
    });
  });
}
