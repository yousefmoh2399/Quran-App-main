import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetSyncService {
  static const String appGroupId = 'group.com.homeScreenApp';
  static const String androidWirdWidget = 'WirdKhatmaWidgetProvider';
  static const String iOSWirdWidget = 'WirdKhatmaWidget';
  static const String androidPrayerWidget = 'PrayerTimesWidgetProvider';
  static const String iOSPrayerWidget = 'PrayerTimesWidget';

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
        name: androidWirdWidget,
        androidName: androidWirdWidget,
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
        name: androidPrayerWidget,
        androidName: androidPrayerWidget,
        iOSName: iOSPrayerWidget,
      );
    } catch (e) {
      debugPrint('Error syncing prayer times to home widget: $e');
    }
  }
}
