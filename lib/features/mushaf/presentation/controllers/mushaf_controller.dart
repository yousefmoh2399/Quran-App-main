import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/ayah_entity.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/data/repositories/mushaf_repository.dart';
import '../../../../core/data/repositories/quran_repository.dart';
import '../../../../core/mushaf/mushaf_font_manager.dart';
import '../../../../core/service/settings/SettingsServices.dart';
import '../../../home/presentation/view_model/home_view_model.dart';
import '../models/mushaf_theme_model.dart';

/// Central controller for the 604-page Madinah Mushaf experience.
class MushafController extends GetxController {
  final MushafRepository _mushafRepo = MushafRepository();
  final QuranRepository _quranRepo = QuranRepository();
  final SettingsServices _settings = Get.find<SettingsServices>();

  // State Observables
  final RxInt currentPage = 1.obs;
  final Rx<MushafThemeMode> currentTheme = MushafThemeMode.light.obs;
  final RxBool isOverlayVisible = true.obs;
  final RxBool isLoading = false.obs;

  // Selected Ayah (for highlighting and action sheet)
  final RxnInt selectedSurah = RxnInt();
  final RxnInt selectedAyah = RxnInt();
  final Rxn<AyahEntity> selectedAyahEntity = Rxn<AyahEntity>();

  // Bookmarks
  final RxSet<int> bookmarkedPages = <int>{}.obs;

  // In-memory Pages Cache
  final Map<int, MushafPage> pagesCache = {};

  // PageController for PageView
  late PageController pageController;

  static const String _prefLastPage = 'mushaf_last_page';
  static const String _prefThemeMode = 'mushaf_theme_mode';
  static const String _prefBookmarks = 'mushaf_bookmarked_pages';

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();

    // Determine initial page from route arguments or saved state
    final int initialPage = _resolveInitialPage();
    currentPage.value = initialPage;
    pageController = PageController(initialPage: initialPage - 1);

    _loadPage(initialPage);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.dispose();
  }

  void _loadPreferences() {
    final prefs = _settings.sharedPref;
    if (prefs == null) return;

    // Theme
    final savedTheme = prefs.getString(_prefThemeMode);
    currentTheme.value = MushafThemeMode.fromString(savedTheme);

    // Bookmarked Pages
    final savedList = prefs.getStringList(_prefBookmarks) ?? [];
    bookmarkedPages.addAll(savedList.map((e) => int.tryParse(e) ?? 0).where((p) => p > 0));
  }

  int _resolveInitialPage() {
    // 1. Check Get.arguments
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      if (args.containsKey('pageNumber')) {
        return (args['pageNumber'] as int).clamp(1, 604);
      }
    } else if (args is int) {
      return args.clamp(1, 604);
    }

    // 2. Check saved last read page
    final savedPage = _settings.sharedPref?.getInt(_prefLastPage);
    if (savedPage != null && savedPage >= 1 && savedPage <= 604) {
      return savedPage;
    }

    return 1;
  }

  /// Retrieves a page from cache or database, triggering font preloading.
  Future<MushafPage?> getPage(int pageNumber) async {
    final clamped = pageNumber.clamp(1, 604);
    if (pagesCache.containsKey(clamped)) {
      return pagesCache[clamped];
    }
    return await _loadPage(clamped);
  }

  Future<MushafPage?> _loadPage(int pageNumber) async {
    try {
      final page = await _mushafRepo.getPage(pageNumber);
      pagesCache[pageNumber] = page;

      // Asynchronously ensure current font and preload neighbors
      MushafFontManager.instance.preloadSurroundingPages(pageNumber);

      return page;
    } catch (_) {
      return null;
    }
  }

  /// Called whenever the user swipes to a new page.
  void onPageChanged(int newPage) {
    final clamped = newPage.clamp(1, 604);
    if (currentPage.value == clamped) return;

    currentPage.value = clamped;
    clearAyahSelection();
    _saveLastRead(clamped);

    // Preload neighbors
    _loadPage(clamped);
    if (clamped > 1) _loadPage(clamped - 1);
    if (clamped < 604) _loadPage(clamped + 1);
  }

  /// Automatically persists last read position.
  Future<void> _saveLastRead(int pageNumber) async {
    final prefs = _settings.sharedPref;
    if (prefs == null) return;

    final page = pagesCache[pageNumber];
    await prefs.setInt(_prefLastPage, pageNumber);

    if (page != null) {
      await prefs.setInt('mushaf_last_surah', page.surahNumber);
      await prefs.setString('mushaf_last_surah_name', page.surahNameAr);
      final displayTitle = 'سورة ${page.surahNameAr} - صفحة $pageNumber';
      await prefs.setString('lastRead', displayTitle);

      // Refresh home card if HomeViewModel is active
      if (Get.isRegistered<HomeViewModel>()) {
        Get.find<HomeViewModel>().getLastRead();
      }
    }
  }

  /// Toggles bookmark on a given page.
  Future<void> togglePageBookmark(int pageNumber) async {
    final prefs = _settings.sharedPref;
    if (prefs == null) return;

    if (bookmarkedPages.contains(pageNumber)) {
      bookmarkedPages.remove(pageNumber);
    } else {
      bookmarkedPages.add(pageNumber);
    }

    final strList = bookmarkedPages.map((p) => p.toString()).toList();
    await prefs.setStringList(_prefBookmarks, strList);
    update();
  }

  bool isPageBookmarked(int pageNumber) {
    return bookmarkedPages.contains(pageNumber);
  }

  /// Selects an ayah for highlighting and loads its Tafseer.
  Future<void> selectAyah(int surahNumber, int ayahNumber) async {
    selectedSurah.value = surahNumber;
    selectedAyah.value = ayahNumber;

    try {
      final ayah = await _quranRepo.getAyah(surahNumber, ayahNumber);
      selectedAyahEntity.value = ayah;
    } catch (_) {
      selectedAyahEntity.value = null;
    }
  }

  void clearAyahSelection() {
    selectedSurah.value = null;
    selectedAyah.value = null;
    selectedAyahEntity.value = null;
  }

  /// Toggles visibility of top app bar and bottom controls.
  void toggleOverlay() {
    isOverlayVisible.value = !isOverlayVisible.value;
  }

  /// Updates reading theme.
  Future<void> setThemeMode(MushafThemeMode mode) async {
    currentTheme.value = mode;
    await _settings.sharedPref?.setString(_prefThemeMode, mode.toPrefString());
  }

  /// Navigates to a specific page.
  void goToPage(int pageNumber) {
    final clamped = pageNumber.clamp(1, 604);
    currentPage.value = clamped;
    if (pageController.hasClients) {
      pageController.jumpToPage(clamped - 1);
    }
    onPageChanged(clamped);
  }

  /// Navigates to the first page of a Surah.
  Future<void> goToSurah(int surahNumber) async {
    final startPage = await _mushafRepo.getSurahStart(surahNumber) ?? 1;
    goToPage(startPage);
  }

  /// Navigates to the first page of a Juz.
  Future<void> goToJuz(int juzNumber) async {
    final startPage = await _mushafRepo.getJuzStart(juzNumber) ?? 1;
    goToPage(startPage);
  }

  /// Navigates to a specific Ayah and selects it.
  Future<void> goToAyah(int surahNumber, int ayahNumber) async {
    final page = await _mushafRepo.getPageOfAyah(surahNumber, ayahNumber) ?? 1;
    goToPage(page);
    await selectAyah(surahNumber, ayahNumber);
  }
}
