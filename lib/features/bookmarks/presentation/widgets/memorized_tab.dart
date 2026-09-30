import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../mushaf/presentation/utils/mushaf_utils.dart';
import '../controllers/bookmarks_controller.dart';

class MemorizedTab extends StatelessWidget {
  final BookmarksController controller;

  const MemorizedTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final stats = controller.memorizationStats;
      final memorizedPages = (stats['memorizedPages'] as int?) ?? 0;
      final learningPages = (stats['learningPages'] as int?) ?? 0;
      final reviewPages = (stats['reviewPages'] as int?) ?? 0;
      final percentage = (stats['percentage'] as double?) ?? 0.0;
      final juzCount = (stats['juzCount'] as double?) ?? 0.0;

      final items = controller.memorizedList;

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Memorization Stats Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary,
                  colors.primary.withOpacity(0.85),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: AppRadius.borderLg,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.25),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إحصائيات الحفظ',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}% من المصحف',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSm,

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: (percentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 8.0,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                AppSpacing.verticalMd,

                // Metric Counters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      title: 'محفوظ',
                      count: '$memorizedPages ص (${juzCount.toStringAsFixed(1)} جزء)',
                      color: Colors.white,
                    ),
                    Container(width: 1.0, height: 32.0, color: Colors.white.withOpacity(0.3)),
                    _buildStatItem(
                      title: 'بيحفظ',
                      count: '$learningPages ص',
                      color: Colors.white,
                    ),
                    Container(width: 1.0, height: 32.0, color: Colors.white.withOpacity(0.3)),
                    _buildStatItem(
                      title: 'مراجعة',
                      count: '$reviewPages ص',
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),

          AppSpacing.verticalLg,

          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قائمة المحفوظات',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              Text(
                '${items.length} عنصر',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  color: colors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,

          // Items List
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.workspace_premium_outlined, size: 48.0, color: colors.textMuted.withOpacity(0.5)),
                  AppSpacing.verticalSm,
                  Text(
                    'لم تقم بتحديد أي آيات أو صفحات في خطة الحفظ بعد',
                    style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Dismissible(
                  key: ValueKey('mem_${item.id}_${item.page}_${item.ayah}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20.0),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28.0),
                  ),
                  onDismissed: (_) {
                    controller.deleteMemorized(item);
                  },
                  child: InkWell(
                    borderRadius: AppRadius.borderMd,
                    onTap: () {
                      controller.openMushaf(
                        page: item.page,
                        surah: item.surah,
                        ayah: item.ayah,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: colors.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4.0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Status Icon Badge
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: item.status.badgeColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              color: item.status.badgeColor,
                              size: 20.0,
                            ),
                          ),
                          AppSpacing.horizontalMd,

                          // Title & Reference
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.type == BookmarkType.ayah
                                      ? 'سورة ${controller.getSurahName(item.surah)}  •  آية ${toArabicDigits(item.ayah ?? 1)}'
                                      : 'صفحة ${toArabicDigits(item.page)}${controller.getSurahName(item.surah).isNotEmpty ? "  •  سورة ${controller.getSurahName(item.surah)}" : ""}',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.text,
                                  ),
                                ),
                                AppSpacing.verticalXs,
                                Text(
                                  'صـ ${toArabicDigits(item.page)}',
                                  style: TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                    color: colors.textMuted,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status Menu
                          PopupMenuButton<MemorizeStatus?>(
                            initialValue: item.status,
                            tooltip: 'تغيير الحالة',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: item.status.badgeColor.withOpacity(0.15),
                                borderRadius: AppRadius.borderSm,
                                border: Border.all(color: item.status.badgeColor.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.status.labelAr,
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: item.status.badgeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4.0),
                                  Icon(Icons.arrow_drop_down_rounded, size: 18.0, color: item.status.badgeColor),
                                ],
                              ),
                            ),
                            onSelected: (newStatus) {
                              controller.updateMemorizeStatus(item, newStatus);
                            },
                            itemBuilder: (context) => [
                              ...MemorizeStatus.values.map(
                                (st) => PopupMenuItem(
                                  value: st,
                                  child: Row(
                                    children: [
                                      CircleAvatar(backgroundColor: st.badgeColor, radius: 6.0),
                                      AppSpacing.horizontalSm,
                                      Text(
                                        st.labelAr,
                                        style: TextStyle(
                                          fontFamily: AppTypography.uiFont,
                                          fontWeight: item.status == st ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18.0, color: colors.error),
                                    AppSpacing.horizontalSm,
                                    Text(
                                      'إزالة من الحفظ',
                                      style: TextStyle(
                                        fontFamily: AppTypography.uiFont,
                                        color: colors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ],
      );
    });
  }

  Widget _buildStatItem({
    required String title,
    required String count,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 12.0,
            color: color.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          count,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
