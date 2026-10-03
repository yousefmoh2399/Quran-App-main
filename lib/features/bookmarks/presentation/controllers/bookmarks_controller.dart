import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/data/repositories/quran_repository.dart';
import '../../../../core/data/repositories/user_repository.dart';
import '../../../../core/util/routes/routes.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_bookmark_model.dart';
import 'package:quran_app_android/features/hadith/data/repositories/hadith_bookmark_repository.dart';

class BookmarksController extends GetxController with GetSingleTickerProviderStateMixin {
  final UserRepository _userRepo = UserRepository();
  final QuranRepository _quranRepo = QuranRepository();
  final HadithBookmarkRepository _hadithRepo = HadithBookmarkRepository();

  late TabController tabController;

  final RxBool isLoading = true.obs;
  final RxList<BookmarkItem> bookmarks = <BookmarkItem>[].obs;
  final RxList<BookmarkItem> filteredBookmarks = <BookmarkItem>[].obs;
  final RxString searchQuery = ''.obs;

  final RxList<MemorizedItem> memorizedList = <MemorizedItem>[].obs;
  final RxMap<String, dynamic> memorizationStats = <String, dynamic>{}.obs;

  final RxList<ReadingLogEntry> readingLogs = <ReadingLogEntry>[].obs;
  final RxList<HadithBookmarkModel> hadithBookmarks = <HadithBookmarkModel>[].obs;

  final Map<int, String> surahNames = {};

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 4, vsync: this);
    loadAll();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      if (surahNames.isEmpty) {
        final surahs = await _quranRepo.getSurahs();
        for (final s in surahs) {
          surahNames[s.id] = s.nameAr;
        }
      }

      await Future.wait([
        _loadBookmarks(),
        _loadMemorized(),
        _loadReadingLog(),
        _loadHadithBookmarks(),
      ]);
    } catch (e) {
      debugPrint('Error loading bookmarks data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadBookmarks() async {
    final list = await _userRepo.getAllBookmarks();
    bookmarks.assignAll(list);
    _applyFilter();
  }

  Future<void> _loadMemorized() async {
    final list = await _userRepo.getAllMemorized();
    memorizedList.assignAll(list);
    final stats = await _userRepo.getMemorizationStats();
    memorizationStats.assignAll(stats);
  }

  Future<void> _loadReadingLog() async {
    final logs = await _userRepo.getReadingLog(limit: 60);
    readingLogs.assignAll(logs);
  }

  Future<void> _loadHadithBookmarks() async {
    final list = await _hadithRepo.getAllBookmarks();
    hadithBookmarks.assignAll(list);
  }

  Future<void> toggleHadithMemorized(String id) async {
    await _hadithRepo.toggleMemorized(id);
    await _loadHadithBookmarks();
  }

  Future<void> deleteHadithBookmark(String id) async {
    await _hadithRepo.removeBookmark(id);
    await _loadHadithBookmarks();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      filteredBookmarks.assignAll(bookmarks);
      return;
    }

    final filtered = bookmarks.where((b) {
      final sName = b.surah != null ? (surahNames[b.surah] ?? '') : '';
      final note = b.note ?? '';
      final pageStr = b.page.toString();
      final ayahStr = b.ayah?.toString() ?? '';

      return sName.toLowerCase().contains(q) ||
          note.toLowerCase().contains(q) ||
          pageStr.contains(q) ||
          ayahStr.contains(q);
    }).toList();

    filteredBookmarks.assignAll(filtered);
  }

  String getSurahName(int? surahNumber) {
    if (surahNumber == null) return '';
    return surahNames[surahNumber] ?? '';
  }

  Future<void> deleteBookmark(BookmarkItem item) async {
    if (item.id != null) {
      await _userRepo.deleteBookmark(item.id!);
      bookmarks.removeWhere((b) => b.id == item.id);
      _applyFilter();
    }
  }

  Future<void> deleteMemorized(MemorizedItem item) async {
    if (item.id != null) {
      await _userRepo.deleteMemorized(item.id!);
      memorizedList.removeWhere((m) => m.id == item.id);
      final stats = await _userRepo.getMemorizationStats();
      memorizationStats.assignAll(stats);
    }
  }

  Future<void> updateMemorizeStatus(MemorizedItem item, MemorizeStatus? newStatus) async {
    if (newStatus == null) {
      await deleteMemorized(item);
    } else {
      final updated = item.copyWith(status: newStatus, updatedAt: DateTime.now());
      await _userRepo.setMemorized(updated);
      await _loadMemorized();
    }
  }

  void openMushaf({required int page, int? surah, int? ayah}) {
    Get.toNamed(
      AppRoutes.mushaf,
      arguments: {
        'pageNumber': page,
        if (surah != null) 'surah': surah,
        if (ayah != null) 'ayah': ayah,
      },
    )?.then((_) => loadAll());
  }
}
