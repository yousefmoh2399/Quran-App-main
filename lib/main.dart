import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran_app_android/core/notifications/ios_prayer_scheduler.dart';
import 'package:quran_app_android/core/notifications/ios_reminder_scheduler.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_app_android/core/native/permissions_helper.dart';
import 'package:quran_app_android/core/permissions/permission_service.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/service/settings/notifications_services.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/core/service/navigation/app_navigation_service.dart';
import 'package:quran_app_android/core/service/theme_controller.dart';
import 'package:quran_app_android/core/util/binding.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global error handling to catch uncaught Flutter errors and zone errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint(
          'FlutterError caught: ${details.exception}\n${details.stack}',
        );
      };

      // Critical essentials needed before first frame (SharedPreferences & orientation)
      await Future.wait([
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]),
        Get.putAsync(() => SettingsServices().init()),
      ]);
      Get.put(ThemeController());

      // Mount UI immediately
      runApp(const MyApp());

      // Run remaining background services concurrently during splash screen
      unawaited(_initBackgroundServices());
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
    },
  );
}

Future<void> _initBackgroundServices() async {
  try {
    await Future.wait([
      initializeDateFormatting('ar', null),
      NotifyHelper().initializeNotification(),
      PermissionService.instance.init(),
      AppNavigationService.instance.init(),
    ]);
    debugPrint('🚀 [Startup] Background services initialized successfully');
  } catch (e, st) {
    debugPrint('⚠️ [Startup] Error in background services initialization: $e\n$st');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SettingsServices settingsServices = Get.find<SettingsServices>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isIOS) {
      Future.microtask(() async {
        await IosPrayerNotificationScheduler.instance.recalculateAndSchedule();
        await IosReminderNotificationScheduler.instance.rescheduleAll();
      });
    }
    _listenToInitialNotification();
    Future.microtask(() async {
      final notify = NotifyHelper();
      await notify.initializeNotification();
      final granted = await notify.ensureSchedulingPermissions(
        requestIfNeeded: false,
      );
      if (!granted) {
        debugPrint(
          'ℹ️ Scheduling permissions not granted yet; will be requested contextually.',
        );
      }
      try {
        //  notify.scheduleAzkar(timeOfDay: null);
        debugPrint('✅ Azkar scheduled successfully.');
      } catch (e, st) {
        debugPrint('⚠️ scheduleAzkar skipped: $e\n$st');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isIOS) {
      debugPrint('📱 [iOS Lifecycle] App resumed, renewing prayer & reminder schedules...');
      IosPrayerNotificationScheduler.instance.recalculateAndSchedule();
      IosReminderNotificationScheduler.instance.rescheduleAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _listenToInitialNotification() async {
    final NotificationAppLaunchDetails? details =
        await NotifyHelper().flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp ?? false) {
      final String? payload = details?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotifyHelper().handleNotificationPayload(payload);
        });
      }
    }
  }

  // Future<void> setupWorkManager() async {
  //   bool? isWorkManagerRunning = settingsServices.sharedPref!.getBool(
  //     'isWorkManager',
  //   );
  //   if (settingsServices.sharedPref!.getBool('stop_noti') == true) {
  //     if (isWorkManagerRunning == null || !isWorkManagerRunning) {
  //       await settingsServices.sharedPref!.setBool('isWorkManager', true);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: PermissionsController.scaffoldMessengerKey,
        initialRoute: AppRoutes.splash,
        initialBinding: Binding(),
        getPages: AppRoutes.routes,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode,
      ),
    );
  }
}
