import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_bookmark_model.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_model.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_model_malek.dart';
import 'package:quran_app_android/features/hadith/data/repositories/hadith_bookmark_repository.dart';

class HadithViewModel extends GetxController {
  final HadithRepository _hadithRepository;
  final HadithBookmarkRepository _bookmarkRepository;

  HadithViewModel({
    HadithRepository? hadithRepository,
    HadithBookmarkRepository? bookmarkRepository,
  })  : _hadithRepository = hadithRepository ?? HadithRepository(),
        _bookmarkRepository = bookmarkRepository ?? HadithBookmarkRepository() {
    hadithRead();
    loadBookmarks();
    loadLastRead();
  }

  final SettingsServices settings = Get.find<SettingsServices>();
  List<dynamic> items = [];
  List<HadithModel> hadithList = [];
  bool isLoading = true;

  RxBool isLoadingg = false.obs;

  double fontSize = 20.0;
  int currentIndex = 0;
  String searchQuery = '';
  PageController pageController = PageController();

  List<dynamic> itemsData = [];
  List<HadithModelFinal> hadithModelFinal = [];

  // Bookmarks state
  List<HadithBookmarkModel> bookmarks = [];
  Set<String> bookmarkedIds = {};

  // Last read state
  int? lastReadChapterIndex;
  String? lastReadChapterName;
  int? lastReadItemIndex;
  int? lastReadHadithNumber;
  String? lastReadSnippet;
  DateTime? lastReadTime;

  bool get hasLastRead =>
      lastReadChapterIndex != null &&
      lastReadChapterName != null &&
      lastReadChapterName!.isNotEmpty;

  List<HadithModelFinal> get filteredChapters {
    if (searchQuery.trim().isEmpty) {
      return hadithModelFinal;
    }
    final q = searchQuery.trim().toLowerCase();
    return hadithModelFinal.where((item) {
      final name = item.data?.metadata?.section?.name?.toLowerCase() ?? '';
      return name.contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    update();
  }

  void increaseFont() {
    if (fontSize < 34) {
      fontSize += 2;
      update();
    }
  }

  void decreaseFont() {
    if (fontSize > 16) {
      fontSize -= 2;
      update();
    }
  }

  void changeIndex(int index) {
    currentIndex = index;
    update();
  }

  String _buildBookmarkId(int chapterIndex, int itemIndex) =>
      '${chapterIndex}_$itemIndex';

  bool isHadithBookmarked(int chapterIndex, int itemIndex) {
    return bookmarkedIds.contains(_buildBookmarkId(chapterIndex, itemIndex));
  }

  int getChapterBookmarkCount(int chapterIndex) {
    final prefix = '${chapterIndex}_';
    return bookmarkedIds.where((id) => id.startsWith(prefix)).length;
  }

  Future<void> loadBookmarks() async {
    try {
      final list = await _bookmarkRepository.getAllBookmarks();
      bookmarks = list;
      bookmarkedIds = list.map((b) => b.id).toSet();
      update();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading hadith bookmarks: $e');
    }
  }

  /// Toggles bookmark state for a specific hadith. Returns true if bookmarked, false if removed.
  Future<bool> toggleBookmark({
    required int chapterIndex,
    required String chapterName,
    required int itemIndex,
    required HadithsModel hadith,
  }) async {
    final id = _buildBookmarkId(chapterIndex, itemIndex);
    final currentlyBookmarked = bookmarkedIds.contains(id);

    if (currentlyBookmarked) {
      await _bookmarkRepository.removeBookmark(id);
      bookmarkedIds.remove(id);
      bookmarks.removeWhere((b) => b.id == id);
      update();
      return false;
    } else {
      final model = HadithBookmarkModel(
        id: id,
        chapterIndex: chapterIndex,
        itemIndex: itemIndex,
        chapterName: chapterName,
        hadithNumber: hadith.arabicnumber ?? (itemIndex + 1),
        text: hadith.text ?? '',
        source: 'موطأ الإمام مالك',
        savedAt: DateTime.now(),
      );
      await _bookmarkRepository.saveBookmark(model);
      bookmarkedIds.add(id);
      bookmarks.insert(0, model);
      update();
      return true;
    }
  }

  /// Automatically updates and persists the last-read hadith position.
  Future<void> saveLastRead({
    required int chapterIndex,
    required String chapterName,
    required int itemIndex,
    required HadithsModel hadith,
  }) async {
    lastReadChapterIndex = chapterIndex;
    lastReadChapterName = chapterName;
    lastReadItemIndex = itemIndex;
    lastReadHadithNumber = hadith.arabicnumber ?? (itemIndex + 1);
    final rawText = (hadith.text ?? '').replaceAll('\n', ' ').trim();
    lastReadSnippet = rawText.length > 70 ? '${rawText.substring(0, 70)}...' : rawText;
    lastReadTime = DateTime.now();

    final prefs = settings.sharedPref;
    if (prefs != null) {
      await prefs.setInt('hadith_last_chapter_index', chapterIndex);
      await prefs.setString('hadith_last_chapter_name', chapterName);
      await prefs.setInt('hadith_last_item_index', itemIndex);
      await prefs.setInt('hadith_last_number', lastReadHadithNumber!);
      await prefs.setString('hadith_last_snippet', lastReadSnippet!);
      await prefs.setString('hadith_last_time', lastReadTime!.toIso8601String());
      await prefs.setInt('saveIndex', itemIndex);
      await prefs.setInt('indexHadith', chapterIndex);
    }
    update();
  }

  void loadLastRead() {
    final prefs = settings.sharedPref;
    if (prefs == null) return;

    final chIdx = prefs.getInt('hadith_last_chapter_index');
    final chName = prefs.getString('hadith_last_chapter_name');
    final itmIdx = prefs.getInt('hadith_last_item_index');

    if (chIdx != null && chName != null) {
      lastReadChapterIndex = chIdx;
      lastReadChapterName = chName;
      lastReadItemIndex = itmIdx ?? 0;
      lastReadHadithNumber = prefs.getInt('hadith_last_number') ?? 1;
      lastReadSnippet = prefs.getString('hadith_last_snippet') ?? '';
      final tStr = prefs.getString('hadith_last_time');
      if (tStr != null) {
        lastReadTime = DateTime.tryParse(tStr);
      }
      update();
    }
  }

  /// Resumes from last read position directly.
  void resumeLastRead() {
    if (!hasLastRead) return;
    openChapterAtHadith(lastReadChapterIndex!, lastReadItemIndex ?? 0);
  }

  /// Opens a specific chapter and navigates to the given hadith index.
  void openChapterAtHadith(int chapterIndex, int hadithIndex) {
    AppHaptics.selection();
    settings.sharedPref?.setInt('indexHadith', chapterIndex);
    settings.sharedPref?.setInt('saveIndex', hadithIndex);
    currentIndex = hadithIndex;

    // Reset or reinitialize pageController for that specific page
    if (pageController.hasClients) {
      pageController.jumpToPage(hadithIndex);
    } else {
      pageController = PageController(initialPage: hadithIndex);
    }

    if (Get.currentRoute == AppRoutes.hadith) {
      update();
    } else {
      Get.toNamed(AppRoutes.hadith);
    }
  }

  void goToPage() {
    final saved = settings.sharedPref?.getInt('saveIndex');
    if (saved != null && pageController.hasClients) {
      pageController.animateToPage(
        saved,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      update();
    }
  }

  Future<void> hadithRead() async {
    try {
      isLoading = true;
      isLoadingg.value = true;
      update();

      final sectionsWithHadiths =
          await _hadithRepository.getAllSectionsWithHadiths();

      hadithModelFinal = sectionsWithHadiths.map((swh) {
        return HadithModelFinal(
          id: swh.section.id,
          data: HadithModelData(
            metadata: MetaDataModel(
              name: swh.section.source,
              section: SectionModel(name: swh.section.name),
            ),
            hadiths: swh.hadiths.map((h) {
              return HadithsModel(
                hadithnumber: h.hadithNumber,
                arabicnumber: h.arabicNumber,
                text: h.textAr,
              );
            }).toList(),
          ),
        );
      }).toList();

      itemsData = hadithModelFinal;
      isLoadingg.value = false;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HadithViewModel error: $e\n$st');
      }
    } finally {
      isLoading = false;
      update();
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
