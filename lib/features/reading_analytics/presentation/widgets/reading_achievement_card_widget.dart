import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/design/app_typography.dart';
import '../../data/models/reading_analytics_models.dart';

/// High-resolution, professional Islamic image card representing user's reading achievements.
/// Designed for social sharing (WhatsApp Status, Instagram Story, etc.) with 300+ DPI capture.
class ReadingAchievementCardWidget extends StatelessWidget {
  final ReadingAnalyticsSummary summary;

  const ReadingAchievementCardWidget({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final khatmaPercent = (summary.khatmaProgress * 100).toInt();
    final readingHours = (summary.totalReadingMinutes / 60.0).toStringAsFixed(1);
    final peakTitle = summary.primaryPeak?.titleAr ?? 'الفجر وبكور اليوم';

    // Formatted dates
    final hijri = HijriCalendar.now();
    final hijriStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';
    final gregStr = DateFormat('d MMMM yyyy', 'ar').format(DateTime.now());

    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071A11),
            Color(0xFF0F3622),
            Color(0xFF081F15),
            Color(0xFF05130B),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.85),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Ornament & Header
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                    width: 1,
                  ),
                  color: const Color(0xFFD4AF37).withOpacity(0.12),
                ),
                child: const Text(
                  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                  style: TextStyle(
                    fontFamily: AppTypography.quranFont,
                    color: Color(0xFFE8D08D),
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card Title & Branding
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFD4AF37),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'إنجازي في تلاوة القرآن الكريم',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'تَقَرُّبْ | TAQARRAB',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  color: const Color(0xFFD4AF37).withOpacity(0.75),
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Subtle Gold Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4AF37).withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 4 Core Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'سلسلة متواصلة',
                    value: '${summary.streak.currentStreak}',
                    unit: 'يوم',
                    icon: Icons.local_fire_department_rounded,
                    accentColor: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'إجمالي المقروء',
                    value: '${summary.totalPagesRead}',
                    unit: 'صفحة',
                    icon: Icons.auto_stories_rounded,
                    accentColor: const Color(0xFFE8D08D),
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
                    accentColor: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'زمن التلاوة',
                    value: readingHours,
                    unit: 'ساعة',
                    icon: Icons.timer_rounded,
                    accentColor: const Color(0xFF26A69A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Khatma Progress Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.black.withOpacity(0.25),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تقدم الختمة المباركة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${summary.totalPagesRead % 604} / 604 صفحة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          color: const Color(0xFFE8D08D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: summary.khatmaProgress > 0 ? summary.khatmaProgress : 0.01,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Peak Hour Highlight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wb_twilight_rounded,
                    color: Color(0xFFE8D08D),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'وقت التلاوة المفضل: ',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    peakTitle,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      color: const Color(0xFFE8D08D),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Prophetic Hadith Quote
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.2),
              ),
              child: Column(
                children: [
                  const Text(
                    '«اقْرَءُوا الْقُرْآنَ فَإِنَّهُ يَأْتِي يَوْمَ الْقِيَامَةِ شَفِيعًا لِأَصْحَابِهِ»',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.hadithFont,
                      color: Color(0xFFE8D08D),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '— صحيح مسلم',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      color: Colors.white54,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Footer info: Date & App Branding
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hijriStr,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      gregStr,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: Colors.white38,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFFD4AF37),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'تطبيق تقرّب',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: const Color(0xFFD4AF37).withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: accentColor),
          ),
          const SizedBox(width: 8),
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
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 10,
                        color: Colors.white54,
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
}
