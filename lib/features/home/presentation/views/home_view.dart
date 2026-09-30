import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/daily_wird_card.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/daily_zekr_card.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_header.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_nav_bar.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_sections_grid.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/last_read_card.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/latest_bookmark_card.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/next_prayer_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controllers are registered safely
    if (!Get.isRegistered<HomeViewModel>()) {
      Get.put(HomeViewModel());
    }
    if (!Get.isRegistered<AdhanViewModel>()) {
      Get.put(AdhanViewModel());
    }

    return AppScaffold(
      useSafeArea: true,
      constrainContentWidth: true,
      bottomNavigationBar: const HomeNavBar(currentIndex: 0),
      body: RefreshIndicator(
        color: context.appColors.primary,
        onRefresh: () async {
          final adhanVM = Get.find<AdhanViewModel>();
          await adhanVM.initializeAdhan();
          final homeVM = Get.find<HomeViewModel>();
          await homeVM.loadUserQuranData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              AppSpacing.verticalMd,
              HomeHeader(),
              AppSpacing.verticalLg,
              NextPrayerCard(),
              AppSpacing.verticalLg,
              DailyWirdCard(),
              AppSpacing.verticalLg,
              LastReadCard(),
              AppSpacing.verticalLg,
              LatestBookmarkCard(),
              AppSpacing.verticalLg,
              HomeSectionsGrid(),
              AppSpacing.verticalLg,
              DailyZekrCard(),
              AppSpacing.verticalXxl,
            ],
          ),
        ),
      ),
    );
  }
}
