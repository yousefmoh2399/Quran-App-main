import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/core/data/models/quran_marks_models.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/features/quran/data/models/model.dart';
import 'package:quran_app_android/features/quran/presentation/views/widget/surah_index_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database testDb;
  late UserRepository userRepo;

  // Synthetic Quran structure for deterministic unit tests
  late QuranIndexStructure syntheticStructure;

  setUpAll(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await UserDatabase.createTablesForTest(testDb);
    UserDatabase.customDatabaseForTesting = testDb;
    userRepo = UserRepository();

    syntheticStructure = QuranIndexStructure(
      surahs: {
        // Surah 1: Al-Fatiha (7 ayahs, page 1)
        1: const SurahMetadata(
          id: 1,
          nameAr: 'الفاتحة',
          totalVerses: 7,
          startPage: 1,
          endPage: 1,
          ayahsByPage: {
            1: [1, 2, 3, 4, 5, 6, 7],
          },
        ),
        // Boundary Page 604 containing Surahs 112, 113, and 114
        112: const SurahMetadata(
          id: 112,
          nameAr: 'الإخلاص',
          totalVerses: 4,
          startPage: 604,
          endPage: 604,
          ayahsByPage: {
            604: [1, 2, 3, 4],
          },
        ),
        113: const SurahMetadata(
          id: 113,
          nameAr: 'الفلق',
          totalVerses: 5,
          startPage: 604,
          endPage: 604,
          ayahsByPage: {
            604: [1, 2, 3, 4, 5],
          },
        ),
        114: const SurahMetadata(
          id: 114,
          nameAr: 'الناس',
          totalVerses: 6,
          startPage: 604,
          endPage: 604,
          ayahsByPage: {
            604: [1, 2, 3, 4, 5, 6],
          },
        ),
      },
      pageToSurahs: {
        1: [1],
        604: [112, 113, 114],
      },
      juzPages: {
        1: [1, 21],
        30: [582, 604],
      },
    );
  });

  tearDownAll(() async {
    await testDb.close();
    UserDatabase.customDatabaseForTesting = null;
  });

  setUp(() async {
    // Clear user_data tables before each test
    await testDb.delete('bookmarks');
    await testDb.delete('memorized');
    await testDb.delete('reading_log');
  });

  group('1. Memorization Ratio & Status Calculations', () {
    test('Calculates partial and full memorization ratio accurately', () async {
      // 1. Mark 3 of 7 verses of Al-Fatihah as memorized
      for (int i = 1; i <= 3; i++) {
        await userRepo.setMemorized(MemorizedItem(
          type: BookmarkType.ayah,
          page: 1,
          surah: 1,
          ayah: i,
          status: MemorizeStatus.memorized,
        ));
      }

      var aggregate = await userRepo.getMarksAggregate(structure: syntheticStructure);
      var fatiha = aggregate.surahs[1]!;

      expect(fatiha.memorizedAyahsCount, equals(3));
      expect(fatiha.totalVerses, equals(7));
      expect(fatiha.memorizedRatio, closeTo(3 / 7, 0.001));
      expect(fatiha.memorizedPercentage, equals(43));
      expect(fatiha.isPartiallyMemorized, isTrue);
      expect(fatiha.isFullyMemorized, isFalse);

      // 2. Complete memorizing remaining verses (4..7)
      for (int i = 4; i <= 7; i++) {
        await userRepo.setMemorized(MemorizedItem(
          type: BookmarkType.ayah,
          page: 1,
          surah: 1,
          ayah: i,
          status: MemorizeStatus.memorized,
        ));
      }

      aggregate = await userRepo.getMarksAggregate(structure: syntheticStructure);
      fatiha = aggregate.surahs[1]!;

      expect(fatiha.memorizedAyahsCount, equals(7));
      expect(fatiha.memorizedRatio, equals(1.0));
      expect(fatiha.memorizedPercentage, equals(100));
      expect(fatiha.isFullyMemorized, isTrue);
      expect(fatiha.isPartiallyMemorized, isFalse);
    });
  });

  group('2. Boundary Page Surah Attribution (Page 604 with Surahs 112, 113, 114)', () {
    test('Page bookmark flags all Surahs on the boundary page', () async {
      await userRepo.addBookmark(BookmarkItem(
        type: BookmarkType.page,
        page: 604,
        color: BookmarkColor.gold,
      ));

      final aggregate = await userRepo.getMarksAggregate(structure: syntheticStructure);

      expect(aggregate.surahs[112]!.hasBookmark, isTrue);
      expect(aggregate.surahs[113]!.hasBookmark, isTrue);
      expect(aggregate.surahs[114]!.hasBookmark, isTrue);
      // Surah 1 on page 1 is not affected
      expect(aggregate.surahs[1]!.hasBookmark, isFalse);
      // Juz 30 containing page 604 is flagged
      expect(aggregate.juzs[30]!.hasBookmark, isTrue);
    });

    test('Ayah bookmark flags ONLY the specific Surah on the boundary page', () async {
      // Bookmark verse 2 of Surah 113 (Al-Falaq) on page 604
      await userRepo.addBookmark(BookmarkItem(
        type: BookmarkType.ayah,
        page: 604,
        surah: 113,
        ayah: 2,
        color: BookmarkColor.emerald,
      ));

      final aggregate = await userRepo.getMarksAggregate(structure: syntheticStructure);

      expect(aggregate.surahs[113]!.hasBookmark, isTrue);
      expect(aggregate.surahs[112]!.hasBookmark, isFalse);
      expect(aggregate.surahs[114]!.hasBookmark, isFalse);
    });

    test('Page memorization marks verses for all Surahs on boundary page', () async {
      await userRepo.setMemorized(MemorizedItem(
        type: BookmarkType.page,
        page: 604,
        status: MemorizeStatus.memorized,
      ));

      final aggregate = await userRepo.getMarksAggregate(structure: syntheticStructure);

      // Surah 112: all 4 verses memorized
      expect(aggregate.surahs[112]!.memorizedAyahsCount, equals(4));
      expect(aggregate.surahs[112]!.isFullyMemorized, isTrue);

      // Surah 113: all 5 verses memorized
      expect(aggregate.surahs[113]!.memorizedAyahsCount, equals(5));
      expect(aggregate.surahs[113]!.isFullyMemorized, isTrue);

      // Surah 114: all 6 verses memorized
      expect(aggregate.surahs[114]!.memorizedAyahsCount, equals(6));
      expect(aggregate.surahs[114]!.isFullyMemorized, isTrue);
    });

    test('Last read resolution on boundary page assigns badge to explicitly focused Surah', () async {
      // User is on page 604 and explicitly reading Surah 113
      final aggregate = await userRepo.getMarksAggregate(
        structure: syntheticStructure,
        lastReadPage: 604,
        lastReadSurah: 113,
        lastReadSurahName: 'الفلق',
      );

      expect(aggregate.surahs[113]!.isLastRead, isTrue);
      expect(aggregate.surahs[113]!.lastReadPage, equals(604));
      // Neighboring Surahs on the same page do NOT get the badge
      expect(aggregate.surahs[112]!.isLastRead, isFalse);
      expect(aggregate.surahs[114]!.isLastRead, isFalse);
    });

    test('Last read resolution on boundary page falls back to first Surah if surah not specified', () async {
      final aggregate = await userRepo.getMarksAggregate(
        structure: syntheticStructure,
        lastReadPage: 604,
      );

      // Falls back to first surah present on page 604 (Surah 112)
      expect(aggregate.surahs[112]!.isLastRead, isTrue);
      expect(aggregate.surahs[113]!.isLastRead, isFalse);
      expect(aggregate.surahs[114]!.isLastRead, isFalse);
    });
  });

  group('3. Dynamic Badge Updates After Marking', () {
    test('Bookmark badge reflects in aggregate immediately upon insert and delete', () async {
      var aggregate = await userRepo.getMarksAggregate(structure: syntheticStructure);
      expect(aggregate.surahs[1]!.hasBookmark, isFalse);

      final id = await userRepo.addBookmark(BookmarkItem(
        type: BookmarkType.ayah,
        page: 1,
        surah: 1,
        ayah: 1,
      ));

      aggregate = await userRepo.getMarksAggregate(structure: syntheticStructure);
      expect(aggregate.surahs[1]!.hasBookmark, isTrue);

      await userRepo.deleteBookmark(id);
      aggregate = await userRepo.getMarksAggregate(structure: syntheticStructure);
      expect(aggregate.surahs[1]!.hasBookmark, isFalse);
    });
  });

  group('4. SurahIndexItem Widget Tests in all 4 Visual States', () {
    Widget createTestWidget(SurahMarksSummary? marks) {
      return MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SurahIndexItem(
            surah: NameModel(
              id: 1,
              name: 'الفاتحة',
              total_verses: 7,
              type: 'meccan',
            ),
            marks: marks,
            onTap: () {},
            onStartFromBeginning: () {},
          ),
        ),
      );
    }

    testWidgets('State 1: Normal Surah item (no badges or marks)', (tester) async {
      const normalMarks = SurahMarksSummary(
        surahId: 1,
        surahName: 'الفاتحة',
        startPage: 1,
        endPage: 1,
        totalVerses: 7,
      );

      await tester.pumpWidget(createTestWidget(normalMarks));
      await tester.pumpAndSettle();

      expect(find.text('سورة الفاتحة'), findsOneWidget);
      expect(find.text('مكية • 7 آيات'), findsOneWidget);
      expect(find.byKey(const Key('surah_last_read_badge')), findsNothing);
      expect(find.byKey(const Key('surah_bookmark_icon')), findsNothing);
      expect(find.byKey(const Key('surah_fully_memorized_icon')), findsNothing);
    });

    testWidgets('State 2: Last Read Surah item (shows last read badge and start from beginning button)', (tester) async {
      const lastReadMarks = SurahMarksSummary(
        surahId: 1,
        surahName: 'الفاتحة',
        startPage: 1,
        endPage: 1,
        totalVerses: 7,
        isLastRead: true,
        lastReadPage: 1,
      );

      await tester.pumpWidget(createTestWidget(lastReadMarks));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('surah_last_read_badge')), findsOneWidget);
      expect(find.byKey(const Key('surah_start_beginning_btn')), findsOneWidget);
      expect(find.textContaining('آخر قراءة'), findsOneWidget);
    });

    testWidgets('State 3: Bookmarked Surah item (shows bookmark icon)', (tester) async {
      const bookmarkedMarks = SurahMarksSummary(
        surahId: 1,
        surahName: 'الفاتحة',
        startPage: 1,
        endPage: 1,
        totalVerses: 7,
        hasBookmark: true,
      );

      await tester.pumpWidget(createTestWidget(bookmarkedMarks));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('surah_bookmark_icon')), findsOneWidget);
      expect(find.byKey(const Key('surah_last_read_badge')), findsNothing);
    });

    testWidgets('State 4: Fully Memorized Surah item (shows 100% memorized badge)', (tester) async {
      const fullyMemorizedMarks = SurahMarksSummary(
        surahId: 1,
        surahName: 'الفاتحة',
        startPage: 1,
        endPage: 1,
        totalVerses: 7,
        memorizedAyahsCount: 7,
      );

      await tester.pumpWidget(createTestWidget(fullyMemorizedMarks));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('surah_fully_memorized_icon')), findsOneWidget);
      expect(find.text('محفوظة'), findsOneWidget);
    });
  });
}
