import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/quran/data/models/model.dart';

class QuranViewModel extends GetxController {
  final QuranRepository _quranRepository;

  QuranViewModel({QuranRepository? quranRepository})
      : _quranRepository = quranRepository ?? QuranRepository();

  final SettingsServices settingsServices = Get.find<SettingsServices>();
  late final PageController pageController;
  int currentPage = 0;
  bool isLoading = false;
  List<dynamic> items = [];
  List<NameModel> nameModel = [];

  final TextEditingController searchController = TextEditingController();

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
    } finally {
      isLoading = false;
      update();
    }
  }

  void onPageChanged(int index) {
    currentPage = index;
    settingsServices.sharedPref?.setInt('lastVisitedSurahPage', index);
    update();
  }
}
