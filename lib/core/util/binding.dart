import 'package:get/get.dart';
import 'package:quran_app_android/core/service/database/database_helper.dart';
import 'package:quran_app_android/core/service/database/local_storage_data.dart';
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';
import 'package:quran_app_android/features/azkar/presentation/view_model/azkar_view_model.dart';
import 'package:quran_app_android/features/hadith/presentation/view_model/hadith_view_model.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/nameOfAllah/presentation/view_model/Names_Of_Allah_view_model.dart';
import 'package:quran_app_android/features/onboarding/presentation/view_model/onboarding_view_model.dart';
import 'package:quran_app_android/features/pngtree/presentation/view_model/pngTree_view_model.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_audio_view_model.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_screen_model_details.dart';
import 'package:quran_app_android/features/quran/presentation/view_model/quran_view_model.dart';
import 'package:quran_app_android/features/settings/presentation/view_model/settins_view_model.dart';
import 'package:quran_app_android/features/tafsser/presentation/view_model/tafseer_details_view_model.dart';

class Binding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QuranScreenViewModel());
    Get.lazyPut(() => HomeViewModel());
    Get.lazyPut(() => QuranViewModel());
    Get.lazyPut(() => TafseerDetailsViewModel());
    Get.lazyPut(() => QuranAudioViewModel());
    Get.lazyPut(() => LocalStorageData());
    Get.lazyPut(() => LocalStorageAdhanData());
    Get.lazyPut(() => PngTreeViewModel());
    Get.lazyPut(() => AzkarViewModel());
    Get.lazyPut(() => NamesOfAllahViewModel());
    Get.lazyPut(() => HadithViewModel());
    Get.lazyPut(() => AdhanViewModel());
    Get.lazyPut(() => OnBoardingViewModel());
    Get.lazyPut(() => SettingsViewModel());
  }
}
