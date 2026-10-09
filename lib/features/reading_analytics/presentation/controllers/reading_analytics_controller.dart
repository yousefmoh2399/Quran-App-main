import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/reading_analytics_models.dart';
import '../../data/services/reading_analytics_service.dart';

class ReadingAnalyticsController extends GetxController {
  final ReadingAnalyticsService _service;

  ReadingAnalyticsController({ReadingAnalyticsService? service})
      : _service = service ?? ReadingAnalyticsService.instance;

  final RxBool isLoading = true.obs;
  final RxBool isExporting = false.obs;
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

  /// Exports the reading achievement card to high-res PNG and opens native sharing sheet
  Future<void> shareAsImage(BuildContext context, GlobalKey cardKey) async {
    if (isExporting.value) return;
    isExporting.value = true;
    AppHaptics.itemCompleted();

    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Get.snackbar(
          'تنبيه',
          'تعذر قراءة بطاقة الإنجاز، يرجى المحاولة مرة ثانية',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Capture share position origin synchronously before async operations
      Rect? shareOrigin;
      try {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          shareOrigin = box.localToGlobal(Offset.zero) & box.size;
        }
      } catch (_) {}

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'taqarrab_reading_achievement_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        final xFile = XFile(file.path, mimeType: 'image/png');

        final s = summary.value;
        final streak = s?.streak.currentStreak ?? 0;
        final pages = s?.totalPagesRead ?? 0;

        await Share.shareXFiles(
          [xFile],
          text: '📊 إنجازي في تلاوة القرآن الكريم: $pages صفحة | سلسلة $streak يوم متواصل 🔥\nعبر تطبيق تقرّب (بدون إنترنت)',
          sharePositionOrigin: shareOrigin,
        );
      }
    } catch (e) {
      debugPrint('Error generating achievement card image: $e');
      Get.snackbar(
        'تنبيه',
        'حدث خطأ أثناء تصدير الصورة، يرجى المحاولة لاحقاً',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isExporting.value = false;
    }
  }

  /// Saves the achievement card image to the device files
  Future<void> saveCardToDevice(BuildContext context, GlobalKey cardKey) async {
    if (isExporting.value) return;
    isExporting.value = true;
    AppHaptics.itemCompleted();

    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List? pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'إنجاز_قرآني_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        Get.snackbar(
          'تم حفظ البطاقة بنجاح ✅',
          'تم حفظ بطاقة إنجازك القرآني بجودة فائقة في ملفات التطبيق',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error saving card: $e');
      Get.snackbar('خطأ', 'تعذر حفظ البطاقة في الجهاز', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isExporting.value = false;
    }
  }

  /// Shares as formatted text
  void shareReportText() {
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
عبر تطبيق تقرّب (بدون إنترنت)
''';

    Share.share(text.trim());
  }

  void shareReport() {
    shareReportText();
  }
}
