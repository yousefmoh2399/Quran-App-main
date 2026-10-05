import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/ayah_entity.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/data/repositories/mushaf_repository.dart';
import '../../../../core/data/repositories/quran_repository.dart';
import '../../../../core/data/repositories/user_repository.dart';
import '../../../../core/mushaf/mushaf_font_manager.dart';
import '../../../../core/mushaf/mushaf_raster_cache.dart';
import '../../../../core/service/settings/SettingsServices.dart';
import '../../../home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/reminders/data/commute_wird_repository.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../models/mushaf_theme_model.dart';
import '../widgets/mushaf_paper_flip_view.dart';

/// Central controller for the 604-page Madinah Mushaf experience.
class MushafController extends GetxController {
  final MushafRepository _mushafRepo = MushafRepository();
  final QuranRepository _quranRepo = QuranRepository();
  final UserRepository _userRepo = UserRepository();
  final SettingsServices _settings = Get.find<SettingsServices>();

  // State Observables
  final RxInt currentPage = 1.obs;
  final Rx<MushafThemeMode> currentTheme = MushafThemeMode.light.obs;
  final RxBool isOverlayVisible = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPageTurning = false.obs;
  final RxList<int> pagesToPreload = <int>[].obs;

  // Selected Ayah (for highlighting and action sheet)
  final RxnInt selectedSurah = RxnInt();
  final RxnInt selectedAyah = RxnInt();
  final Rxn<AyahEntity> selectedAyahEntity = Rxn<AyahEntity>();
  final Rx<BookmarkColor> selectedAyahColor = BookmarkColor.gold.obs;

  // Bookmarks & Memorization Maps
  final RxSet<int> bookmarkedPages = <int>{}.obs;
  final RxMap<int, BookmarkItem> pageBookmarksMap = <int, BookmarkItem>{}.obs;
  final RxMap<int, MemorizedItem> pageMemorizedMap = <int, MemorizedItem>{}.obs;
  final RxMap<String, BookmarkItem> ayahBookmarksMap = <String, BookmarkItem>{}.obs;
  final RxMap<String, MemorizedItem> ayahMemorizedMap = <String, MemorizedItem>{}.obs;
  final RxInt userMarksVersion = 0.obs;

  // Commute Mode Observables
  final RxBool isCommuteMode = false.obs;
  final RxDouble commuteZoomScale = 1.12.obs;
  final RxBool commuteHighContrast = false.obs;
  final RxBool commuteKeepScreenOn = true.obs;
  final RxInt commuteTargetPages = 3.obs;
  final RxInt commuteStartPage = 1.obs;
  final RxInt commutePagesRead = 1.obs;
  final RxString commuteSlotId = 'commute'.obs;
  final RxBool commuteCountTowardsMain = true.obs;
  final RxBool isCommuteCompleted = false.obs;

  // Debounced last read timer (2 seconds after page settles)
  Timer? _lastReadDebounce;

  // Reading dwell timer (5 seconds dwell triggers reading log)
  Timer? _dwellTimer;

  // In-memory Pages Cache
  final Map<int, MushafPage> pagesCache = {};

  // PageController for PageView / DualView
  late PageController pageController;

  // Paper flip view state handle for realistic page turning
  MushafPaperFlipViewState? paperFlipState;

  static const String _prefLastPage = 'mushaf_last_page';
  static const String _prefThemeMode = 'mushaf_theme_mode';
  static const String _prefBookmarks = 'mushaf_bookmarked_pages';

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    loadUserData();

    // Determine initial page from route arguments or saved state
    final int initialPage = _resolveInitialPage();
    currentPage.value = initialPage;
    pageController = PageController(initialPage: initialPage - 1);

    _loadPage(initialPage).then((_) {
      _preloadAdjacentPages(initialPage);
    });

    _startDwellTimer(initialPage);

    // If an exact ayah was requested in arguments, select it after layout
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final s = args['surah'] as int?;
      final a = args['ayah'] as int?;
      if (s != null && a != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          selectAyah(s, a);
        });
      }
    }
  }

  @override
  void onClose() {
    _dwellTimer?.cancel();
    _lastReadDebounce?.cancel();
    _saveLastRead(currentPage.value);
    MushafRasterCache.instance.clear();
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
      if (args['commute_mode'] == true) {
        isCommuteMode.value = true;
        if (args.containsKey('target_pages')) {
          commuteTargetPages.value = (args['target_pages'] as num).toInt();
        }
        if (args.containsKey('slot_id')) {
          commuteSlotId.value = args['slot_id']?.toString() ?? 'commute';
        }
        if (args.containsKey('count_towards_main')) {
          commuteCountTowardsMain.value = args['count_towards_main'] as bool? ?? true;
        }
        if (args.containsKey('page')) {
          final p = (args['page'] as num).toInt().clamp(1, 604);
          commuteStartPage.value = p;
          return p;
        }
      }
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

  void _preloadAdjacentPages(int pageNumber) {
    final targets = <int>[];
    for (int i = 1; i <= 4; i++) {
      if (pageNumber - i >= 1) targets.add(pageNumber - i);
      if (pageNumber + i <= 604) targets.add(pageNumber + i);
    }

    for (final target in targets) {
      _loadPage(target);
    }

    // Queue adjacent pages that need offscreen rasterization
    final needingRaster = targets.where(
      (p) => !MushafRasterCache.instance.has(p, currentTheme.value),
    ).toList();
    pagesToPreload.assignAll(needingRaster);
  }

  /// Automatically persists last read position.
  Future<void> _saveLastRead(int pageNumber) async {
    final prefs = _settings.sharedPref;
    if (prefs == null) return;

    final page = pagesCache[pageNumber];
    await prefs.setInt(_prefLastPage, pageNumber);

    // Track active Wird position if reading within active plan range
    try {
      final wirdPlan = await _userRepo.getWirdPlan();
      if (wirdPlan != null && wirdPlan.enabled && pageNumber >= wirdPlan.startPage && pageNumber <= wirdPlan.endPage) {
        await prefs.setInt('wird_last_page', pageNumber);
      }
    } catch (_) {}

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

  /// Called whenever the user swipes to a new page.
  void onPageChanged(int newPage) {
    final clamped = newPage.clamp(1, 604);
    if (currentPage.value == clamped) {
      _preloadAdjacentPages(clamped);
      return;
    }

    currentPage.value = clamped;
    clearAyahSelection();

    // 2-second debounce before persisting last read position
    _lastReadDebounce?.cancel();
    _lastReadDebounce = Timer(const Duration(seconds: 2), () {
      _saveLastRead(clamped);
    });

    _startDwellTimer(clamped);
    _preloadAdjacentPages(clamped);
  }

  void _startDwellTimer(int page) {
    _dwellTimer?.cancel();
    _dwellTimer = Timer(const Duration(seconds: 5), () async {
      if (currentPage.value == page) {
        await _userRepo.logPageRead(page);
      }
    });
  }

  Future<void> loadUserData() async {
    try {
      final bookmarks = await _userRepo.getAllBookmarks();
      final memorized = await _userRepo.getAllMemorized();

      pageBookmarksMap.clear();
      ayahBookmarksMap.clear();
      bookmarkedPages.clear();

      for (final b in bookmarks) {
        if (b.type == BookmarkType.page) {
          pageBookmarksMap[b.page] = b;
          bookmarkedPages.add(b.page);
        } else if (b.surah != null && b.ayah != null) {
          ayahBookmarksMap['${b.surah}:${b.ayah}'] = b;
        }
      }

      pageMemorizedMap.clear();
      ayahMemorizedMap.clear();

      for (final m in memorized) {
        if (m.type == BookmarkType.page) {
          pageMemorizedMap[m.page] = m;
        } else if (m.surah != null && m.ayah != null) {
          ayahMemorizedMap['${m.surah}:${m.ayah}'] = m;
        }
      }
      userMarksVersion.value++;
      update();
    } catch (e) {
      debugPrint('Error loading user data in mushaf controller: $e');
    }
  }

  Map<String, BookmarkColor> getAyahBookmarkColors() {
    return ayahBookmarksMap.map((key, item) => MapEntry(key, item.color));
  }

  Map<String, MemorizeStatus> getAyahMemorizeStatuses() {
    return ayahMemorizedMap.map((key, item) => MapEntry(key, item.status));
  }

  BookmarkColor? getPageBookmarkColor(int page) => pageBookmarksMap[page]?.color;
  MemorizeStatus? getPageMemorizeStatus(int page) => pageMemorizedMap[page]?.status;
  BookmarkItem? getPageBookmark(int page) => pageBookmarksMap[page];
  MemorizedItem? getPageMemorized(int page) => pageMemorizedMap[page];
  BookmarkItem? getAyahBookmark(int surah, int ayah) => ayahBookmarksMap['$surah:$ayah'];
  MemorizedItem? getAyahMemorized(int surah, int ayah) => ayahMemorizedMap['$surah:$ayah'];

  /// Toggles bookmark on a given page.
  Future<void> togglePageBookmark(
    int pageNumber, {
    BookmarkColor color = BookmarkColor.gold,
    String? note,
  }) async {
    if (pageBookmarksMap.containsKey(pageNumber)) {
      final item = pageBookmarksMap[pageNumber];
      if (item?.id != null) {
        await _userRepo.deleteBookmark(item!.id!);
      } else {
        await _userRepo.deleteBookmarkByPage(pageNumber);
      }
      pageBookmarksMap.remove(pageNumber);
      bookmarkedPages.remove(pageNumber);
    } else {
      final page = pagesCache[pageNumber];
      final item = BookmarkItem(
        type: BookmarkType.page,
        page: pageNumber,
        surah: page?.surahNumber,
        ayah: 1,
        color: color,
        note: note,
      );
      final id = await _userRepo.addBookmark(item);
      pageBookmarksMap[pageNumber] = item.copyWith(id: id);
      bookmarkedPages.add(pageNumber);
    }
    MushafRasterCache.instance.removePage(pageNumber);
    userMarksVersion.value++;
    update();
  }

  Future<void> setPageBookmark({
    required int pageNumber,
    required BookmarkColor color,
    String? note,
  }) async {
    final page = pagesCache[pageNumber];
    final item = BookmarkItem(
      type: BookmarkType.page,
      page: pageNumber,
      surah: page?.surahNumber,
      ayah: 1,
      color: color,
      note: note,
    );
    final id = await _userRepo.addBookmark(item);
    pageBookmarksMap[pageNumber] = item.copyWith(id: id);
    bookmarkedPages.add(pageNumber);
    MushafRasterCache.instance.removePage(pageNumber);
    userMarksVersion.value++;
    update();
  }

  Future<void> removePageBookmark(int pageNumber) async {
    final item = pageBookmarksMap[pageNumber];
    if (item?.id != null) {
      await _userRepo.deleteBookmark(item!.id!);
    } else {
      await _userRepo.deleteBookmarkByPage(pageNumber);
    }
    pageBookmarksMap.remove(pageNumber);
    bookmarkedPages.remove(pageNumber);
    MushafRasterCache.instance.removePage(pageNumber);
    userMarksVersion.value++;
    update();
  }

  Future<void> setPageMemorizeStatus(int pageNumber, MemorizeStatus? status) async {
    if (status == null) {
      await _userRepo.deleteMemorizedByPage(pageNumber);
      pageMemorizedMap.remove(pageNumber);
    } else {
      final item = MemorizedItem(
        type: BookmarkType.page,
        page: pageNumber,
        status: status,
      );
      final id = await _userRepo.setMemorized(item);
      pageMemorizedMap[pageNumber] = item.copyWith(id: id);
    }
    MushafRasterCache.instance.removePage(pageNumber);
    userMarksVersion.value++;
    update();
  }

  Future<void> setAyahBookmark({
    required int surah,
    required int ayah,
    required int page,
    required BookmarkColor color,
    String? note,
  }) async {
    final item = BookmarkItem(
      type: BookmarkType.ayah,
      page: page,
      surah: surah,
      ayah: ayah,
      color: color,
      note: note,
    );
    final id = await _userRepo.addBookmark(item);
    ayahBookmarksMap['$surah:$ayah'] = item.copyWith(id: id);
    selectedAyahColor.value = color;
    MushafRasterCache.instance.removePage(page);
    userMarksVersion.value++;
    update();
  }

  Future<void> removeAyahBookmark(int surah, int ayah, int page) async {
    await _userRepo.deleteBookmarkByAyah(surah, ayah);
    ayahBookmarksMap.remove('$surah:$ayah');
    MushafRasterCache.instance.removePage(page);
    userMarksVersion.value++;
    update();
  }

  Future<void> setAyahMemorizeStatus({
    required int surah,
    required int ayah,
    required int page,
    required MemorizeStatus? status,
  }) async {
    if (status == null) {
      await _userRepo.deleteMemorizedByAyah(surah, ayah);
      ayahMemorizedMap.remove('$surah:$ayah');
    } else {
      final item = MemorizedItem(
        type: BookmarkType.ayah,
        page: page,
        surah: surah,
        ayah: ayah,
        status: status,
      );
      final id = await _userRepo.setMemorized(item);
      ayahMemorizedMap['$surah:$ayah'] = item.copyWith(id: id);
    }
    MushafRasterCache.instance.removePage(page);
    userMarksVersion.value++;
    update();
  }

  bool isPageBookmarked(int pageNumber) {
    return pageBookmarksMap.containsKey(pageNumber);
  }

  /// Selects an ayah for highlighting and loads its Tafseer.
  Future<void> selectAyah(int surahNumber, int ayahNumber) async {
    selectedSurah.value = surahNumber;
    selectedAyah.value = ayahNumber;

    final existing = getAyahBookmark(surahNumber, ayahNumber);
    if (existing != null) {
      selectedAyahColor.value = existing.color;
    } else {
      selectedAyahColor.value = BookmarkColor.gold;
    }

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
    MushafRasterCache.instance.clear();
    currentTheme.value = mode;
    await _settings.sharedPref?.setString(_prefThemeMode, mode.toPrefString());
    _preloadAdjacentPages(currentPage.value);
  }

  /// Navigates to a specific page.
  void goToPage(int pageNumber, {bool animate = true}) {
    final clamped = pageNumber.clamp(1, 604);
    if (clamped == currentPage.value) return;

    if (animate && paperFlipState != null) {
      if (clamped == currentPage.value + 1) {
        paperFlipState?.turnNext();
        return;
      } else if (clamped == currentPage.value - 1) {
        paperFlipState?.turnPrevious();
        return;
      }
    }

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

  // Commute Mode Handlers
  void toggleCommuteZoom() {
    if (commuteZoomScale.value < 1.1) {
      commuteZoomScale.value = 1.15;
    } else if (commuteZoomScale.value < 1.2) {
      commuteZoomScale.value = 1.25;
    } else {
      commuteZoomScale.value = 1.0;
    }
  }

  void toggleCommuteContrast() {
    commuteHighContrast.value = !commuteHighContrast.value;
    if (commuteHighContrast.value) {
      setThemeMode(MushafThemeMode.dark);
    } else {
      setThemeMode(MushafThemeMode.light);
    }
  }

  void nextCommutePage() {
    if (currentPage.value < 604) {
      goToPage(currentPage.value + 1);
    }
  }

  void prevCommutePage() {
    if (currentPage.value > 1) {
      goToPage(currentPage.value - 1);
    }
  }

  Future<void> completeCommuteWird() async {
    try {
      final repo = CommuteWirdRepository();
      final count = (currentPage.value - commuteStartPage.value).abs() + 1;
      await repo.recordProgress(
        pagesRead: count,
        toPage: currentPage.value,
        slotId: commuteSlotId.value,
        countTowardsMain: commuteCountTowardsMain.value,
      );
      isCommuteCompleted.value = true;
      AppHaptics.cycleCompleted();

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Text('🎉 '),
              Text('تقبل الله طاعتكم!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم تسجيل إتمام ورد المواصلات بنجاح ($count صفحات).',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4D3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF1B4D3E)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم تحديث سجل قراءتك وإلغاء تذكير هذا الوقت لهذا اليوم 🌿',
                        style: TextStyle(fontSize: 13, color: Color(0xFF1B4D3E), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('متابعة القراءة', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Get.back();
                Get.back();
              },
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
        barrierDismissible: true,
      );
    } catch (e) {
      debugPrint('Error completing commute wird: $e');
    }
  }
}
