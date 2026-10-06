import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/azkar/presentation/view_model/azkar_view_model.dart';
import 'package:quran_app_android/features/reminders/data/commute_wird_repository.dart';

/// Central navigation coordinator for handling app entry via notifications,
/// widget clicks, deep links, and alarms from both cold start and running states.
class AppNavigationService {
  AppNavigationService._();
  static final AppNavigationService instance = AppNavigationService._();

  static const MethodChannel _navChannel =
      MethodChannel('com.taqarrab.quran/app_navigation');

  bool _initialized = false;
  Map<String, dynamic>? _pendingColdStartNav;

  /// Initializes listening to the native navigation channel.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _navChannel.setMethodCallHandler(_handleNativeMethodCall);

    try {
      final initialData =
          await _navChannel.invokeMethod<Map<dynamic, dynamic>>('getInitialNavigation');
      if (initialData != null && initialData.isNotEmpty) {
        _pendingColdStartNav = Map<String, dynamic>.from(initialData);
        debugPrint('🔔 [AppNavigationService] Found cold start navigation: $_pendingColdStartNav');
      }
    } catch (e) {
      debugPrint('⚠️ [AppNavigationService] Failed to check initial navigation: $e');
    }
  }

  /// Processes cold start navigation once the root UI/splash is mounted.
  Future<void> processColdStartNavigationIfNeeded() async {
    if (_pendingColdStartNav == null) return;
    final navData = _pendingColdStartNav!;
    _pendingColdStartNav = null;

    // Small delay to allow GetMaterialApp / home route to be completely ready
    await Future.delayed(const Duration(milliseconds: 350));
    await handleNavigation(navData);
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onNavigationIntent') {
      try {
        final args = call.arguments;
        if (args is Map) {
          final navData = Map<String, dynamic>.from(args);
          debugPrint('🔔 [AppNavigationService] Received runtime navigation: $navData');
          await handleNavigation(navData);
        }
      } catch (e, st) {
        debugPrint('⚠️ [AppNavigationService] Error handling runtime navigation: $e\n$st');
      }
    }
  }

  /// Directly routes the user to the destination based on intent extras / payload.
  Future<void> handleNavigation(Map<String, dynamic> navData) async {
    final targetScreen = navData['target_screen'] as String?;
    final route = navData['route'] as String?;
    final openPage = navData['open_page'] as int?;
    final isCommute = navData['commute_mode'] == true;
    final category = navData['category'] as String?;

    debugPrint('🔔 [AppNavigationService] Routing: targetScreen=$targetScreen, route=$route, page=$openPage');

    if (isCommute || targetScreen == 'commute_wird') {
      await _navigateToCommuteWird(openPage);
      return;
    }

    switch (targetScreen) {
      case 'wird':
        await _navigateToDailyWird(openPage);
        return;

      case 'sadaqah':
        await Get.toNamed(AppRoutes.sadaqahLogs);
        return;

      case 'azkar':
        await _navigateToAzkar(category);
        return;

      case 'prayer_times':
      case 'adhan':
        await Get.toNamed(AppRoutes.adhan);
        return;

      case 'mushaf':
        final page = openPage ?? _getLastReadPage();
        await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': page});
        return;

      case 'qiblah':
        await Get.toNamed(AppRoutes.qiblah);
        return;

      case 'commute_wird_settings':
        await Get.toNamed(AppRoutes.commuteWirdSettings);
        return;

      case 'permissions':
        await Get.toNamed(AppRoutes.permissionsStatus);
        return;

      case 'sounds':
        await Get.toNamed(AppRoutes.notificationSoundsSettings);
        return;
    }

    // Fallback to explicit route if provided
    if (route != null && route.isNotEmpty) {
      if (route == AppRoutes.mushaf && openPage != null) {
        await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': openPage});
      } else {
        await Get.toNamed(route);
      }
      return;
    }

    // Default fallback if page is specified
    if (openPage != null) {
      await Get.toNamed(AppRoutes.mushaf, arguments: {'pageNumber': openPage});
    }
  }

  /// Calculates the best resume page for the Daily Wird and navigates to Mushaf.
  Future<void> _navigateToDailyWird(int? specificPage) async {
    int targetPage = 1;

    try {
      final userRepo = UserRepository();
      final plan = await userRepo.getWirdPlan();
      final lastRead = _getLastReadPage();

      if (specificPage != null && specificPage >= 1 && specificPage <= 604) {
        targetPage = specificPage;
      } else if (plan != null) {
        // If last read page is within today's range, resume from there
        if (lastRead >= plan.startPage && lastRead <= plan.endPage) {
          targetPage = lastRead;
        } else {
          targetPage = plan.startPage;
        }
      } else {
        targetPage = lastRead;
      }
    } catch (e) {
      debugPrint('⚠️ [AppNavigationService] Error calculating wird page: $e');
      targetPage = _getLastReadPage();
    }

    await Get.toNamed(
      AppRoutes.mushaf,
      arguments: {
        'pageNumber': targetPage.clamp(1, 604),
      },
    );
  }

  /// Resumes the commute wird session in Mushaf with commute mode enabled.
  Future<void> _navigateToCommuteWird(int? specificPage) async {
    int page = specificPage ?? 1;

    try {
      if (specificPage == null) {
        final commuteRepo = CommuteWirdRepository();
        final state = await commuteRepo.getState();
        page = state.currentPage;
      }
    } catch (_) {
      page = _getLastReadPage();
    }

    await Get.toNamed(
      AppRoutes.mushaf,
      arguments: {
        'commute_mode': true,
        'page': page.clamp(1, 604),
      },
    );
  }

  /// Navigates to Azkar, optionally opening the specific category if matched.
  Future<void> _navigateToAzkar(String? categoryName) async {
    if (categoryName == null || categoryName.trim().isEmpty) {
      await Get.toNamed(AppRoutes.azkar);
      return;
    }

    try {
      if (Get.isRegistered<AzkarViewModel>()) {
        final vm = Get.find<AzkarViewModel>();
        final idx = vm.azkarModel.indexWhere(
          (m) => m.category?.trim() == categoryName.trim(),
        );
        if (idx != -1 && Get.isRegistered<SettingsServices>()) {
          Get.find<SettingsServices>().sharedPref?.setInt('indexAzkar', idx);
          await Get.toNamed(AppRoutes.azkarDetails);
          return;
        }
      }
    } catch (_) {
      // Fallback below
    }

    await Get.toNamed(AppRoutes.azkar);
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
