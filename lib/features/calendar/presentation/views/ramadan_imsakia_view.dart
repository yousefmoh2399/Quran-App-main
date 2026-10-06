import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/ramadan/data/ramadan_service.dart';

class RamadanImsakiaView extends StatefulWidget {
  const RamadanImsakiaView({super.key});

  @override
  State<RamadanImsakiaView> createState() => _RamadanImsakiaViewState();
}

class _RamadanImsakiaViewState extends State<RamadanImsakiaView> {
  final RamadanService _ramadanService = RamadanService.instance;
  late int _ramadanYear;
  List<RamadanDayInfo> _imsakiaDays = [];
  bool _isLoading = true;
  int _imsakOffset = 15; // 15 or 20 minutes before Fajr
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ramadanYear = _ramadanService.getRamadanYear();
    _loadImsakia();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadImsakia() {
    setState(() => _isLoading = true);
    final days = _ramadanService.calculate30DaysImsakia(imsakMinutesBeforeFajr: _imsakOffset);
    setState(() {
      _imsakiaDays = days;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    final todayIndex = _imsakiaDays.indexWhere((d) => d.isToday);
    if (todayIndex != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(
        (todayIndex * 60.0).clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showDayDetails(RamadanDayInfo day) {
    HapticFeedback.lightImpact();
    Get.bottomSheet(
      Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مواقيت يوم ${day.dayNumber} رمضان $_ramadanYear هـ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${day.gregorianDate.day}/${day.gregorianDate.month}/${day.gregorianDate.year}',
                  style: TextStyle(color: context.appColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('موعد الإمساك (قبل الفجر بـ $_imsakOffset دقيقة)', day.imsakTime, Colors.blueGrey, Icons.nightlight_outlined),
            _buildDetailRow('أذان الفجر', day.fajrTime, context.appColors.primary, Icons.wb_twilight_rounded),
            _buildDetailRow('الشروق', day.sunriseTime, Colors.orange, Icons.wb_sunny_outlined),
            _buildDetailRow('أذان الظهر', day.dhuhrTime, context.appColors.text, Icons.wb_sunny_rounded),
            _buildDetailRow('أذان العصر', day.asrTime, context.appColors.text, Icons.wb_cloudy_rounded),
            _buildDetailRow('أذان المغرب (الإفطار)', day.maghribTime, Colors.deepOrange, Icons.restaurant_rounded, isHighlight: true),
            _buildDetailRow('أذان العشاء والتراويح', day.ishaTime, context.appColors.primary, Icons.bedtime_rounded),
            const SizedBox(height: 12),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String title, String time, Color color, IconData icon, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFF09261E).withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isHighlight ? Border.all(color: const Color(0xFFD4AF37)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  color: isHighlight ? const Color(0xFF09261E) : context.appColors.text,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      title: 'إمساكية رمضان $_ramadanYear هـ',
      constrainContentWidth: true,
      actions: [
        IconButton(
          tooltip: 'الانتقال إلى اليوم',
          onPressed: _scrollToToday,
          icon: const Icon(Icons.my_location_rounded),
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF09261E), Color(0xFF134E3E)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontFamily: AppTypography.decorativeFont,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'مواقيت الإمساك والإفطار والصلوات محسوبة محلياً بنسبة 100% بدون إنترنت',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('احتساب الإمساك قبل الفجر بـ: ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          DropdownButton<int>(
                            value: _imsakOffset,
                            dropdownColor: const Color(0xFF09261E),
                            style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD4AF37)),
                            items: const [
                              DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                              DropdownMenuItem(value: 20, child: Text('20 دقيقة')),
                              DropdownMenuItem(value: 10, child: Text('10 دقائق')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _imsakOffset = val);
                                _loadImsakia();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Table Column Headers
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: colors.surface,
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: Text('اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 2, child: Text('الإمساك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                      Expanded(flex: 2, child: Text('الفجر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal))),
                      Expanded(flex: 2, child: Text('المغرب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange))),
                      Expanded(flex: 2, child: Text('العشاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // 30 Days List
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    itemCount: _imsakiaDays.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _imsakiaDays[index];

                      return InkWell(
                        onTap: () => _showDayDetails(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: item.isToday ? colors.primary.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: item.isToday ? Border.all(color: colors.primary.withOpacity(0.4)) : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'رمضان ${item.dayNumber}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: item.isToday ? colors.primary : colors.text,
                                          ),
                                        ),
                                        if (item.isToday)
                                          Container(
                                            margin: const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: colors.primary,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('اليوم', style: TextStyle(color: Colors.white, fontSize: 9)),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '${item.gregorianDate.day}/${item.gregorianDate.month}',
                                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(item.imsakTime, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(item.fajrTime, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.primary)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(item.maghribTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(item.ishaTime, style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
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
