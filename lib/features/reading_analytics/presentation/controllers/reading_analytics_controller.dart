import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/reading_analytics_models.dart';
import '../../data/services/reading_analytics_service.dart';

class ReadingAnalyticsController extends GetxController {
  final ReadingAnalyticsService _service;

  ReadingAnalyticsController({ReadingAnalyticsService? service})
      : _service = service ?? ReadingAnalyticsService.instance;

  final RxBool isLoading = true.obs;
  final Rxn<ReadingAnalyticsSummary> summary = Rxn<ReadingAnalyticsSummary>();
  final Rxn<ReadingHeatmapDay> selectedDay = Rxn<ReadingHeatmapDay>();

  @override
  void onInit() {
    super.onInit();
    if (summary.value == null) {
      loadAnalytics();
    }
  }

  Future<void> loadAnalytics() async {
    isLoading.value = true;
    try {
      final s = await _service.getAnalyticsSummary();
      summary.value = s;
      if (s.heatmapDays.isNotEmpty) {
        selectedDay.value = s.heatmapDays.lastWhere((d) => d.isToday, orElse: () => s.heatmapDays.last);
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('ReadingAnalyticsController.loadAnalytics error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  void selectDay(ReadingHeatmapDay day) {
    selectedDay.value = day;
  }

  void shareReport() {
    final s = summary.value;
    if (s == null) return;

    final streak = s.streak.currentStreak;
    final totalPages = s.totalPagesRead;
    final dailyAvg = s.dailyAveragePages;
    final peak = s.primaryPeak?.titleAr ?? 'الفجر';

    final text = '''
📊 تقرير إنجازي في تلاوة القرآن الكريم:
🔥 سلسلة القراءة المتواصلة: $streak يوم
📖 إجمالي الصفحات المقروءة: $totalPages صفحة
📈 المعدل اليومي: $dailyAvg صفحة/يوم
🌅 وقت الذروة المفضل: $peak

قال النبي ﷺ: «اقْرَءُوا الْقُرْآنَ فَإِنَّهُ يَأْتِي يَوْمَ الْقِيَامَةِ شَفِيعًا لِأَصْحَابِهِ»
عبر تطبيق تقرّب
''';

    Share.share(text.trim());
  }
}
