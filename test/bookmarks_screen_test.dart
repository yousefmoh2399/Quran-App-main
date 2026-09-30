import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';

void main() {
  late Database testDb;
  late UserRepository userRepo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await UserDatabase.createTablesForTest(testDb);
    UserDatabase.customDatabaseForTesting = testDb;
    userRepo = UserRepository();
  });

  tearDownAll(() async {
    await testDb.close();
    UserDatabase.customDatabaseForTesting = null;
  });

  group('Bookmarks and Reading Log Unit Tests', () {

    test('Add multiple bookmarks with colors and notes and retrieve filtered', () async {
      await userRepo.addBookmark(BookmarkItem(
        type: BookmarkType.page,
        page: 1,
        color: BookmarkColor.gold,
        note: 'الفاتحة أم الكتاب',
      ));

      await userRepo.addBookmark(BookmarkItem(
        type: BookmarkType.ayah,
        page: 2,
        surah: 2,
        ayah: 5,
        color: BookmarkColor.ruby,
        note: 'أولئك على هدى من ربهم',
      ));

      final all = await userRepo.getAllBookmarks();
      expect(all.length, 2);

      final pageBookmarks = await userRepo.getBookmarksForPage(1);
      expect(pageBookmarks.length, 1);
      expect(pageBookmarks.first.note, 'الفاتحة أم الكتاب');
      expect(pageBookmarks.first.color, BookmarkColor.gold);

      final ayahBookmark = await userRepo.getBookmarkForAyah(2, 5);
      expect(ayahBookmark, isNotNull);
      expect(ayahBookmark!.color, BookmarkColor.ruby);
    });

    test('Reading log records daily pages and calculates last read page', () async {
      await userRepo.logPageRead(10);
      await userRepo.logPageRead(11);
      await userRepo.logPageRead(12);

      final today = await userRepo.getTodayReadingLog();
      expect(today, isNotNull);
      expect(today!.pagesRead, 3);
      expect(today.lastPage, 12);

      final lastReadPage = await userRepo.getLastReadPage();
      expect(lastReadPage, 12);
    });

    test('Memorization stats updates with multiple statuses', () async {
      await userRepo.setMemorized(MemorizedItem(
        type: BookmarkType.page,
        page: 1,
        status: MemorizeStatus.memorized,
      ));

      await userRepo.setMemorized(MemorizedItem(
        type: BookmarkType.page,
        page: 2,
        status: MemorizeStatus.memorized,
      ));

      await userRepo.setMemorized(MemorizedItem(
        type: BookmarkType.page,
        page: 3,
        status: MemorizeStatus.learning,
      ));

      await userRepo.setMemorized(MemorizedItem(
        type: BookmarkType.page,
        page: 4,
        status: MemorizeStatus.needsReview,
      ));

      final stats = await userRepo.getMemorizationStats();
      expect(stats['memorizedPages'], 2);
      expect(stats['learningPages'], 1);
      expect(stats['reviewPages'], 1);
      expect(stats['percentage'], closeTo((2 / 604.0) * 100, 0.01));
    });
  });
}
