import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/quran/data/models/juz_model.dart';
import 'package:quran_app_android/features/quran/data/models/model.dart';
import '../views/widget/quran_filter_chips_bar.dart';

class QuranViewModel extends GetxController {
  final QuranRepository _quranRepository;
  final UserRepository _userRepository;

  QuranViewModel({
    QuranRepository? quranRepository,
    UserRepository? userRepository,
  })  : _quranRepository = quranRepository ?? QuranRepository(),
        _userRepository = userRepository ?? UserRepository();

  final SettingsServices settingsServices = Get.find<SettingsServices>();
  late final PageController pageController;
  int currentPage = 0;
  bool isLoading = false;
  List<dynamic> items = [];
  List<NameModel> nameModel = [];

  final TextEditingController searchController = TextEditingController();

  // Aggregated marks for Surahs and Juzs
  QuranMarksAggregate? marksAggregate;
  QuranIndexFilter activeFilter = QuranIndexFilter.all;

  @override
  void onInit() {
    super.onInit();
    final savedPage =
        settingsServices.sharedPref?.getInt('lastVisitedSurahPage') ?? 0;
    currentPage = savedPage;
    pageController = PageController(initialPage: savedPage);
    readJson();
  }

  @override
  void onClose() {
    pageController.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> readJson() async {
    try {
      isLoading = true;
      update();
      final surahs = await _quranRepository.getSurahs();
      nameModel
        ..clear()
        ..addAll(
          surahs.map(
            (s) => NameModel(
              id: s.id,
              name: s.nameAr,
              total_verses: s.totalVerses,
              transliteration: s.transliteration,
              type: s.type,
            ),
          ),
        );
      items = nameModel;

      if (nameModel.isNotEmpty) {
        final int safePage =
            currentPage.clamp(0, nameModel.length - 1);
        if (safePage != currentPage) {
          currentPage = safePage;
        }
        if (pageController.hasClients) {
          pageController.jumpToPage(currentPage);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (pageController.hasClients) {
              pageController.jumpToPage(currentPage);
            }
          });
        }
      }

      await loadMarks();
    } finally {
      isLoading = false;
      update();
    }
  }

  /// High-performance aggregated marks retrieval across all 114 Surahs and 30 Juzs.
  Future<void> loadMarks() async {
    try {
      final structure = await _quranRepository.getQuranIndexStructure();
      final prefs = settingsServices.sharedPref;

      final lastReadPage = prefs?.getInt('mushaf_last_page');
      final lastReadSurah = prefs?.getInt('mushaf_last_surah');
      final lastReadSurahName = prefs?.getString('mushaf_last_surah_name');

      marksAggregate = await _userRepository.getMarksAggregate(
        structure: structure,
        lastReadPage: lastReadPage,
        lastReadSurah: lastReadSurah,
        lastReadSurahName: lastReadSurahName,
      );
    } catch (e) {
      debugPrint('Error loading quran marks aggregate: $e');
    } finally {
      update();
    }
  }

  void setFilter(QuranIndexFilter filter) {
    if (activeFilter != filter) {
      activeFilter = filter;
      update();
    }
  }

  bool matchesSurahFilter(NameModel surah) {
    if (activeFilter == QuranIndexFilter.all) return true;
    final m = marksAggregate?.surahs[surah.id];
    if (activeFilter == QuranIndexFilter.memorized) {
      return (m?.memorizedAyahsCount ?? 0) > 0;
    }
    if (activeFilter == QuranIndexFilter.marked) {
      return (m?.hasBookmark == true) || (m?.isLastRead == true);
    }
    return true;
  }

  bool matchesJuzFilter(JuzModel juz) {
    if (activeFilter == QuranIndexFilter.all) return true;
    final m = marksAggregate?.juzs[juz.number];
    if (activeFilter == QuranIndexFilter.memorized) {
      return (m?.memorizedAyahsCount ?? 0) > 0;
    }
    if (activeFilter == QuranIndexFilter.marked) {
      return (m?.hasBookmark == true) || (m?.isLastRead == true);
    }
    return true;
  }

  int get memorizedSurahsCount =>
      marksAggregate?.surahs.values.where((s) => s.memorizedAyahsCount > 0).length ?? 0;

  int get markedSurahsCount =>
      marksAggregate?.surahs.values.where((s) => s.hasBookmark || s.isLastRead).length ?? 0;

  int get memorizedJuzsCount =>
      marksAggregate?.juzs.values.where((j) => j.memorizedAyahsCount > 0).length ?? 0;

  int get markedJuzsCount =>
      marksAggregate?.juzs.values.where((j) => j.hasBookmark || j.isLastRead).length ?? 0;

  void onPageChanged(int index) {
    currentPage = index;
    settingsServices.sharedPref?.setInt('lastVisitedSurahPage', index);
    update();
  }
}
