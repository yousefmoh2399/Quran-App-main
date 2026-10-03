import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/mushaf/mushaf_raster_cache.dart';
import '../controllers/mushaf_controller.dart';
import '../models/mushaf_theme_model.dart';
import '../utils/mushaf_utils.dart';
import '../widgets/ayah_action_bottom_sheet.dart';
import '../widgets/mushaf_dual_page_view.dart';
import '../widgets/mushaf_jump_dialog.dart';
import '../widgets/mushaf_paper_flip_view.dart';
import '../widgets/page_bookmark_bottom_sheet.dart';
import '../../../quran/presentation/views/quran_search_view.dart';

/// The authentic 604-page, 15-line Madinah Mushaf reader screen.
class MushafView extends StatefulWidget {
  final int? initialPage;
  const MushafView({super.key, this.initialPage});

  @override
  State<MushafView> createState() => _MushafViewState();
}

class _MushafViewState extends State<MushafView> {
  late final MushafController controller;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<MushafController>()) {
      Get.delete<MushafController>();
    }
    controller = Get.put(MushafController());
    if (widget.initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.goToPage(widget.initialPage!);
      });
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<MushafController>()) {
      Get.delete<MushafController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MushafThemeConfig.of(controller.currentTheme.value).pageBg,
      body: Stack(
        children: [
          // Main Reader Area - Isolated from top/bottom overlay rebuilds
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: OrientationBuilder(
                builder: (context, orientation) {
                  // Only clear cache on true orientation change
                  if (_lastOrientation != null && _lastOrientation != orientation) {
                    MushafRasterCache.instance.clear();
                  }
                  _lastOrientation = orientation;

                  final isDualMode = orientation == Orientation.landscape &&
                      MediaQuery.of(context).size.width >= 600;

                  return RepaintBoundary(
                    child: Obx(() {
                      final themeConfig = MushafThemeConfig.of(controller.currentTheme.value);
                      final currentPage = controller.currentPage.value;
                      // Touch userMarksVersion & selectedAyahColor so bookmark, color, and memorization changes rebuild immediately
                      final _ = controller.userMarksVersion.value;
                      final _ = controller.selectedAyahColor.value;

                      return Container(
                        color: themeConfig.pageBg,
                        child: isDualMode
                            ? MushafDualPageView(
                                currentPage: currentPage,
                                theme: themeConfig,
                                pagesCache: controller.pagesCache,
                                getPage: controller.getPage,
                                selectedSurah: controller.selectedSurah.value,
                                selectedAyah: controller.selectedAyah.value,
                                selectedAyahColor: controller.selectedAyahColor.value,
                                isMoving: controller.isPageTurning.value,
                                onPageChanged: controller.onPageChanged,
                                onAyahTapped: (s, a) => controller.selectAyah(s, a),
                                onTapPage: controller.toggleOverlay,
                              )
                            : _buildSinglePageView(context, controller, themeConfig),
                      );
                    }),
                  );
                },
              ),
            ),
          ),

          // Top Overlay Bar - Only listens to isOverlayVisible, currentPage, currentTheme
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: Obx(() {
              final themeConfig = MushafThemeConfig.of(controller.currentTheme.value);
              final isOverlayVisible = controller.isOverlayVisible.value;
              final currentPage = controller.currentPage.value;
              final isBookmarked = controller.isPageBookmarked(currentPage);
              final currentPageModel = controller.pagesCache[currentPage];
              final surahName = currentPageModel?.surahNameAr ?? '';

              return AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                offset: isOverlayVisible ? Offset.zero : const Offset(0.0, -1.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isOverlayVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !isOverlayVisible,
                    child: RepaintBoundary(
                      child: _buildTopBar(
                        context,
                        controller,
                        themeConfig,
                        surahName,
                        currentPage,
                        isBookmarked,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Bottom Overlay Bar - Only listens to isOverlayVisible, currentPage, currentTheme
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Obx(() {
              final themeConfig = MushafThemeConfig.of(controller.currentTheme.value);
              final isOverlayVisible = controller.isOverlayVisible.value;
              final currentPage = controller.currentPage.value;

              return AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                offset: isOverlayVisible ? Offset.zero : const Offset(0.0, 1.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isOverlayVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !isOverlayVisible,
                    child: RepaintBoundary(
                      child: _buildBottomBar(context, controller, themeConfig, currentPage),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Commute Mode Floating Top Bar
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: Obx(() {
              if (!controller.isCommuteMode.value) return const SizedBox.shrink();
              final themeConfig = MushafThemeConfig.of(controller.currentTheme.value);
              return RepaintBoundary(
                child: _buildCommuteTopBanner(context, controller, themeConfig),
              );
            }),
          ),

          // Commute Mode Ergonomic Bottom Bar (One-handed thumb navigation)
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: Obx(() {
              if (!controller.isCommuteMode.value) return const SizedBox.shrink();
              final themeConfig = MushafThemeConfig.of(controller.currentTheme.value);
              return RepaintBoundary(
                child: _buildCommuteBottomBar(context, controller, themeConfig),
              );
            }),
          ),

          // Ayah Action Sheet (if an ayah is selected)
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: Obx(() {
              if (controller.selectedAyah.value == null) return const SizedBox.shrink();
              final themeConfig = MushafThemeConfig.of(controller.currentTheme.value);
              final currentPage = controller.currentPage.value;
              final currentPageModel = controller.pagesCache[currentPage];
              final surahName = currentPageModel?.surahNameAr ?? '';

              return AyahActionBottomSheet(
                surahNumber: controller.selectedSurah.value!,
                ayahNumber: controller.selectedAyah.value!,
                pageNumber: currentPage,
                surahName: surahName,
                ayahEntity: controller.selectedAyahEntity.value,
                theme: themeConfig,
                onClose: controller.clearAyahSelection,
              );
            }),
          ),

        ],
      ),
    );
  }

  Widget _buildSinglePageView(
    BuildContext context,
    MushafController controller,
    MushafThemeConfig themeConfig,
  ) {
    final childView = MushafPaperFlipView(
      currentPage: controller.currentPage.value,
      theme: themeConfig,
      pagesCache: controller.pagesCache,
      getPage: controller.getPage,
      selectedSurah: controller.selectedSurah.value,
      selectedAyah: controller.selectedAyah.value,
      selectedAyahColor: controller.selectedAyahColor.value,
      onPageChanged: (newPage) {
        controller.onPageChanged(newPage);
      },
      onAyahTapped: (s, a) => controller.selectAyah(s, a),
      onTapPage: controller.toggleOverlay,
      getPageBookmarkColor: controller.getPageBookmarkColor,
      getPageMemorizeStatus: controller.getPageMemorizeStatus,
      getAyahBookmarkColors: controller.getAyahBookmarkColors,
      getAyahMemorizeStatuses: controller.getAyahMemorizeStatuses,
      controller: controller,
    );

    if (controller.isCommuteMode.value) {
      return Transform.scale(
        scale: controller.commuteZoomScale.value,
        child: childView,
      );
    }
    return childView;
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),

              // Quran Full-Text Search Button
              IconButton(
                icon: const Icon(Icons.search_rounded),
                color: colors.text,
                tooltip: 'البحث في القرآن',
                onPressed: () => Get.to(
                  () => const QuranSearchView(),
                  transition: Transition.cupertino,
                ),
              ),

              // Jump Dialog Button
              IconButton(
                icon: const Icon(Icons.explore_outlined),
                color: colors.text,
                tooltip: 'انتقال سريع',
                onPressed: () => _openJumpDialog(context, controller, currentPage),
              ),

              // Bookmark Page Button
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isBookmarked
                      ? (controller.getPageBookmarkColor(currentPage)?.color ?? colors.accent)
                      : colors.text,
                ),
                tooltip: 'علامة الصفحة وخيارات الحفظ',
                onPressed: () => PageBookmarkBottomSheet.show(context, currentPage, surahName),
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
                          controller.goToPage(val.round(), animate: false);
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

  Widget _buildCommuteTopBanner(
    BuildContext context,
    MushafController controller,
    MushafThemeConfig themeConfig,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 8,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4D3E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bus_rounded, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('وضع المواصلات', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          // Zoom toggle
          IconButton(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                Text(' ${controller.commuteZoomScale.value.toStringAsFixed(2)}x', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
            tooltip: 'تكبير الخط',
            onPressed: controller.toggleCommuteZoom,
          ),
          // High contrast toggle
          IconButton(
            icon: Icon(
              controller.commuteHighContrast.value ? Icons.contrast_rounded : Icons.brightness_6_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'تباين عالي',
            onPressed: controller.toggleCommuteContrast,
          ),
          // Screen On Badge
          const Icon(Icons.lightbulb_rounded, color: Colors.amberAccent, size: 18),
          const SizedBox(width: 8),
          // Exit commute mode
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            tooltip: 'إغلاق وضع المواصلات',
            onPressed: () => controller.isCommuteMode.value = false,
          ),
        ],
      ),
    );
  }

  Widget _buildCommuteBottomBar(
    BuildContext context,
    MushafController controller,
    MushafThemeConfig themeConfig,
  ) {
    final readCount = (controller.currentPage.value - controller.commuteStartPage.value).abs() + 1;
    final target = controller.commuteTargetPages.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Previous Page Button (Right in RTL, thumb-friendly)
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
            onPressed: controller.prevCommutePage,
            tooltip: 'الصفحة السابقة',
          ),
          const SizedBox(width: 12),
          // Center Info & Complete Button
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المقروء: $readCount من $target صفحات',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    minimumSize: const Size(120, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.completeCommuteWird,
                  child: const Text('أتممت الورد ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Next Page Button (Left in RTL, thumb-friendly)
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1B4D3E),
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: controller.nextCommutePage,
            tooltip: 'الصفحة التالية',
          ),
        ],
      ),
    );
  }
}
