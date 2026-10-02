import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widgets/smart_zikr_card.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/continue_reading_wird_card.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_header.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_nav_bar.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_quick_shortcuts.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/next_prayer_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Ensure controllers are registered safely
    if (!Get.isRegistered<HomeViewModel>()) {
      Get.put(HomeViewModel());
    }
    if (!Get.isRegistered<AdhanViewModel>()) {
      Get.put(AdhanViewModel());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useSafeArea: true,
      constrainContentWidth: true,
      bottomNavigationBar: const HomeNavBar(currentIndex: 0),
      body: RefreshIndicator(
        color: context.appColors.primary,
        notificationPredicate: (notification) => notification.depth == 0,
        onRefresh: () async {
          final adhanVM = Get.find<AdhanViewModel>();
          await adhanVM.initializeAdhan();
          final homeVM = Get.find<HomeViewModel>();
          await homeVM.loadUserQuranData();
        },
        child: SingleChildScrollView(
          key: const PageStorageKey<String>('home_scroll_view'),
          controller: _scrollController,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              AppSpacing.verticalMd,
              HomeHeader(),
              AppSpacing.verticalLg,
              NextPrayerCard(),
              AppSpacing.verticalLg,
              ContinueReadingWirdCard(),
              AppSpacing.verticalLg,
              HomeQuickShortcuts(),
              AppSpacing.verticalLg,
              SmartZikrCard(),
              AppSpacing.verticalXxl,
            ],
          ),
        ),
      ),
    );
  }
}
