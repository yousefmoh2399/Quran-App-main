import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../controllers/traveler_companion_controller.dart';
import '../widgets/travel_duas_tab.dart';
import '../widgets/travel_fiqh_guide_tab.dart';
import '../widgets/wiping_timer_tab.dart';

class TravelerCompanionView extends StatefulWidget {
  const TravelerCompanionView({super.key});

  @override
  State<TravelerCompanionView> createState() => _TravelerCompanionViewState();
}

class _TravelerCompanionViewState extends State<TravelerCompanionView>
    with SingleTickerProviderStateMixin {
  late final TravelerCompanionController controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TravelerCompanionController());
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        AppHaptics.selection();
        controller.selectedTabIndex.value = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          'مساعد المسافر ورخص السفر',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.bold,
            fontSize: 17.0,
            color: colors.text,
          ),
        ),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            height: 42.0,
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(9.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.28),
                    blurRadius: 6.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: colors.textMuted,
              labelStyle: const TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 15.0),
                      SizedBox(width: 4),
                      Text('مؤقت المسح'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 15.0),
                      SizedBox(width: 4),
                      Text('دليل الرخص'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline_rounded, size: 15.0),
                      SizedBox(width: 4),
                      Text('أدعية السفر'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          WipingTimerTab(controller: controller),
          TravelFiqhGuideTab(controller: controller),
          TravelDuasTab(controller: controller),
        ],
      ),
    );
  }
}
