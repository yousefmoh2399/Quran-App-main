import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';
import 'package:quran_app_android/core/native/native_azkar_bridge.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/service/settings/notifications_services.dart';
import 'package:quran_app_android/core/util/assets.dart';
import 'package:quran_app_android/core/util/constant/static_vars.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

class HomeViewModel extends GetxController {
  HomeViewModel() {
    _init();
  }

  final SettingsServices settingsServices = Get.find<SettingsServices>();
  final StaticVars staticVars = StaticVars();
  final UserRepository _userRepo = UserRepository();

  RxString lastRead = ''.obs;
  final RxnInt lastReadPage = RxnInt();
  final Rxn<BookmarkItem> latestBookmark = Rxn<BookmarkItem>();
  final Rxn<WirdPlan> currentWirdPlan = Rxn<WirdPlan>();
  final RxInt todayPagesRead = 0.obs;

  String currentZekr = 'سبحان الله';
  String appGroupId = 'group.com.homeScreenApp';
  String iOSWidgetName = 'MyHomeWidget';
  String androidWidgetName = 'MyHomeWidget';
  String dataKey = 'currentZekr';

  Future<void> _init() async {
    await getLastRead();
    await loadUserQuranData();
    await _setupHomeWidget();
    await NativeAzkarBridge.scheduleDailyAzkar(2);
    await NativeAdhanBridge.scheduleDailyReset();
  }

  Future<void> getLastRead() async {
    final prefs = settingsServices.sharedPref;
    if (prefs != null && prefs.getString('lastRead') != null) {
      lastRead.value = prefs.getString('lastRead')!;
      update();
    }
  }

  Future<void> loadUserQuranData() async {
    try {
      final savedPage = settingsServices.sharedPref?.getInt('mushaf_last_page');
      final logLast = await _userRepo.getLastReadPage();
      lastReadPage.value = savedPage ?? logLast ?? 1;

      final bm = await _userRepo.getLatestBookmark();
      latestBookmark.value = bm;

      final plan = await _userRepo.getWirdPlan();
      currentWirdPlan.value = plan;

      final todayLog = await _userRepo.getTodayReadingLog();
      todayPagesRead.value = todayLog?.pagesRead ?? 0;

      if (plan != null && plan.enabled) {
        await NotifyHelper().scheduleDailyWirdNotification();
      }

      await getLastRead();
      update();
    } catch (e) {
      debugPrint('Error loading user Quran data: $e');
    }
  }

  Future<void> markWirdCompleted() async {
    final updated = await _userRepo.markTodayWirdCompleted();
    if (updated != null) {
      currentWirdPlan.value = updated;
      await NotifyHelper().cancelWirdNotifications();
      update();
    }
  }

  Future<void> saveWirdPlan(WirdPlan plan) async {
    await _userRepo.saveWirdPlan(plan);
    currentWirdPlan.value = plan;
    if (plan.enabled) {
      await NotifyHelper().scheduleDailyWirdNotification();
    } else {
      await NotifyHelper().cancelWirdNotifications();
    }
    update();
  }

  Future<void> _setupHomeWidget() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      await Future.delayed(const Duration(seconds: 2));
      await _updateWidget();
    } catch (e, st) {
      debugPrint('⚠️ HomeWidget init failed: $e\n$st');
    }
  }

  Future<void> _updateWidget() async {
    try {
      final randomIndex = DateTime.now().second % staticVars.smallDo3a2.length;
      currentZekr = staticVars.smallDo3a2[randomIndex];
      await HomeWidget.saveWidgetData(dataKey, currentZekr);
      await HomeWidget.saveWidgetData('deepLink', 'quranapp://azkar');
      await Future.delayed(const Duration(seconds: 1));
      await HomeWidget.updateWidget(
        iOSName: 'MyHomeWidget',
        androidName: 'com.example.quran_app_android.MyHomeWidget',
      );
      debugPrint('✅ Widget updated successfully');
    } catch (e, st) {
      debugPrint('⚠️ Widget update failed: $e\n$st');
    }
  }

  // 🕌 بيانات الصفحة الرئيسية
  List<String> titles = ['القرآن الكريم', 'حديث', 'أسماء الله الحسنى', 'تفسير'];

  List<String> images = [
    AssetsData.mushaf_1,
    AssetsData.moon,
    AssetsData.nameOfAllah,
    AssetsData.mushaf,
  ];

  List<String> routes = [
    AppRoutes.quranScreen,
    AppRoutes.sectionHadith,
    AppRoutes.nameofAllah,
    AppRoutes.tafsser,
  ];

  List<String> titleListView = ['أذكار', 'مواقيت الصلاة', 'القبلة', 'المسبحة'];

  List<String> imageListView = [
    AssetsData.azkar,
    AssetsData.ramadan,
    AssetsData.qiblahImage,
    AssetsData.pngTree,
  ];

  List<String> routesListView = [
    AppRoutes.azkar,
    AppRoutes.adhan,
    AppRoutes.qiblah,
    AppRoutes.pngTree,
  ];
  TextEditingController timeController = TextEditingController();
  var formKey = GlobalKey<FormState>();
}
