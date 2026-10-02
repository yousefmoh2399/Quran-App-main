import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/service/settings/notifications_services.dart';
import 'package:quran_app_android/core/util/constant/static_vars.dart';
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
      // Keep in sync with legacy prayer_banner_enabled if exists
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
  final String bigContentText;
  final String summaryText;
  final String nextPrayerCountdown;
  final String allPrayersLine;
  final String wirdLine;
  final String zikrLine;
  final String hijriLine;

  BannerDisplayData({
    required this.title,
    required this.bigContentText,
    required this.summaryText,
    required this.nextPrayerCountdown,
    required this.allPrayersLine,
    required this.wirdLine,
    required this.zikrLine,
    required this.hijriLine,
  });
}

class LockScreenBannerService {
  LockScreenBannerService._();
  static final LockScreenBannerService instance = LockScreenBannerService._();

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
      hijriLine = '📅 ${h.hDay} ${h.longMonthName} ${h.hYear} هـ';
    } catch (_) {
      hijriLine = '📅 التقويم الهجري المبارك';
    }

    // 2. Prayer Times & Next Prayer
    String nextPrayerCountdown = '';
    String allPrayersLine = '';
    try {
      final pt = await _resolvePrayerTimes();
      if (pt != null) {
        final next = pt.nextPrayer();
        final actualNext = next == Prayer.none ? Prayer.fajr : next;
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

        final diff = nextTime.difference(DateTime.now());
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        final countdownStr = hours > 0
            ? 'متبقي $hours س و $minutes د'
            : (minutes > 0 ? 'متبقي $minutes د' : 'الآن');

        nextPrayerCountdown = '🕌 الصلاة القادمة: ${pName(actualNext)} ${fTime(nextTime)} ($countdownStr)';
        allPrayersLine = 'الفجر: ${fTime(pt.fajr)} | الظهر: ${fTime(pt.dhuhr)} | العصر: ${fTime(pt.asr)} | المغرب: ${fTime(pt.maghrib)} | العشاء: ${fTime(pt.isha)}';
      }
    } catch (e) {
      debugPrint('⚠️ Error resolving prayer times for banner: $e');
    }

    // 3. Wird Progress
    String wirdLine = '';
    try {
      final userRepo = UserRepository();
      final plan = await userRepo.getWirdPlan();
      if (plan != null) {
        final lastRead = _getLastReadPage();
        final remaining = (plan.endPage - lastRead).clamp(0, 604);
        if (remaining == 0) {
          wirdLine = '📖 ورد اليوم: أتممت وردك المبارك (ص ${plan.startPage} - ${plan.endPage}) تقبل الله!';
        } else {
          wirdLine = '📖 ورد اليوم: ص ${plan.startPage} إلى ${plan.endPage} • متبقي $remaining صفحات';
        }
      } else {
        final lastRead = _getLastReadPage();
        wirdLine = '📖 متابعة القرآن: آخر موضع قراءة (صفحة $lastRead)';
      }
    } catch (_) {
      wirdLine = '📖 ورد القرآن الكريم اليومي';
    }

    // 4. Daily Zikr
    String zikrLine = '';
    try {
      final adhkar = StaticVars().smallDo3a2;
      if (adhkar.isNotEmpty) {
        // Pick consistent dhikr based on current hour to avoid flashing on every refresh
        final idx = (DateTime.now().hour + DateTime.now().day) % adhkar.length;
        zikrLine = '📿 ذكر الوقت: «${adhkar[idx]}»';
      }
    } catch (_) {
      zikrLine = '📿 «سبحان الله وبحمده، سبحان الله العظيم»';
    }

    // Construct Title
    String bannerTitle = 'تطبيق تقرّب • شاشة القفل';
    if (model.showNextPrayer && nextPrayerCountdown.isNotEmpty) {
      bannerTitle = nextPrayerCountdown;
    } else if (model.showHijriDate && hijriLine.isNotEmpty) {
      bannerTitle = hijriLine;
    } else if (model.showWirdProgress && wirdLine.isNotEmpty) {
      bannerTitle = wirdLine;
    }

    // Construct Big Content Text Lines
    final List<String> bigLines = [];

    if (model.showHijriDate && hijriLine.isNotEmpty && bannerTitle != hijriLine) {
      bigLines.add(hijriLine);
    }
    if (model.showAllPrayers && allPrayersLine.isNotEmpty) {
      bigLines.add(allPrayersLine);
    }
    if (model.showWirdProgress && wirdLine.isNotEmpty && bannerTitle != wirdLine) {
      bigLines.add(wirdLine);
    }
    if (model.showDailyZikr && zikrLine.isNotEmpty) {
      bigLines.add(zikrLine);
    }

    // Fallback if empty
    if (bigLines.isEmpty) {
      bigLines.add('ألا بذكر الله تطمئن القلوب 🌿');
    }

    return BannerDisplayData(
      title: bannerTitle,
      bigContentText: bigLines.join('\n'),
      summaryText: 'مواقيت الصلاة والورد',
      nextPrayerCountdown: nextPrayerCountdown,
      allPrayersLine: allPrayersLine,
      wirdLine: wirdLine,
      zikrLine: zikrLine,
      hijriLine: hijriLine,
    );
  }

  /// Updates or refreshes the actual Android Lock Screen Ongoing Notification.
  Future<void> updateBanner() async {
    final model = await loadSettings();
    final notify = NotifyHelper();

    if (!model.isEnabled) {
      await notify.cancelOngoingPrayerBanner();
      debugPrint('🔔 [LockScreenBannerService] Lock screen banner disabled and cancelled.');
      return;
    }

    final data = await buildDisplayData(model);

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
      'prayer_banner_channel',
      'شريط مواقيت الصلاة وشاشة القفل',
      channelDescription: 'عرض دائم وأنيق لمواقيت الصلاة، الورد القرآني، والأذكار على شاشة القفل',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      icon: 'icon',
      visibility: NotificationVisibility.public, // Crucial for full lock screen display
      styleInformation: BigTextStyleInformation(
        data.bigContentText,
        contentTitle: data.title,
        summaryText: data.summaryText,
      ),
      color: const Color(0xFF0F5C4A),
      actions: actions.isNotEmpty ? actions : null,
    );

    await notify.flutterLocalNotificationsPlugin.show(
      NotifyHelper.prayerBannerNotificationId,
      data.title,
      data.bigContentText,
      NotificationDetails(android: androidDetails),
      payload: 'taqarrab://prayer_times',
    );

    debugPrint('✅ [LockScreenBannerService] Lock screen banner successfully updated.');
  }

  Future<PrayerTimes?> _resolvePrayerTimes() async {
    if (Get.isRegistered<AdhanViewModel>()) {
      final vm = Get.find<AdhanViewModel>();
      if (vm.prayerTimes != null) return vm.prayerTimes;
    }

    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('lat') ?? 30.0444; // Cairo default
    final lng = prefs.getDouble('lng') ?? 31.2357;
    if (lat == 0.0 && lng == 0.0) return null;

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
