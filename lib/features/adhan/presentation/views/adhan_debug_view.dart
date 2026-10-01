import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

class AdhanDebugView extends StatefulWidget {
  const AdhanDebugView({super.key});

  @override
  State<AdhanDebugView> createState() => _AdhanDebugViewState();
}

class _AdhanDebugViewState extends State<AdhanDebugView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _upcomingPrayers = [];
  Map<String, dynamic>? _nativeSettings;

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  Future<void> _loadDebugData() async {
    setState(() => _isLoading = true);
    try {
      final prayers = await NativeAdhanBridge.getUpcomingPrayers();
      final settings = await NativeAdhanBridge.getSettings();
      setState(() {
        _upcomingPrayers = prayers;
        _nativeSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading debug adhan data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerTestAdhan() async {
    Get.snackbar(
      'جدولة أذان تجريبي',
      'سيتم إطلاق شاشة وصوت الأذان فوق القفل بعد 10 ثوانٍ بالتمام! ⏱️',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F5C4A),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
    await NativeAdhanBridge.scheduleTestAdhan(delaySeconds: 10, prayerName: 'الفجر التجريبي');
  }

  Future<void> _forceRecalculate() async {
    final count = await NativeAdhanBridge.recalculateAndSchedule();
    await _loadDebugData();
    Get.snackbar(
      'إعادة الجدولة الفلكية',
      'تم إعادة حساب وجدولة $count صلاة بنجاح للـ 7 أيام القادمة 🕋',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F5C4A),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug mode only')),
      );
    }

    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'فحص واختبار محرك الأذان Native',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: _loadDebugData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                        ),
                        icon: const Icon(Icons.timer_outlined, size: 20),
                        label: const Text(
                          'جرّب أذان بعد 10 ثواني',
                          style: TextStyle(fontFamily: AppTypography.uiFont, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _triggerTestAdhan,
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                        ),
                        icon: Icon(Icons.sync_rounded, color: colors.primary, size: 20),
                        label: Text(
                          'إعادة جدولة 7 أيام',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                        onPressed: _forceRecalculate,
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalMd,

                // Current Native Settings Card
                if (_nativeSettings != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: colors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: colors.primary, size: 18),
                            AppSpacing.horizontalXs,
                            Text(
                              'إعدادات المحرك المسجلة في Kotlin',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontWeight: FontWeight.bold,
                                color: colors.text,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          'الإحداثيات: ${_nativeSettings!['latitude']}, ${_nativeSettings!['longitude']}',
                          style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12.0, color: colors.textMuted),
                        ),
                        Text(
                          'طريقة الحساب: ${_nativeSettings!['calculationMethod']} | المذهب: ${_nativeSettings!['madhab']}',
                          style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12.0, color: colors.textMuted),
                        ),
                        Text(
                          'المنطقة الزمنية: ${_nativeSettings!['timeZoneId']}',
                          style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12.0, color: colors.textMuted),
                        ),
                        Text(
                          'الصوت المختار: ${_nativeSettings!['adhanSound']}',
                          style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12.0, color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalMd,
                ],

                // Upcoming 7-day scheduled alarms
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الصلوات المجدولة القادمة (${toArabicDigits(_upcomingPrayers.length)} صلاة)',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      'نافذة الـ 7 أيام (Rolling)',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalXs,

                if (_upcomingPrayers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    alignment: Alignment.center,
                    child: Text(
                      'لا توجد صلوات مجدولة حالياً (تحقق من الموقع واضغط إعادة الجدولة)',
                      style: TextStyle(fontFamily: AppTypography.uiFont, color: colors.textMuted),
                    ),
                  )
                else
                  ..._upcomingPrayers.map((prayer) {
                    final dayOffset = prayer['dayOffset'] as int? ?? 0;
                    final dayTitle = dayOffset == 0 ? 'اليوم' : 'بعد ${toArabicDigits(dayOffset)} أيام';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: colors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.12),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Icon(Icons.alarm_on_rounded, color: colors.primary, size: 20),
                          ),
                          AppSpacing.horizontalSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      prayer['prayerName'] ?? '',
                                      style: TextStyle(
                                        fontFamily: AppTypography.uiFont,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: colors.text,
                                      ),
                                    ),
                                    AppSpacing.horizontalXs,
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: colors.divider,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        dayTitle,
                                        style: TextStyle(
                                          fontFamily: AppTypography.uiFont,
                                          fontSize: 10.5,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  prayer['formattedTime'] ?? '',
                                  style: TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                    fontSize: 12.0,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                prayer['notificationMode'] == 'adhan' ? 'أذان كامل' : 'تنبيه فقط',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  color: colors.accent,
                                ),
                              ),
                              Text(
                                'ID: ${prayer['requestCode']}',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 10.0,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
