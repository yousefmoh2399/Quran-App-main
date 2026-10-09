import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../controllers/reading_analytics_controller.dart';
import '../../data/models/reading_analytics_models.dart';

class ReadingAnalyticsView extends StatefulWidget {
  final ReadingAnalyticsController? controller;
  const ReadingAnalyticsView({super.key, this.controller});

  @override
  State<ReadingAnalyticsView> createState() => _ReadingAnalyticsViewState();
}

class _ReadingAnalyticsViewState extends State<ReadingAnalyticsView> {
  late final ReadingAnalyticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        (Get.isRegistered<ReadingAnalyticsController>()
            ? Get.find<ReadingAnalyticsController>()
            : Get.put(ReadingAnalyticsController()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppScaffold(
        title: 'إحصائيات التلاوة والنشاط',
        actions: [
          IconButton(
            tooltip: 'مشاركة ملخص الإنجاز',
            icon: Icon(Icons.share_rounded, color: colors.primary),
            onPressed: () => _controller.shareReport(),
          ),
        ],
        body: Obx(() {
          if (_controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }

          final summary = _controller.summary.value;
          if (summary == null) {
            return Center(
              child: Text(
                'تعذر تحميل إحصائيات القراءة',
                style: TextStyle(fontFamily: AppTypography.uiFont, color: colors.textMuted),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Metrics Grid (Streak, Total Pages, Khatma %, Hours)
                _buildMetricsGrid(summary, colors),
                const SizedBox(height: 16),

                // 2. Interactive Heatmap Card
                _buildHeatmapSection(summary, colors),
                const SizedBox(height: 16),

                // 3. Peak Reading Hours Breakdown
                _buildPeakHoursSection(summary, colors),
                const SizedBox(height: 16),

                // 4. Weekly Goal & Consistency Card
                _buildWeeklyGoalSection(summary, colors),
                const SizedBox(height: 20),

                // 5. Share Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _controller.shareReport(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: 1.5,
                    ),
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: Text(
                      'مشاركة بطاقة إنجازي القرآني',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMetricsGrid(ReadingAnalyticsSummary summary, AppColorsExtension colors) {
    final khatmaPercent = (summary.khatmaProgress * 100).toInt();
    final readingHours = (summary.totalReadingMinutes / 60.0).toStringAsFixed(1);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'سلسلة متواصلة',
                value: '${summary.streak.currentStreak}',
                unit: 'يوم',
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange.shade600,
                bgColor: Colors.orange.withOpacity(0.09),
                colors: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'إجمالي المقروء',
                value: '${summary.totalPagesRead}',
                unit: 'صفحة',
                icon: Icons.menu_book_rounded,
                iconColor: colors.primary,
                bgColor: colors.primary.withOpacity(0.09),
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'الختمة الحالية',
                value: '$khatmaPercent%',
                unit: 'من ٦٠٤',
                icon: Icons.mosque_rounded,
                iconColor: colors.accent,
                bgColor: colors.accent.withOpacity(0.12),
                colors: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: 'زمن التلاوة',
                value: readingHours,
                unit: 'ساعة',
                icon: Icons.timer_rounded,
                iconColor: Colors.teal.shade600,
                bgColor: Colors.teal.withOpacity(0.09),
                colors: colors,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required AppColorsExtension colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.5,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection(ReadingAnalyticsSummary summary, AppColorsExtension colors) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title & Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تقويم النشاط والقراءة التفاعلي',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'آخر ١٦ أسبوعاً من صحبة القرآن الكريم',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              _buildLegend(colors),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Heatmap Grid
          Obx(() {
            final selectedDay = _controller.selectedDay.value;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: _buildHeatmapGrid(summary.heatmapDays, selectedDay, colors),
            );
          }),

          const SizedBox(height: 14),

          // Selected Day Details Banner
          Obx(() {
            final day = _controller.selectedDay.value;
            if (day == null) return const SizedBox.shrink();
            return _buildSelectedDayCard(day, colors);
          }),
        ],
      ),
    );
  }

  Widget _buildLegend(AppColorsExtension colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'أقل',
          style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 10, color: colors.textMuted),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (i) => Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: _getIntensityColor(i, colors),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        const SizedBox(width: 4),
        Text(
          'أكثر',
          style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 10, color: colors.textMuted),
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid(
    List<ReadingHeatmapDay> days,
    ReadingHeatmapDay? selectedDay,
    AppColorsExtension colors,
  ) {
    // 16 columns of 7 days each = 112 days
    const numColumns = 16;
    const numRows = 7;

    final List<String> dayLabels = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels column
        Column(
          children: List.generate(numRows, (r) {
            return Container(
              height: 16,
              margin: const EdgeInsets.only(bottom: 3, left: 4),
              alignment: Alignment.center,
              child: Text(
                r % 2 == 0 ? dayLabels[r] : '',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 9,
                  color: colors.textMuted,
                ),
              ),
            );
          }),
        ),

        // Columns of days
        ...List.generate(numColumns, (c) {
          return Column(
            children: List.generate(numRows, (r) {
              final index = c * numRows + r;
              if (index >= days.length) return const SizedBox(width: 16, height: 16);
              final day = days[index];
              final isSelected = selectedDay?.dateString == day.dateString;
              final cellColor = _getIntensityColor(day.intensity, colors);

              return GestureDetector(
                onTap: () => _controller.selectDay(day),
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(3.5),
                    border: Border.all(
                      color: isSelected
                          ? colors.accent
                          : (day.isToday ? colors.primary : Colors.transparent),
                      width: isSelected ? 1.8 : (day.isToday ? 1.2 : 0),
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: colors.accent.withOpacity(0.4), blurRadius: 4)]
                        : null,
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Color _getIntensityColor(int intensity, AppColorsExtension colors) {
    final isDark = colors.isDark;
    switch (intensity) {
      case 0:
        return isDark ? const Color(0xFF1E2824) : const Color(0xFFE9EFE9);
      case 1:
        return isDark ? const Color(0xFF1B4D3E) : const Color(0xFFB5DEC8);
      case 2:
        return isDark ? const Color(0xFF196F4B) : const Color(0xFF75C79E);
      case 3:
        return isDark ? const Color(0xFF1F9861) : const Color(0xFF38A36C);
      case 4:
      default:
        return isDark ? const Color(0xFF27BA74) : const Color(0xFF167B48);
    }
  }

  static const _arDays = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  static const _arMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  String _formatArabicDate(DateTime date) {
    final dayName = _arDays[(date.weekday - 1) % 7];
    final monthName = _arMonths[(date.month - 1) % 12];
    return '$dayName، ${date.day} $monthName ${date.year}';
  }

  Widget _buildSelectedDayCard(ReadingHeatmapDay day, AppColorsExtension colors) {
    final formattedDate = _formatArabicDate(day.date);
    final statusText = day.pagesRead > 0
        ? 'تمت قراءة ${day.pagesRead} صفحة في قرابة ${day.minutesSpent} دقيقة'
        : 'لم تسجل قراءة في هذا اليوم';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(
            day.pagesRead > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: day.pagesRead > 0 ? colors.primary : colors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11,
                    color: day.pagesRead > 0 ? colors.primary : colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (day.isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'اليوم',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursSection(ReadingAnalyticsSummary summary, AppColorsExtension colors) {
    final primary = summary.primaryPeak;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: colors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أوقات الذروة للقراءة وتوزيع اليوم',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
            ],
          ),
          if (primary != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: colors.accent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'وقت ذروتك الأكثر بركة هو: ${primary.titleAr} (${(primary.percentage * 100).toInt()}%)',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // 5 intervals list
          ...summary.peakHours.map((bucket) {
            final percent = (bucket.percentage * 100).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(bucket.icon, size: 16, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        bucket.titleAr,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${bucket.timeRange})',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 10.5,
                          color: colors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: bucket.percentage.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: colors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        bucket.id == primary?.id ? colors.accent : colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalSection(ReadingAnalyticsSummary summary, AppColorsExtension colors) {
    final goal = summary.weeklyGoalPages;
    final current = summary.currentWeekPages;
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flag_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'الهدف القرآني الأسبوعي',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
              Text(
                '$current من $goal صفحة',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0
                ? '🎉 ما شاء الله! أنجزت هدفك الأسبوعي كاملاً، زادك الله توفيقاً وقبولاً!'
                : 'متبقي ${goal - current} صفحة لإتمام هدفك الأسبوعي ($percent% منجز).',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11.5,
              color: progress >= 1.0 ? Colors.green.shade700 : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
