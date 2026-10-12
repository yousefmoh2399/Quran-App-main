import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

class _ShortcutItem {
  final String title;
  final String imageAsset;
  final IconData fallbackIcon;
  final String route;

  const _ShortcutItem({
    required this.title,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.route,
  });
}

class HomeQuickShortcuts extends StatelessWidget {
  const HomeQuickShortcuts({super.key});

  static final List<_ShortcutItem> _shortcuts = [
    _ShortcutItem(
      title: 'رمضان المبارك',
      imageAsset: 'assets/images/icon_3d_lantern.png',
      fallbackIcon: Icons.nightlight_round,
      route: AppRoutes.ramadanHub,
    ),
    _ShortcutItem(
      title: 'رفيق المعتمر',
      imageAsset: 'assets/images/icon_3d_qiblah.png',
      fallbackIcon: Icons.mosque_rounded,
      route: AppRoutes.umrahHub,
    ),
    _ShortcutItem(
      title: 'رخص السفر',
      imageAsset: 'assets/images/icon_3d_travel.png',
      fallbackIcon: Icons.flight_takeoff_rounded,
      route: AppRoutes.travelerCompanion,
    ),
    _ShortcutItem(
      title: 'ختمة العائلة',
      imageAsset: 'assets/images/icon_3d_khatma_circles.png',
      fallbackIcon: Icons.groups_rounded,
      route: AppRoutes.khatmaCircles,
    ),
    _ShortcutItem(
      title: 'استوديو البطاقات',
      imageAsset: 'assets/images/icon_3d_card_studio.png',
      fallbackIcon: Icons.palette_rounded,
      route: AppRoutes.cardStudio,
    ),
    _ShortcutItem(
      title: 'اختبار الحفظ',
      imageAsset: 'assets/images/icon_3d_hifz_tester.png',
      fallbackIcon: Icons.psychology_alt_rounded,
      route: AppRoutes.hifzTester,
    ),
    _ShortcutItem(
      title: 'إحصائيات القراءة',
      imageAsset: 'assets/images/icon_3d_quran.png',
      fallbackIcon: Icons.insights_rounded,
      route: AppRoutes.readingAnalytics,
    ),
    _ShortcutItem(
      title: 'الرقية الشرعية',
      imageAsset: 'assets/images/icon_3d_praying_hands.png',
      fallbackIcon: Icons.healing_rounded,
      route: AppRoutes.ruqyah,
    ),
    _ShortcutItem(
      title: 'السيرة النبوية',
      imageAsset: 'assets/images/icon_3d_hadith.png',
      fallbackIcon: Icons.timeline_rounded,
      route: AppRoutes.seerah,
    ),
    _ShortcutItem(
      title: 'غِراس الجنة',
      imageAsset: 'assets/images/icon_3d_tasbeeh.png',
      fallbackIcon: Icons.park_rounded,
      route: AppRoutes.spiritualMilestones,
    ),
    _ShortcutItem(
      title: 'الطب النبوي',
      imageAsset: 'assets/images/icon_3d_praying_hands.png',
      fallbackIcon: Icons.eco_rounded,
      route: AppRoutes.propheticMedicine,
    ),
    _ShortcutItem(
      title: 'الصلوات الخاصة',
      imageAsset: 'assets/images/icon_3d_prayer_clock.png',
      fallbackIcon: Icons.accessibility_new_rounded,
      route: AppRoutes.specialPrayers,
    ),
    _ShortcutItem(
      title: 'القبلة',
      imageAsset: 'assets/images/icon_3d_qiblah.png',
      fallbackIcon: Icons.explore_rounded,
      route: AppRoutes.qiblah,
    ),
    _ShortcutItem(
      title: 'السبحة',
      imageAsset: 'assets/images/icon_3d_tasbeeh.png',
      fallbackIcon: Icons.fingerprint_rounded,
      route: AppRoutes.pngTree,
    ),
    _ShortcutItem(
      title: 'أسماء الله',
      imageAsset: 'assets/images/icon_3d_names99.png',
      fallbackIcon: Icons.stars_rounded,
      route: AppRoutes.nameofAllah,
    ),
    _ShortcutItem(
      title: 'الحديث',
      imageAsset: 'assets/images/icon_3d_hadith.png',
      fallbackIcon: Icons.auto_stories_rounded,
      route: AppRoutes.sectionHadith,
    ),
    _ShortcutItem(
      title: 'التقويم',
      imageAsset: 'assets/images/icon_3d_calendar.png',
      fallbackIcon: Icons.calendar_month_rounded,
      route: AppRoutes.islamicCalendar,
    ),
    _ShortcutItem(
      title: 'سجل الصلوات',
      imageAsset: 'assets/images/icon_3d_prayer_clock.png',
      fallbackIcon: Icons.fact_check_rounded,
      route: AppRoutes.prayerTracker,
    ),
  ];

  Widget _buildCard(BuildContext context, _ShortcutItem item, AppColorsExtension colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? colors.surface : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.toNamed(item.route),
        child: Container(
          width: 86,
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? colors.divider : Colors.black.withOpacity(0.04),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Image.asset(
                  item.imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    item.fallbackIcon,
                    color: colors.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final int columnCount = (_shortcuts.length / 2).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'اختصارات سريعة',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(columnCount, (colIndex) {
              final topItem = _shortcuts[colIndex * 2];
              final bottomIndex = colIndex * 2 + 1;
              final bottomItem = bottomIndex < _shortcuts.length
                  ? _shortcuts[bottomIndex]
                  : null;

              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCard(context, topItem, colors),
                    if (bottomItem != null) ...[
                      const SizedBox(height: 10),
                      _buildCard(context, bottomItem, colors),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
