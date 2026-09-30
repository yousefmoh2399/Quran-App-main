import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../controllers/bookmarks_controller.dart';
import '../widgets/bookmarks_tab.dart';
import '../widgets/memorized_tab.dart';
import '../widgets/reading_log_tab.dart';

class BookmarksView extends StatelessWidget {
  const BookmarksView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BookmarksController());
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'علاماتي',
          style: TextStyle(
            fontFamily: AppTypography.decorativeFont,
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            height: 40.0,
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.divider),
            ),
            child: TabBar(
              controller: controller.tabController,
              indicator: BoxDecoration(
                color: colors.primary,
                borderRadius: AppRadius.borderSm,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: colors.textMuted,
              labelStyle: const TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 13.0,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.normal,
                fontSize: 13.0,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_rounded, size: 16.0),
                      SizedBox(width: 6.0),
                      Text('علامات'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 16.0),
                      SizedBox(width: 6.0),
                      Text('محفوظاتي'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu_rounded, size: 16.0),
                      SizedBox(width: 6.0),
                      Text('سجل القراءة'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: colors.primary,
              strokeWidth: 2.5,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadAll,
          color: colors.primary,
          child: TabBarView(
            controller: controller.tabController,
            children: [
              BookmarksTab(controller: controller),
              MemorizedTab(controller: controller),
              ReadingLogTab(controller: controller),
            ],
          ),
        );
      }),
    );
  }
}
