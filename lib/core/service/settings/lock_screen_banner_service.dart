import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/service/settings/notifications_services.dart';
import 'package:quran_app_android/core/util/constant/static_vars.dart';
import 'package:quran_app_android/core/services/widget_sync_service.dart';
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LockScreenBannerModel {
  bool isEnabled;
  bool showNextPrayer;
  bool showAllPrayers;
  bool showWirdProgress;
  bool showDailyZikr;
  bool showHijriDate;
  bool showQuickActions;

  LockScreenBannerModel({
    this.isEnabled = true,
    this.showNextPrayer = true,
    this.showAllPrayers = true,
    this.showWirdProgress = true,
    this.showDailyZikr = true,
    this.showHijriDate = true,
    this.showQuickActions = true,
  });

  Map<String, dynamic> toMap() => {
        'isEnabled': isEnabled,
        'showNextPrayer': showNextPrayer,
        'showAllPrayers': showAllPrayers,
        'showWirdProgress': showWirdProgress,
        'showDailyZikr': showDailyZikr,
        'showHijriDate': showHijriDate,
        'showQuickActions': showQuickActions,
      };

  factory LockScreenBannerModel.fromPrefs(SharedPreferences prefs) {
    return LockScreenBannerModel(
      isEnabled: prefs.getBool('lockscreen_banner_enabled') ??
          prefs.getBool('prayer_banner_enabled') ??
          true,
      showNextPrayer: prefs.getBool('lockscreen_show_next_prayer') ?? true,
      showAllPrayers: prefs.getBool('lockscreen_show_all_prayers') ?? true,
      showWirdProgress: prefs.getBool('lockscreen_show_wird') ?? true,
      showDailyZikr: prefs.getBool('lockscreen_show_zikr') ?? true,
      showHijriDate: prefs.getBool('lockscreen_show_hijri') ?? true,
      showQuickActions: prefs.getBool('lockscreen_show_actions') ?? true,
    );
  }

  Future<void> saveToPrefs(SharedPreferences prefs) async {
    await prefs.setBool('lockscreen_banner_enabled', isEnabled);
    await prefs.setBool('prayer_banner_enabled', isEnabled);
    await prefs.setBool('lockscreen_show_next_prayer', showNextPrayer);
    await prefs.setBool('lockscreen_show_all_prayers', showAllPrayers);
    await prefs.setBool('lockscreen_show_wird', showWirdProgress);
    await prefs.setBool('lockscreen_show_zikr', showDailyZikr);
    await prefs.setBool('lockscreen_show_hijri', showHijriDate);
    await prefs.setBool('lockscreen_show_actions', showQuickActions);
  }
}

class BannerDisplayData {
  final String title;
  final String subText;
  final String summaryText;
  final String collapsedText;
  final String bigContentText;
  final String plainContentText;
  final String nextPrayerCountdown;
  final String allPrayersLine;
  final String allPrayersLine1;
  final String allPrayersLine2;
  final String wirdLine;
  final String zikrLine;
  final String hijriLine;
  final String cityName;
  final String nextPrayerName;
  final String nextPrayerTimeStr;
  final Prayer actualNextPrayer;
  final Map<String, String> prayerTimesMap;

  BannerDisplayData({
    required this.title,
    this.subText = '',
    required this.summaryText,
    this.collapsedText = '',
    required this.bigContentText,
    this.plainContentText = '',
    required this.nextPrayerCountdown,
    required this.allPrayersLine,
    this.allPrayersLine1 = '',
    this.allPrayersLine2 = '',
    required this.wirdLine,
    required this.zikrLine,
    required this.hijriLine,
    this.cityName = 'القاهرة',
    this.nextPrayerName = '',
    this.nextPrayerTimeStr = '',
    this.actualNextPrayer = Prayer.none,
    this.prayerTimesMap = const {},
  });
}

class LockScreenBannerService {
  LockScreenBannerService._();
  static final LockScreenBannerService instance = LockScreenBannerService._();

  Timer? _autoRefreshTimer;

  Future<LockScreenBannerModel> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return LockScreenBannerModel.fromPrefs(prefs);
  }

  Future<void> saveSettings(LockScreenBannerModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await model.saveToPrefs(prefs);
    await updateBanner();
  }

  /// Builds preview and display data matching the user's customized toggles.
  Future<BannerDisplayData> buildDisplayData([LockScreenBannerModel? customModel]) async {
    final model = customModel ?? await loadSettings();

    // 1. Hijri Date
    String hijriLine = '';
    try {
      HijriCalendar.setLocal('ar');
      final h = HijriCalendar.now();
      hijriLine = '${h.dayWeName}، ${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {
      hijriLine = 'التقويم الهجري المبارك';
    }

    // 2. City Name
    String cityName = 'القاهرة';
    if (Get.isRegistered<AdhanViewModel>()) {
      final vm = Get.find<AdhanViewModel>();
      if (vm.cityName.isNotEmpty) cityName = vm.cityName;
    } else {
      final prefs = await SharedPreferences.getInstance();
      cityName = prefs.getString('city_name') ?? 'القاهرة';
    }

    // 3. Prayer Times & Next Prayer Calculation
    String nextPrayerCountdown = '';
    String nextPrayerName = 'الصلاة';
    String nextPrayerTimeStr = '';
    Prayer actualNext = Prayer.none;
    String allPrayersHtmlLine1 = '';
    String allPrayersHtmlLine2 = '';
    String allPrayersPlainLine1 = '';
    String allPrayersPlainLine2 = '';
    final prayerTimesMap = <String, String>{};

    try {
      final pt = await _resolvePrayerTimes();
      if (pt != null) {
        final next = pt.nextPrayer();
        actualNext = next == Prayer.none ? Prayer.fajr : next;
        final nextTime = pt.timeForPrayer(actualNext) ?? DateTime.now();

        String pName(Prayer p) {
          switch (p) {
            case Prayer.fajr: return 'الفجر';
            case Prayer.sunrise: return 'الشروق';
            case Prayer.dhuhr: return 'الظهر';
            case Prayer.asr: return 'العصر';
            case Prayer.maghrib: return 'المغرب';
            case Prayer.isha: return 'العشاء';
            case Prayer.none: return 'الفجر';
          }
        }

        String fTime(DateTime dt) {
          final hour = dt.hour;
          final minute = dt.minute.toString().padLeft(2, '0');
          final isPm = hour >= 12;
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '$displayHour:$minute ${isPm ? 'م' : 'ص'}';
        }

        nextPrayerName = pName(actualNext);
        nextPrayerTimeStr = fTime(nextTime);

        prayerTimesMap['fajr'] = fTime(pt.fajr);
        prayerTimesMap['dhuhr'] = fTime(pt.dhuhr);
        prayerTimesMap['asr'] = fTime(pt.asr);
        prayerTimesMap['maghrib'] = fTime(pt.maghrib);
        prayerTimesMap['isha'] = fTime(pt.isha);

        final diff = nextTime.difference(DateTime.now());
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        final countdownStr = hours > 0
            ? '$hours س و $minutes د'
            : (minutes > 0 ? '$minutes د' : 'الآن');

        nextPrayerCountdown = 'متبقي $countdownStr';

        String formatHtmlPrayer(Prayer p) {
          final name = pName(p);
          final time = fTime(pt.timeForPrayer(p)!);
          if (p == actualNext) {
            return '<font color="#D4AF37"><b>▸ $name $time ◂</b></font>';
          }
          return '$name $time';
        }

        String formatPlainPrayer(Prayer p) {
          final name = pName(p);
          final time = fTime(pt.timeForPrayer(p)!);
          if (p == actualNext) {
            return '▸ $name $time ◂';
          }
          return '$name $time';
        }

        allPrayersHtmlLine1 = '${formatHtmlPrayer(Prayer.fajr)}  •  ${formatHtmlPrayer(Prayer.dhuhr)}  •  ${formatHtmlPrayer(Prayer.asr)}';
        allPrayersHtmlLine2 = '${formatHtmlPrayer(Prayer.maghrib)}  •  ${formatHtmlPrayer(Prayer.isha)}';

        allPrayersPlainLine1 = '${formatPlainPrayer(Prayer.fajr)}  •  ${formatPlainPrayer(Prayer.dhuhr)}  •  ${formatPlainPrayer(Prayer.asr)}';
        allPrayersPlainLine2 = '${formatPlainPrayer(Prayer.maghrib)}  •  ${formatPlainPrayer(Prayer.isha)}';
      }
    } catch (e) {
      debugPrint('⚠️ Error resolving prayer times for banner: $e');
    }

    // 4. Wird Progress
    String wirdLine = '';
    String wirdShort = '';
    try {
      final userRepo = UserRepository();
      final plan = await userRepo.getWirdPlan();
      if (plan != null && plan.enabled) {
        final lastRead = _getLastReadPage();
        final remaining = (plan.endPage - lastRead).clamp(0, 604);
        if (remaining == 0) {
          wirdLine = 'أتممت ورد اليوم المبارك (ص ${plan.startPage} - ${plan.endPage}) تقبل الله!';
          wirdShort = 'ورد اليوم: تم بحمد الله 🌿';
        } else {
          wirdLine = 'ص ${plan.startPage} إلى ${plan.endPage} • متبقي $remaining صفحات';
          wirdShort = 'الورد: ص $lastRead (متبقي $remaining)';
        }
      } else {
        final lastRead = _getLastReadPage();
        wirdLine = 'آخر موضع قراءة في المصحف: صفحة $lastRead';
        wirdShort = 'المصحف: صفحة $lastRead';
      }
    } catch (_) {
      wirdLine = 'ورد القرآن الكريم اليومي';
      wirdShort = 'ورد القرآن';
    }

    // 5. Daily Dhikr
    String zikrLine = 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ';
    try {
      final adhkar = StaticVars().smallDo3a2;
      if (adhkar.isNotEmpty) {
        final now = DateTime.now();
        final slot = now.minute ~/ 15;
        final idx = (now.hour * 4 + slot + now.day) % adhkar.length;
        zikrLine = adhkar[idx];
      }
    } catch (_) {}

    // Construct Title
    String bannerTitle = 'تطبيق تقرّب';
    if (model.showNextPrayer && nextPrayerCountdown.isNotEmpty) {
      bannerTitle = '🕌 الصلاة القادمة: $nextPrayerName • $nextPrayerTimeStr ($nextPrayerCountdown)';
    } else if (model.showHijriDate && hijriLine.isNotEmpty) {
      bannerTitle = '📅 $hijriLine';
    } else if (model.showWirdProgress && wirdShort.isNotEmpty) {
      bannerTitle = '📖 $wirdShort';
    }

    // Collapsed 1-line text for compact view
    String collapsedText = '';
    if (nextPrayerCountdown.isNotEmpty) {
      collapsedText = '⏳ $nextPrayerCountdown  │  $wirdShort';
    } else {
      collapsedText = '$cityName  •  $hijriLine';
    }

    // Construct Structured HTML Content for Expanded Android Notification
    final htmlBuffer = StringBuffer();
    final plainBuffer = StringBuffer();

    if (model.showAllPrayers && allPrayersHtmlLine1.isNotEmpty) {
      htmlBuffer.writeln('🕌 <b>مواقيت الصلاة:</b>');
      htmlBuffer.writeln('$allPrayersHtmlLine1<br/>$allPrayersHtmlLine2');
      htmlBuffer.writeln('<br/>');

      plainBuffer.writeln('🕌 مواقيت الصلاة:');
      plainBuffer.writeln('$allPrayersPlainLine1\n$allPrayersPlainLine2');
      plainBuffer.writeln('');
    }

    if (model.showWirdProgress && wirdLine.isNotEmpty) {
      htmlBuffer.writeln('📖 <b>الورد القرآني:</b> $wirdLine<br/>');
      plainBuffer.writeln('📖 الورد القرآني: $wirdLine');
    }

    if (model.showDailyZikr && zikrLine.isNotEmpty) {
      htmlBuffer.writeln('📿 <b>ذكر الوقت:</b> «$zikrLine»<br/>');
      plainBuffer.writeln('📿 ذكر الوقت: «$zikrLine»');
    }

    if (model.showHijriDate && hijriLine.isNotEmpty) {
      htmlBuffer.writeln('📅 <b>التاريخ:</b> $hijriLine');
      plainBuffer.writeln('📅 التاريخ: $hijriLine');
    }

    if (htmlBuffer.isEmpty) {
      htmlBuffer.writeln('ألا بذكر الله تطمئن القلوب 🌿');
      plainBuffer.writeln('ألا بذكر الله تطمئن القلوب 🌿');
    }

    final allPrayersUnified = '$allPrayersPlainLine1 • $allPrayersPlainLine2';

    return BannerDisplayData(
      title: bannerTitle,
      subText: 'تقرّب • $cityName',
      summaryText: 'مواقيت الصلاة والورد',
      collapsedText: collapsedText,
      bigContentText: htmlBuffer.toString().trim(),
      plainContentText: plainBuffer.toString().trim(),
      nextPrayerCountdown: nextPrayerCountdown,
      allPrayersLine: allPrayersUnified,
      allPrayersLine1: allPrayersPlainLine1,
      allPrayersLine2: allPrayersPlainLine2,
      wirdLine: wirdLine,
      zikrLine: zikrLine,
      hijriLine: hijriLine,
      cityName: cityName,
      nextPrayerName: nextPrayerName,
      nextPrayerTimeStr: nextPrayerTimeStr,
      actualNextPrayer: actualNext,
      prayerTimesMap: prayerTimesMap,
    );
  }

  /// Updates or refreshes the Android Lock Screen Ongoing Notification.
  Future<void> updateBanner() async {
    final model = await loadSettings();
    final notify = NotifyHelper();

    if (!model.isEnabled) {
      await notify.cancelOngoingPrayerBanner();
      _autoRefreshTimer?.cancel();
      debugPrint('🔔 [LockScreenBannerService] Lock screen banner disabled and cancelled.');
      return;
    }

    // Ensure permissions are ready
    try {
      await notify.ensureSchedulingPermissions(requestIfNeeded: false);
    } catch (_) {}

    final data = await buildDisplayData(model);

    try {
      if (data.nextPrayerName.isNotEmpty && data.nextPrayerTimeStr.isNotEmpty) {
        unawaited(WidgetSyncService.syncPrayerTimes(
          nextPrayerName: data.nextPrayerName,
          nextPrayerTime: data.nextPrayerTimeStr,
          cityName: data.cityName,
        ));
      }
    } catch (_) {}

    final actions = <AndroidNotificationAction>[];
    if (model.showQuickActions) {
      actions.addAll([
        const AndroidNotificationAction(
          'action_mushaf',
          '📖 الورد',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'action_azkar',
          '📿 الأذكار',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'action_prayer',
          '🕌 المواقيت',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ]);
    }

    final androidDetails = AndroidNotificationDetails(
      'prayer_banner_channel_v2',
      'شريط مواقيت الصلاة وشاشة القفل',
      channelDescription: 'عرض دائم وأنيق لمواقيت الصلاة، الورد القرآني، والأذكار على شاشة القفل',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      icon: 'ic_mosque',
      color: const Color(0xFF0F5C4A),
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      subText: data.subText,
      styleInformation: BigTextStyleInformation(
        data.bigContentText,
        contentTitle: data.title,
        summaryText: data.summaryText,
        htmlFormatContent: true,
        htmlFormatContentTitle: true,
        htmlFormatSummaryText: true,
      ),
      actions: actions.isNotEmpty ? actions : null,
    );

    await notify.flutterLocalNotificationsPlugin.show(
      NotifyHelper.prayerBannerNotificationId,
      data.title,
      data.collapsedText.isNotEmpty ? data.collapsedText : data.plainContentText,
      NotificationDetails(android: androidDetails),
      payload: 'taqarrab://prayer_times',
    );

    _startAutoRefreshTimer();
    debugPrint('✅ [LockScreenBannerService] Lock screen banner successfully updated.');
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      updateBanner();
    });
  }

  Future<PrayerTimes?> _resolvePrayerTimes() async {
    if (Get.isRegistered<AdhanViewModel>()) {
      final vm = Get.find<AdhanViewModel>();
      if (vm.prayerTimes != null) return vm.prayerTimes;
    }

    final nativeMap = await NativeAdhanBridge.getSettings();
    double lat = 30.0444; // Cairo default
    double lng = 31.2357;
    if (nativeMap != null && nativeMap.containsKey('latitude')) {
      final nLat = (nativeMap['latitude'] as num?)?.toDouble() ?? 0.0;
      final nLng = (nativeMap['longitude'] as num?)?.toDouble() ?? 0.0;
      if (nLat != 0.0 && nLng != 0.0) {
        lat = nLat;
        lng = nLng;
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final pLat = prefs.getDouble('lat') ?? 0.0;
      final pLng = prefs.getDouble('lng') ?? 0.0;
      if (pLat != 0.0 && pLng != 0.0) {
        lat = pLat;
        lng = pLng;
      }
    }

    final coords = Coordinates(lat, lng);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    return PrayerTimes.today(coords, params);
  }

  int _getLastReadPage() {
    try {
      if (Get.isRegistered<SettingsServices>()) {
        final last = Get.find<SettingsServices>().sharedPref?.getInt('mushaf_last_page');
        if (last != null && last >= 1 && last <= 604) return last;
      }
    } catch (_) {}
    return 1;
  }
}
