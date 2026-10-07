import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/middleware/middleware.dart';
import 'package:quran_app_android/core/util/binding.dart';
import 'package:quran_app_android/core/util/constant/constant.dart';
import 'package:quran_app_android/features/adhan/presentation/views/adhan_view.dart';
import 'package:quran_app_android/features/adhan/presentation/views/adhan_settings_view.dart';
import 'package:quran_app_android/features/adhan/presentation/views/adhan_debug_view.dart';
import 'package:quran_app_android/features/azkar/presentation/views/azkar_details_view.dart';
import 'package:quran_app_android/features/azkar/presentation/views/azkar_notifications_settings_view.dart';
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
import 'package:quran_app_android/features/reminders/presentation/views/my_reminders_view.dart';
import 'package:quran_app_android/features/reminders/presentation/views/sadaqah_settings_view.dart';
import 'package:quran_app_android/features/reminders/presentation/views/sadaqah_logs_view.dart';
import 'package:quran_app_android/features/reminders/presentation/views/commute_wird_settings_view.dart';
import 'package:quran_app_android/features/reminders/presentation/views/wird_reminder_settings_view.dart';
import 'package:quran_app_android/features/reminders/presentation/views/notification_sounds_settings_view.dart';
import 'package:quran_app_android/features/reminders/presentation/views/reminders_debug_view.dart';
import 'package:quran_app_android/features/pngtree/presentation/views/pngTreeView.dart';
import 'package:quran_app_android/features/qiblah/presentation/views/qiblah_view.dart';
import 'package:quran_app_android/features/quran/presentation/views/quran_view.dart';
import 'package:quran_app_android/features/quran/presentation/views/quran_search_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/permissions_status_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/settings_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/lock_screen_banner_settings_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/backup_restore_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/privacy_policy_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/about_app_view.dart';
import 'package:quran_app_android/features/settings/presentation/views/support_app_view.dart';
import 'package:quran_app_android/features/share/presentation/views/app_share_view.dart';
import 'package:quran_app_android/features/prayers_tracker/presentation/views/prayer_tracker_view.dart';
import 'package:quran_app_android/features/prayers_tracker/presentation/views/post_prayer_azkar_view.dart';
import 'package:quran_app_android/features/calendar/presentation/views/islamic_calendar_view.dart';
import 'package:quran_app_android/features/calendar/presentation/views/ramadan_imsakia_view.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_hub_view.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_khatma_view.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_cannon_suhoor_view.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_taraweeh_view.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_duas_view.dart';
import 'package:quran_app_android/features/ramadan/presentation/views/ramadan_zakat_view.dart';
import 'package:quran_app_android/features/stats/presentation/views/achievements_dashboard_view.dart';
import 'package:quran_app_android/features/splash/presentation/views/splash_screen_view.dart';
import 'package:quran_app_android/features/tafsser/presentation/views/tafseer_details_view.dart';
import 'package:quran_app_android/features/tafsser/presentation/views/tafseer_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/congestion_estimates_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/sai_counter_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/tawaf_counter_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/trip_diary_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/umrah_guide_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/umrah_hub_view.dart';
import 'package:quran_app_android/features/umrah/presentation/views/umrah_sources_review_view.dart';

class AppRoutes {
  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreenView(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),
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
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 250),
      popGesture: false,
    ),
    GetPage(
      name: mushaf,
      page: () => const MushafView(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 250),
      popGesture: false,
    ),
    GetPage(
      name: quranSearch,
      page: () => const QuranSearchView(),
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
    GetPage(
      name: adhanSettings,
      page: () => const AdhanSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: azkarNotificationsSettings,
      page: () => const AzkarNotificationsSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: myReminders,
      page: () => const MyRemindersView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: sadaqahSettings,
      page: () => const SadaqahSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: sadaqahLogs,
      page: () => const SadaqahLogsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: commuteWirdSettings,
      page: () => const CommuteWirdSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: wirdSettings,
      page: () => const WirdReminderSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: notificationSoundsSettings,
      page: () => const NotificationSoundsSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: prayerTracker,
      page: () => const PrayerTrackerView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: postPrayerAzkar,
      page: () => const PostPrayerAzkarView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: islamicCalendar,
      page: () => const IslamicCalendarView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: ramadanImsakia,
      page: () => const RamadanImsakiaView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: ramadanHub,
      page: () => const RamadanHubView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: ramadanKhatma,
      page: () => const RamadanKhatmaView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: ramadanCannonSuhoor,
      page: () => const RamadanCannonSuhoorView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: ramadanTaraweeh,
      page: () => const RamadanTaraweehView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: ramadanDuas,
      page: () => const RamadanDuasView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: ramadanZakat,
      page: () => const RamadanZakatView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: achievements,
      page: () => const AchievementsDashboardView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: backupRestore,
      page: () => const BackupRestoreView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: lockScreenBannerSettings,
      page: () => const LockScreenBannerSettingsView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: privacyPolicy,
      page: () => const PrivacyPolicyView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: aboutApp,
      page: () => const AboutAppView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: supportApp,
      page: () => const SupportAppView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: appShare,
      page: () => const AppShareView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: umrahHub,
      page: () => const UmrahHubView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: umrahGuide,
      page: () => const UmrahGuideView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: tawafCounter,
      page: () => const TawafCounterView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: saiCounter,
      page: () => const SaiCounterView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: umrahEstimates,
      page: () => const CongestionEstimatesView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: umrahDiary,
      page: () => const TripDiaryView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    GetPage(
      name: umrahSources,
      page: () => const UmrahSourcesReviewView(),
      transition: Transition.cupertino,
      transitionDuration: kTransitionDuration,
    ),
    if (kDebugMode) ...[
      GetPage(
        name: adhanDebug,
        page: () => const AdhanDebugView(),
        transition: Transition.cupertino,
        transitionDuration: kTransitionDuration,
      ),
      GetPage(
        name: remindersDebug,
        page: () => const RemindersDebugView(),
        transition: Transition.cupertino,
        transitionDuration: kTransitionDuration,
      ),
    ],
  ];

  static String splash = '/splash';
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
  static String azkarNotificationsSettings = '/azkarNotificationsSettings';
  static String myReminders = '/myReminders';
  static String sadaqahSettings = '/sadaqahSettings';
  static String sadaqahLogs = '/sadaqahLogs';
  static String commuteWirdSettings = '/commuteWirdSettings';
  static String wirdSettings = '/wirdSettings';
  static String notificationSoundsSettings = '/notificationSoundsSettings';
  static String prayerTracker = '/prayerTracker';
  static String lockScreenBannerSettings = '/lockScreenBannerSettings';
  static String postPrayerAzkar = '/postPrayerAzkar';
  static String islamicCalendar = '/islamicCalendar';
  static String ramadanImsakia = '/ramadanImsakia';
  static String ramadanHub = '/ramadanHub';
  static String ramadanKhatma = '/ramadanKhatma';
  static String ramadanCannonSuhoor = '/ramadanCannonSuhoor';
  static String ramadanTaraweeh = '/ramadanTaraweeh';
  static String ramadanDuas = '/ramadanDuas';
  static String ramadanZakat = '/ramadanZakat';
  static String achievements = '/achievements';
  static String backupRestore = '/backupRestore';
  static String privacyPolicy = '/privacyPolicy';
  static String aboutApp = '/aboutApp';
  static String supportApp = '/supportApp';
  static String appShare = '/appShare';
  static String adhan = '/adhan';
  static String adhanSettings = '/adhanSettings';
  static String adhanDebug = '/adhanDebug';
  static String remindersDebug = '/remindersDebug';
  static String notify = '/notify';
  static String adhanAlert = '/adhanAlert';
  static String qiblah = '/qiblah';
  static String quranScreen = '/quranScreen';
  static String detailsScreen = '/detailsScreen';
  static String mushaf = '/mushaf';
  static String quranSearch = '/quranSearch';
  static String mushafDebug = '/mushafDebug';
  static String onboarding = '/onboarding';
  static String sectionHadith = '/sectionHadith';
  static String umrahHub = '/umrahHub';
  static String umrahGuide = '/umrahGuide';
  static String tawafCounter = '/tawafCounter';
  static String saiCounter = '/saiCounter';
  static String umrahEstimates = '/umrahEstimates';
  static String umrahDiary = '/umrahDiary';
  static String umrahSources = '/umrahSources';
}
