import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/middleware/middleware.dart';
import 'package:quran_app_android/core/util/binding.dart';
import 'package:quran_app_android/core/util/constant/constant.dart';
import 'package:quran_app_android/features/adhan/presentation/views/adhan_view.dart';
import 'package:quran_app_android/features/azkar/presentation/views/azkar_details_view.dart';
import 'package:quran_app_android/features/azkar/presentation/views/azkar_view.dart';
import 'package:quran_app_android/features/bookmarks/presentation/views/bookmarks_view.dart';
import 'package:quran_app_android/features/hadith/presentation/views/hadith__view.dart';
import 'package:quran_app_android/features/hadith/presentation/views/hadith_details_view.dart';
import 'package:quran_app_android/features/home/presentation/views/home_view.dart';
import 'package:quran_app_android/features/nameOfAllah/presentation/views/name_of_allah_view.dart';
import 'package:quran_app_android/features/notifications/views/adhan_overlay_view.dart';
import 'package:quran_app_android/features/notifications/views/notify_view.dart';
import 'package:quran_app_android/features/onboarding/presentation/views/onboarding_screen.dart';
import 'package:quran_app_android/features/mushaf/presentation/views/mushaf_font_debug_view.dart';
import 'package:quran_app_android/features/mushaf/presentation/views/mushaf_view.dart';
import 'package:quran_app_android/features/pngtree/presentation/views/pngTreeView.dart';
import 'package:quran_app_android/features/qiblah/presentation/views/qiblah_view.dart';
import 'package:quran_app_android/features/quran/presentation/views/quran_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/permissions_status_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/settings_view.dart';
import 'package:quran_app_android/features/tafsser/presentation/views/tafseer_details_view.dart';
import 'package:quran_app_android/features/tafsser/presentation/views/tafseer_view.dart';

class AppRoutes {
  static List<GetPage> routes = [
    GetPage(
      name: home,
      page: () => HomeView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: tafsser,
      bindings: [Binding()],
      page: () => TafseerView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: hadith,
      bindings: [Binding()],
      page: () => HadithView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: quranScreen,
      // bindings: [Binding()],
      page: () => QuranScreen(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: nameofAllah,
      // bindings: [Binding()],
      page: () => const NameOfAllahView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: detailsTafseer,
      page: () => const TafseerDetailsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: pngTree,
      page: () => PngTreeView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: azkar,
      page: () => AzkarView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: azkarDetails,
      page: () => DetailesAzkarView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: adhan,
      page: () =>  AdhanView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: notify,
      page: () => const NotifyView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: adhanAlert,
      page: () => const AdhanOverlayView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: qiblah,
      page: () => const QiblahView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: detailsScreen,
      page: () => const MushafView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: mushaf,
      page: () => const MushafView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    if (kDebugMode)
      GetPage(
        name: mushafDebug,
        page: () => const MushafFontDebugView(),
        transition: Transition.cupertino,
        transitionDuration: kTransitionDuration,
      ),
    GetPage(
      name: onboarding,
      page: () => OnBoardingScreen(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
      middlewares: [AuthMiddleWare()],
    ),
    GetPage(
      name: sectionHadith,
      page: () => const SectionHadithView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: settings,
      page: () =>   SettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: permissionsStatus,
      page: () => const PermissionsStatusView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: bookmarks,
      page: () => const BookmarksView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
  ];

  static String home = '/home';
  static String bookmarks = '/bookmarks';
  static String settings = '/settings';
  static String permissionsStatus = '/permissionsStatus';
  static String tafsser = '/tafsser';
  static String hadith = '/hadith';
  static String nameofAllah = '/nameofAllah';
  static String detailsTafseer = '/detailsTafseer';
  static String pngTree = '/pngTree';
  static String azkar = '/azkar';
  static String azkarDetails = '/azkarDetails';
  static String adhan = '/adhan';
  static String notify = '/notify';
  static String adhanAlert = '/adhanAlert';
  static String qiblah = '/qiblah';
  static String quranScreen = '/quranScreen';
  static String detailsScreen = '/detailsScreen';
  static String mushaf = '/mushaf';
  static String mushafDebug = '/mushafDebug';
  static String onboarding = '/onboarding';
  static String sectionHadith = '/sectionHadith';
}
