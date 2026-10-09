import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

class _ShortcutItem {
  final String title;
  final IconData icon;
  final String route;

  const _ShortcutItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class HomeQuickShortcuts extends StatelessWidget {
  const HomeQuickShortcuts({super.key});

  static final List<_ShortcutItem> _shortcuts = [
    _ShortcutItem(
      title: 'رمضان المبارك',
      icon: Icons.nightlight_round,
      route: AppRoutes.ramadanHub,
    ),
    _ShortcutItem(
      title: 'رفيق المعتمر',
      icon: Icons.mosque_rounded,
      route: AppRoutes.umrahHub,
    ),
    _ShortcutItem(
      title: 'ختمة العائلة',
      icon: Icons.groups_rounded,
      route: AppRoutes.khatmaCircles,
    ),
    _ShortcutItem(
      title: 'استوديو البطاقات',
      icon: Icons.palette_rounded,
      route: AppRoutes.cardStudio,
    ),
    _ShortcutItem(
      title: 'اختبار الحفظ',
      icon: Icons.psychology_alt_rounded,
      route: AppRoutes.hifzTester,
    ),
    _ShortcutItem(
      title: 'القبلة',
      icon: Icons.explore_rounded,
      route: AppRoutes.qiblah,
    ),
    _ShortcutItem(
      title: 'السبحة',
      icon: Icons.fingerprint_rounded,
      route: AppRoutes.pngTree,
    ),
    _ShortcutItem(
      title: 'أسماء الله',
      icon: Icons.stars_rounded,
      route: AppRoutes.nameofAllah,
    ),
    _ShortcutItem(
      title: 'الحديث',
      icon: Icons.auto_stories_rounded,
      route: AppRoutes.sectionHadith,
    ),
    _ShortcutItem(
      title: 'التقويم',
      icon: Icons.calendar_month_rounded,
      route: AppRoutes.islamicCalendar,
    ),
    _ShortcutItem(
      title: 'سجل الصلوات',
      icon: Icons.fact_check_rounded,
      route: AppRoutes.prayerTracker,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: _shortcuts.map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Material(
                  color: colors.surface,
                  borderRadius: AppRadius.borderLg,
                  elevation: 1,
                  shadowColor: Colors.black.withOpacity(0.04),
                  child: InkWell(
                    borderRadius: AppRadius.borderLg,
                    onTap: () => Get.toNamed(item.route),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 76),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: colors.primary,
                              size: 20,
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
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
