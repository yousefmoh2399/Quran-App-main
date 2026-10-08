import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetSyncService {
  static const String appGroupId = 'group.com.yousefmohamed.quranApp';
  static const String androidWirdWidget = 'com.example.quran_app_android.widgets.WirdKhatmaWidgetProvider';
  static const String iOSWirdWidget = 'WirdKhatmaWidget';
  static const String androidPrayerWidget = 'com.example.quran_app_android.widgets.PrayerTimesWidgetProvider';
  static const String iOSPrayerWidget = 'PrayerTimesWidget';
  static const String androidRamadanWidget = 'com.example.quran_app_android.widgets.RamadanWidgetProvider';
  static const String iOSRamadanWidget = 'RamadanWidget';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Error setting AppGroupId for HomeWidget: $e');
    }
  }

  /// Synchronize Wird / Khatma reading progress across home screen widgets
  static Future<void> syncWirdProgress({
    required int streak,
    required int targetPages,
    required int completedPages,
    required int lastPage,
    String planTitle = 'الورد اليومي',
  }) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      // Save for iOS WidgetKit
      await HomeWidget.saveWidgetData<int>('wird_streak', streak);
      await HomeWidget.saveWidgetData<int>('wird_target', targetPages);
      await HomeWidget.saveWidgetData<int>('wird_completed', completedPages);
      await HomeWidget.saveWidgetData<int>('wird_last_page', lastPage);
      await HomeWidget.saveWidgetData<String>('wird_plan_title', planTitle);

      // Save for Android Native SharedPreferences
      if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('wird_streak', streak);
        await prefs.setInt('wird_target', targetPages);
        await prefs.setInt('wird_completed', completedPages);
        await prefs.setInt('wird_last_page', lastPage);
        await prefs.setString('wird_plan_title', planTitle);
      }

      // Trigger widget update
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidWirdWidget,
        iOSName: iOSWirdWidget,
      );
    } catch (e) {
      debugPrint('Error syncing wird to home widget: $e');
    }
  }

  /// Synchronize upcoming prayer times to home screen widgets
  static Future<void> syncPrayerTimes({
    required String nextPrayerName,
    required String nextPrayerTime,
    required String cityName,
  }) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      await HomeWidget.saveWidgetData<String>('next_prayer_name', nextPrayerName);
      await HomeWidget.saveWidgetData<String>('next_prayer_time', nextPrayerTime);
      await HomeWidget.saveWidgetData<String>('prayer_city', cityName);

      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidPrayerWidget,
        iOSName: iOSPrayerWidget,
      );
    } catch (e) {
      debugPrint('Error syncing prayer times to home widget: $e');
    }
  }

  /// Synchronize Ramadan Imsak, Iftar, countdown, and Dua across home screen widgets
  static Future<void> syncRamadanData({
    required int dayNumber,
    required String dayTitle,
    required String eventTitle,
    required String countdownText,
    required String imsakTime,
    required String iftarTime,
    required String dailyDua,
  }) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      // Save for iOS WidgetKit
      await HomeWidget.saveWidgetData<int>('ramadan_day', dayNumber);
      await HomeWidget.saveWidgetData<String>('ramadan_day_title', dayTitle);
      await HomeWidget.saveWidgetData<String>('ramadan_event_title', eventTitle);
      await HomeWidget.saveWidgetData<String>('ramadan_countdown', countdownText);
      await HomeWidget.saveWidgetData<String>('ramadan_imsak_time', imsakTime);
      await HomeWidget.saveWidgetData<String>('ramadan_iftar_time', iftarTime);
      await HomeWidget.saveWidgetData<String>('ramadan_daily_dua', dailyDua);

      // Save for Android Native SharedPreferences
      if (Platform.isAndroid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('ramadan_day', dayNumber);
        await prefs.setString('ramadan_day_title', dayTitle);
        await prefs.setString('ramadan_event_title', eventTitle);
        await prefs.setString('ramadan_countdown', countdownText);
        await prefs.setString('ramadan_imsak_time', imsakTime);
        await prefs.setString('ramadan_iftar_time', iftarTime);
        await prefs.setString('ramadan_daily_dua', dailyDua);
      }

      // Trigger widget update
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidRamadanWidget,
        iOSName: iOSRamadanWidget,
      );
    } catch (e) {
      debugPrint('Error syncing ramadan data to home widget: $e');
    }
  }
}

