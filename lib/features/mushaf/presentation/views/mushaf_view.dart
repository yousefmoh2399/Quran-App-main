import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../controllers/mushaf_controller.dart';
import '../models/mushaf_theme_model.dart';
import '../utils/mushaf_utils.dart';
import '../widgets/ayah_action_bottom_sheet.dart';
import '../widgets/mushaf_dual_page_view.dart';
import '../widgets/mushaf_jump_dialog.dart';
import '../widgets/mushaf_page_widget.dart';

/// The authentic 604-page, 15-line Madinah Mushaf reader screen.
class MushafView extends StatelessWidget {
  const MushafView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MushafController());

    return Obx(() {
      final themeConfig = MushafThemeConfig.of(controller.currentTheme.value);
      final isOverlayVisible = controller.isOverlayVisible.value;
      final currentPage = controller.currentPage.value;
      final isBookmarked = controller.isPageBookmarked(currentPage);
      final isDualMode = MediaQuery.of(context).orientation == Orientation.landscape ||
          MediaQuery.of(context).size.width >= 720;

      final currentPageModel = controller.pagesCache[currentPage];
      final surahName = currentPageModel?.surahNameAr ?? '';

      return Scaffold(
        backgroundColor: themeConfig.pageBg,
        body: Stack(
          children: [
            // Main Reader Area
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: isDualMode
                    ? MushafDualPageView(
                        currentPage: currentPage,
                        theme: themeConfig,
                        pagesCache: controller.pagesCache,
                        getPage: controller.getPage,
                        selectedSurah: controller.selectedSurah.value,
                        selectedAyah: controller.selectedAyah.value,
                        onPageChanged: controller.onPageChanged,
                        onAyahTapped: (s, a) => controller.selectAyah(s, a),
                        onTapPage: controller.toggleOverlay,
                      )
                    : _buildSinglePageView(controller, themeConfig),
              ),
            ),

            // Top Overlay Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: isOverlayVisible ? 0.0 : -100.0,
              left: 0.0,
              right: 0.0,
              child: _buildTopBar(
                context,
                controller,
                themeConfig,
                surahName,
                currentPage,
                isBookmarked,
              ),
            ),

            // Bottom Overlay Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              bottom: isOverlayVisible ? 0.0 : -120.0,
              left: 0.0,
              right: 0.0,
              child: _buildBottomBar(context, controller, themeConfig, currentPage),
            ),

            // Ayah Action Sheet (if an ayah is selected)
            if (controller.selectedAyah.value != null)
              Positioned(
                left: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: AyahActionBottomSheet(
                  surahNumber: controller.selectedSurah.value!,
                  ayahNumber: controller.selectedAyah.value!,
                  surahName: surahName,
                  ayahEntity: controller.selectedAyahEntity.value,
                  theme: themeConfig,
                  onClose: controller.clearAyahSelection,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSinglePageView(
    MushafController controller,
    MushafThemeConfig themeConfig,
  ) {
    return PageView.builder(
      controller: controller.pageController,
      reverse: true, // Authentic RTL reading order
      physics: const BouncingScrollPhysics(),
      itemCount: 604,
      onPageChanged: (pageIndex) {
        controller.onPageChanged(pageIndex + 1);
      },
      itemBuilder: (context, pageIndex) {
        final pageNum = pageIndex + 1;
        final cached = controller.pagesCache[pageNum];

        if (cached != null) {
          return MushafPageWidget(
            page: cached,
            theme: themeConfig,
            selectedSurah: controller.selectedSurah.value,
            selectedAyah: controller.selectedAyah.value,
            onAyahTapped: (s, a) => controller.selectAyah(s, a),
            onTapPage: controller.toggleOverlay,
          );
        }

        return FutureBuilder<MushafPage?>(
          future: controller.getPage(pageNum),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
              return MushafPageWidget(
                page: snapshot.data!,
                theme: themeConfig,
                selectedSurah: controller.selectedSurah.value,
                selectedAyah: controller.selectedAyah.value,
                onAyahTapped: (s, a) => controller.selectAyah(s, a),
                onTapPage: controller.toggleOverlay,
              );
            }

            return Container(
              color: themeConfig.pageBg,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: themeConfig.frameBorderInner,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    MushafController controller,
    MushafThemeConfig themeConfig,
    String surahName,
    int currentPage,
    bool isBookmarked,
  ) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: colors.text,
                onPressed: () => Navigator.of(context).pop(),
              ),

              // Title
              Expanded(
                child: Text(
                  surahName.isNotEmpty
                      ? 'سورة $surahName  •  صـ ${toArabicDigits(currentPage)}'
                      : 'المصحف الشريف  •  صـ ${toArabicDigits(currentPage)}',
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),

              // Jump Dialog Button
              IconButton(
                icon: const Icon(Icons.search_rounded),
                color: colors.text,
                tooltip: 'انتقال سريع',
                onPressed: () => _openJumpDialog(context, controller, currentPage),
              ),

              // Bookmark Page Button
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked ? colors.accent : colors.text,
                ),
                tooltip: 'حفظ الصفحة',
                onPressed: () => controller.togglePageBookmark(currentPage),
              ),

              // Theme Switcher Menu
              _buildThemeMenu(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    MushafController controller,
    MushafThemeConfig themeConfig,
    int currentPage,
  ) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slider & Buttons Row
              Row(
                children: [
                  // Next Page (in RTL, next goes left)
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: colors.primary,
                    onPressed: currentPage < 604
                        ? () => controller.goToPage(currentPage + 1)
                        : null,
                  ),

                  // Page Slider
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                      ),
                      child: Slider(
                        value: currentPage.toDouble().clamp(1.0, 604.0),
                        min: 1.0,
                        max: 604.0,
                        activeColor: colors.primary,
                        inactiveColor: colors.divider,
                        onChanged: (val) {
                          controller.goToPage(val.round());
                        },
                      ),
                    ),
                  ),

                  // Previous Page (in RTL, prev goes right)
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 28),
                    color: colors.primary,
                    onPressed: currentPage > 1
                        ? () => controller.goToPage(currentPage - 1)
                        : null,
                  ),
                ],
              ),

              // Position Indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'صفحة ${toArabicDigits(currentPage)} من ٦٠٤',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeMenu(BuildContext context, MushafController controller) {
    final colors = context.appColors;

    return PopupMenuButton<MushafThemeMode>(
      icon: Icon(Icons.palette_outlined, color: colors.text),
      tooltip: 'مظهر المصحف',
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      onSelected: (mode) => controller.setThemeMode(mode),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: MushafThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: Color(0xFFB8892B), size: 20),
              AppSpacing.horizontalSm,
              Text('وضع فاتح (ورق مصحف)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: MushafThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode_rounded, color: Color(0xFF3FB597), size: 20),
              AppSpacing.horizontalSm,
              Text('وضع داكن (مظلم)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: MushafThemeMode.readingNight,
          child: Row(
            children: [
              Icon(Icons.nightlight_round, color: Color(0xFFD9B25A), size: 20),
              AppSpacing.horizontalSm,
              Text('قراءة ليلية (دافئ)'),
            ],
          ),
        ),
      ],
    );
  }

  void _openJumpDialog(
    BuildContext context,
    MushafController controller,
    int currentPage,
  ) {
    showDialog(
      context: context,
      builder: (context) => MushafJumpDialog(
        initialPage: currentPage,
        onPageSelected: (target) => controller.goToPage(target),
      ),
    );
  }
}
