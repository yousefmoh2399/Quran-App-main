import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_model.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_model_malek.dart';

class HadithViewModel extends GetxController {
  final HadithRepository _hadithRepository;

  HadithViewModel({HadithRepository? hadithRepository})
      : _hadithRepository = hadithRepository ?? HadithRepository() {
    hadithRead();
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

  void addCurrentIndex(int index) {
    settings.sharedPref?.setInt('saveIndex', index);
    update();
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
