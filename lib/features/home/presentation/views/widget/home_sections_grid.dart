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
  final IconData icon;
  final String route;

  const _SectionItem({
    required this.title,
    required this.subtitle,
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
      icon: Icons.menu_book_rounded,
      route: AppRoutes.quranScreen,
    ),
    _SectionItem(
      title: 'حصن المسلم',
      subtitle: 'أذكار وأدعية',
      icon: Icons.spa_rounded,
      route: AppRoutes.azkar,
    ),
    _SectionItem(
      title: 'مواقيت الصلاة',
      subtitle: 'الأذان والإقامة',
      icon: Icons.access_time_rounded,
      route: AppRoutes.adhan,
    ),
    _SectionItem(
      title: 'اتجاه القبلة',
      subtitle: 'بوصلة الكعبة',
      icon: Icons.explore_rounded,
      route: AppRoutes.qiblah,
    ),
    _SectionItem(
      title: 'الحديث النبوي',
      subtitle: 'موطأ مالك',
      icon: Icons.auto_stories_rounded,
      route: AppRoutes.sectionHadith,
    ),
    _SectionItem(
      title: 'أسماء الله الحسنى',
      subtitle: 'معاني وشروح',
      icon: Icons.stars_rounded,
      route: AppRoutes.nameofAllah,
    ),
    _SectionItem(
      title: 'التفسير الميسر',
      subtitle: 'تفسير الآيات',
      icon: Icons.library_books_rounded,
      route: AppRoutes.tafsser,
    ),
    _SectionItem(
      title: 'السبحة الإلكترونية',
      subtitle: 'عداد التسبيح',
      icon: Icons.fingerprint_rounded,
      route: AppRoutes.pngTree,
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.12),
                            borderRadius: AppRadius.borderMd,
                            border: Border.all(
                              color: colors.primary.withOpacity(0.18),
                            ),
                          ),
                          child: Icon(
                            item.icon,
                            color: colors.primary,
                            size: 22,
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
