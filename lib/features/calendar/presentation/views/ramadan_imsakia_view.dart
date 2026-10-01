import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../adhan/presentation/view_model/adhan_view_model.dart';
import '../../data/islamic_calendar_service.dart';

class RamadanImsakiaView extends StatefulWidget {
  const RamadanImsakiaView({super.key});

  @override
  State<RamadanImsakiaView> createState() => _RamadanImsakiaViewState();
}

class _RamadanImsakiaViewState extends State<RamadanImsakiaView> {
  final IslamicCalendarService _calendarService = IslamicCalendarService.instance;
  late int _ramadanYear;
  late DateTime _ramadanStartDate;
  List<Map<String, dynamic>> _imsakiaDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateImsakia();
  }

  void _calculateImsakia() {
    final todayHijri = _calendarService.getTodayHijri();
    _ramadanYear = (todayHijri.hMonth > 9) ? todayHijri.hYear + 1 : todayHijri.hYear;

    // 1st of Ramadan
    _ramadanStartDate = _calendarService.toGregorian(_ramadanYear, 9, 1);

    // Get coordinates from AdhanViewModel if available, default to Makkah (21.42, 39.82) or Cairo (30.04, 31.23)
    double lat = 30.0444;
    double lng = 31.2357;
    try {
      if (Get.isRegistered<AdhanViewModel>()) {
        final adhanVM = Get.find<AdhanViewModel>();
        if (adhanVM.latitude != null && adhanVM.longitude != null) {
          lat = adhanVM.latitude!;
          lng = adhanVM.longitude!;
        }
      }
    } catch (_) {}

    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    final days = <Map<String, dynamic>>[];

    for (int day = 1; day <= 30; day++) {
      final date = _ramadanStartDate.add(Duration(days: day - 1));
      final dateComponents = DateComponents(date.year, date.month, date.day);
      final pt = PrayerTimes(coordinates, dateComponents, params);

      final imsakTime = pt.fajr.subtract(const Duration(minutes: 10));

      days.add({
        'day': day,
        'date': date,
        'imsak': _formatTime(imsakTime),
        'fajr': _formatTime(pt.fajr),
        'sunrise': _formatTime(pt.sunrise),
        'dhuhr': _formatTime(pt.dhuhr),
        'asr': _formatTime(pt.asr),
        'maghrib': _formatTime(pt.maghrib),
        'isha': _formatTime(pt.isha),
        'fajrDateTime': pt.fajr,
        'maghribDateTime': pt.maghrib,
      });
    }

    setState(() {
      _imsakiaDays = days;
      _isLoading = false;
    });
  }

  String _formatTime(DateTime dt) {
    try {
      return DateFormat('hh:mm a', 'ar').format(dt);
    } catch (_) {
      int hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'م' : 'ص';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final hourStr = hour.toString().padLeft(2, '0');
      return '$hourStr:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text('إمساكية رمضان $_ramadanYear هـ'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Header Banner
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingLg,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: AppTypography.decorativeFont,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تقويم مواعيد الإمساك والإفطار والصلوات لشهر رمضان المبارك',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: colors.surface,
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: Text('اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('الإمساك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                      Expanded(flex: 2, child: Text('الفجر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal))),
                      Expanded(flex: 2, child: Text('المغرب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber))),
                      Expanded(flex: 2, child: Text('العشاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Imsakia 30-Day List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _imsakiaDays.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _imsakiaDays[index];
                      final dayNum = item['day'] as int;
                      final date = item['date'] as DateTime;
                      final now = DateTime.now();
                      final isToday = now.year == date.year && now.month == date.month && now.day == date.day;

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isToday ? colors.primary.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'رمضان $dayNum',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isToday ? colors.primary : colors.text,
                                    ),
                                  ),
                                  Text(
                                    '${date.day}/${date.month}',
                                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(flex: 2, child: Text(item['imsak'], style: const TextStyle(fontSize: 11, color: Colors.blueGrey))),
                            Expanded(flex: 2, child: Text(item['fajr'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary))),
                            Expanded(flex: 2, child: Text(item['maghrib'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange))),
                            Expanded(flex: 2, child: Text(item['isha'], style: const TextStyle(fontSize: 11))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
