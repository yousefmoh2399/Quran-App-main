import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

class _SectionItem {
  final String title;
  final String subtitle;
  final String imageAsset;
  final IconData icon;
  final String route;

  const _SectionItem({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.icon,
    required this.route,
  });
}

class HomeSectionsGrid extends StatelessWidget {
  const HomeSectionsGrid({super.key});

  static final List<_SectionItem> _sections = [
    _SectionItem(
      title: 'القرآن الكريم',
      subtitle: 'سور وأجزاء',
      imageAsset: 'assets/images/icon_3d_quran.png',
      icon: Icons.menu_book_rounded,
      route: AppRoutes.quranScreen,
    ),
    _SectionItem(
      title: 'حصن المسلم',
      subtitle: 'أذكار وأدعية',
      imageAsset: 'assets/images/icon_3d_praying_hands.png',
      icon: Icons.spa_rounded,
      route: AppRoutes.azkar,
    ),
    _SectionItem(
      title: 'مواقيت الصلاة',
      subtitle: 'الأذان والإقامة',
      imageAsset: 'assets/images/icon_3d_prayer_clock.png',
      icon: Icons.access_time_rounded,
      route: AppRoutes.adhan,
    ),
    _SectionItem(
      title: 'اتجاه القبلة',
      subtitle: 'بوصلة الكعبة',
      imageAsset: 'assets/images/icon_3d_qiblah.png',
      icon: Icons.explore_rounded,
      route: AppRoutes.qiblah,
    ),
    _SectionItem(
      title: 'الحديث النبوي',
      subtitle: 'موطأ مالك',
      imageAsset: 'assets/images/icon_3d_hadith.png',
      icon: Icons.auto_stories_rounded,
      route: AppRoutes.sectionHadith,
    ),
    _SectionItem(
      title: 'أسماء الله الحسنى',
      subtitle: 'معاني وشروح',
      imageAsset: 'assets/images/icon_3d_names99.png',
      icon: Icons.stars_rounded,
      route: AppRoutes.nameofAllah,
    ),
    _SectionItem(
      title: 'التفسير الميسر',
      subtitle: 'تفسير الآيات',
      imageAsset: 'assets/images/icon_3d_quran.png',
      icon: Icons.library_books_rounded,
      route: AppRoutes.tafsser,
    ),
    _SectionItem(
      title: 'السبحة الإلكترونية',
      subtitle: 'عداد التسبيح',
      imageAsset: 'assets/images/icon_3d_tasbeeh.png',
      icon: Icons.fingerprint_rounded,
      route: AppRoutes.pngTree,
    ),
    _SectionItem(
      title: 'علاماتي',
      subtitle: 'علامات ومحفوظات',
      imageAsset: 'assets/images/icon_3d_khatma_circles.png',
      icon: Icons.bookmark_added_rounded,
      route: AppRoutes.bookmarks,
    ),
    _SectionItem(
      title: 'سجل الصلوات',
      subtitle: 'تسجيل وقضاء',
      imageAsset: 'assets/images/icon_3d_prayer_clock.png',
      icon: Icons.fact_check_rounded,
      route: AppRoutes.prayerTracker,
    ),
    _SectionItem(
      title: 'التقويم الهجري',
      subtitle: 'مناسبات وصيام',
      imageAsset: 'assets/images/icon_3d_calendar.png',
      icon: Icons.calendar_month_rounded,
      route: AppRoutes.islamicCalendar,
    ),
    _SectionItem(
      title: 'إنجازاتي',
      subtitle: 'شارات وأوسمة',
      imageAsset: 'assets/images/icon_3d_card_studio.png',
      icon: Icons.military_tech_rounded,
      route: AppRoutes.achievements,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final int crossAxisCount = width > 840 ? 4 : (width > 560 ? 3 : 2);
          final double itemAspectRatio = width > 560 ? 1.4 : 1.35;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sections.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: itemAspectRatio,
            ),
            itemBuilder: (context, index) {
              final item = _sections[index];
              return AppCard(
                variant: AppCardVariant.elevated,
                padding: AppSpacing.paddingMd,
                onTap: () => Get.toNamed(item.route),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.08),
                            borderRadius: AppRadius.borderMd,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(
                              item.imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                item.icon,
                                color: colors.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: colors.textMuted.withOpacity(0.6),
                        ),
                      ],
                    ),
                    AppSpacing.verticalXs,
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
