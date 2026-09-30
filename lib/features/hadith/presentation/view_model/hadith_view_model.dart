import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/widgets/custom_toast.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_model.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_model_malek.dart';

class HadithViewModel extends GetxController {
  final HadithRepository _hadithRepository;

  HadithViewModel({HadithRepository? hadithRepository})
      : _hadithRepository = hadithRepository ?? HadithRepository() {
    hadithRead();
  }

  SettingsServices c = Get.find<SettingsServices>();
  List<dynamic> items = [];
  List<HadithModel> hadithList = [];
  RxBool isLoading = false.obs;

  double fontSize = 20;
  void increaseFont() {
    fontSize++;
    update();
  }

  void decreaseFont() {
    fontSize--;
    update();
  }

  int currentIndex = 0;
  void changeIndex(index) {
    currentIndex = index;
    update();
  }

  PageController pageController = PageController();
  void addCurrentIndex(index) {
    c.sharedPref!.setInt('saveIndex', index);
    update();
  }

  void goToPage() {
    if (c.sharedPref!.getInt('saveIndex') != null) {
      if (pageController.hasClients) {
        pageController.animateToPage(
          c.sharedPref!.getInt('saveIndex')!.toInt(),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        update();
      }
    } else {
      defaultToast(text: 'لا يوجد شئ محفوظ');
    }
  }

  List<dynamic> itemsData = [];
  List<HadithModelFinal> hadithModelFinal = [];
  RxBool isLoadingg = false.obs;

  Future<void> hadithRead() async {
    try {
      isLoadingg.value = true;
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
      update();
    } catch (e, st) {
      isLoadingg.value = false;
      if (kDebugMode) {
        debugPrint('HadithViewModel error: $e\n$st');
      }
    }
  }
}
