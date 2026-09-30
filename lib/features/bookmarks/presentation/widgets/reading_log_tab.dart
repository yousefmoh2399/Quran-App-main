import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../mushaf/presentation/utils/mushaf_utils.dart';
import '../controllers/bookmarks_controller.dart';

class ReadingLogTab extends StatelessWidget {
  final BookmarksController controller;

  const ReadingLogTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final logs = controller.readingLogs;

      if (logs.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_edu_rounded, size: 56.0, color: colors.textMuted.withOpacity(0.5)),
              AppSpacing.verticalSm,
              Text(
                'لم يتم تسجيل أي قراءة بعد\nاقرأ لمدة ٥ ثوانٍ في المصحف لتسجيل جلساتك تلقائياً',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colors.textMuted, height: 1.5),
              ),
            ],
          ),
        );
      }

      final totalPages = logs.fold<int>(0, (sum, item) => sum + item.pagesRead);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayLog = logs.firstWhereOrNull((l) => l.date == todayStr);
      final todayPages = todayLog?.pagesRead ?? 0;

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Reading Overview Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: colors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_rounded, color: colors.accent, size: 22.0),
                    AppSpacing.horizontalXs,
                    Text(
                      'ملخص القراءة اليومية',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalMd,

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewColumn(
                      title: 'اليوم',
                      value: '$todayPages ص',
                      subtitle: 'صفحات اليوم',
                      color: colors.primary,
                    ),
                    Container(width: 1.0, height: 40.0, color: colors.divider),
                    _buildOverviewColumn(
                      title: 'إجمالي الصفحات',
                      value: '$totalPages ص',
                      subtitle: 'كل الجلسات',
                      color: colors.accent,
                    ),
                    Container(width: 1.0, height: 40.0, color: colors.divider),
                    _buildOverviewColumn(
                      title: 'أيام التلاوة',
                      value: '${logs.length} يوماً',
                      subtitle: 'نشاط مستمر',
                      color: colors.text,
                    ),
                  ],
                ),

                // Mini Bar Chart of last 7 entries
                if (logs.length >= 2) ...[
                  AppSpacing.verticalLg,
                  Text(
                    'نشاط القراءة في الأيام السابقة',
                    style: textTheme.labelMedium?.copyWith(color: colors.textMuted),
                  ),
                  AppSpacing.verticalSm,
                  SizedBox(
                    height: 60.0,
                    child: _buildMiniBarChart(logs.take(7).toList().reversed.toList(), colors),
                  ),
                ],
              ],
            ),
          ),

          AppSpacing.verticalLg,

          // Days List Header
          Text(
            'سجل الأيام السابقة',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          AppSpacing.verticalSm,

          // Days List
          ...logs.map((entry) {
            final isToday = entry.date == todayStr;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: isToday ? colors.primary.withOpacity(0.06) : colors.surface,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: isToday ? colors.primary.withOpacity(0.3) : colors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    // Date indicator badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: isToday ? colors.primary : colors.bg,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(color: colors.divider),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isToday ? 'اليوم' : _formatDate(entry.date),
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : colors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.horizontalMd,

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'قرأت ${toArabicDigits(entry.pagesRead)} صفحة',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                          AppSpacing.verticalXs,
                          Text(
                            'آخر صفحة تمت قراءتها: صـ ${toArabicDigits(entry.lastPage)}',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              color: colors.textMuted,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Jump Button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      ),
                      icon: const Icon(Icons.menu_book_rounded, size: 16.0),
                      label: const Text(
                        'متابعة',
                        style: TextStyle(fontFamily: AppTypography.uiFont, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        controller.openMushaf(page: entry.lastPage);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  Widget _buildOverviewColumn({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBarChart(List dynamicLogs, AppColorsExtension colors) {
    int maxPages = 1;
    for (final l in dynamicLogs) {
      if (l.pagesRead > maxPages) maxPages = l.pagesRead;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dynamicLogs.map<Widget>((log) {
        final heightRatio = (log.pagesRead / maxPages).clamp(0.15, 1.0);
        final dayLabel = log.date.substring(8); // DD

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 40.0 * heightRatio,
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  toArabicDigits(int.tryParse(dayLabel) ?? 0),
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 10.0,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length == 3) {
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      return '${toArabicDigits(d)}/${toArabicDigits(m)}';
    }
    return isoDate;
  }
}
