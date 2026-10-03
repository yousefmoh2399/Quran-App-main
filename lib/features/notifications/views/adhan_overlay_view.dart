import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/native/native_adhan_bridge.dart';
import 'package:quran_app_android/core/service/settings/notifications_services.dart';
import 'package:quran_app_android/core/util/arabic_date_formatter.dart';
import 'package:quran_app_android/core/util/assets.dart';
import 'package:quran_app_android/core/util/color.dart';

class AdhanOverlayView extends StatelessWidget {
  const AdhanOverlayView({super.key});

  static const Map<String, String> _prayerNameLookup = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args =
        Get.arguments as Map<String, dynamic>?;
    final String prayerKey = (args?['prayerKey'] as String?) ?? '';
    final int? notificationId = args?['notificationId'] as int?;
    final DateTime scheduledAt =
        (args?['scheduledAt'] as DateTime?) ?? DateTime.now();
    final String prayerName =
        _prayerNameLookup[prayerKey] ?? 'الصلاة';
    final String formattedTime =
        ArabicDateFormatter.formatTime12h(scheduledAt.toLocal());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  color: Colors.black87,
                  onPressed: () => _closeOverlay(notificationId),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      AssetsData.coming,
                      repeat: true,
                      height: 180,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'حان الآن وقت $prayerName',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.kPrimaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الوقت المحدد: $formattedTime',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '«حَافِظُوا عَلَى الصَّلَوَاتِ وَالصَّلَاةِ الْوُسْطَىٰ وَقُومُوا لِلَّهِ قَانِتِينَ»',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F5C4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _recordPrayedAndClose(
                            context,
                            prayerKey: prayerKey,
                            prayerName: prayerName,
                            status: PrayerStatus.onTime,
                            notificationId: notificationId,
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 20),
                          label: const Text(
                            'صليت في وقتها',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E824C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _recordPrayedAndClose(
                            context,
                            prayerKey: prayerKey,
                            prayerName: prayerName,
                            status: PrayerStatus.jamaah,
                            notificationId: notificationId,
                          ),
                          icon: const Icon(Icons.groups_rounded, size: 20),
                          label: const Text(
                            'صليت جماعة',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _closeOverlay(notificationId),
                      icon: const Icon(Icons.volume_off_rounded, size: 18, color: Colors.black54),
                      label: const Text(
                        'إيقاف الأذان فقط',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recordPrayedAndClose(
    BuildContext context, {
    required String prayerKey,
    required String prayerName,
    required PrayerStatus status,
    int? notificationId,
  }) async {
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final effectiveKey = prayerKey.isNotEmpty ? prayerKey : _guessCurrentPrayerKey();
      await UserRepository().savePrayerLog(PrayerLog(
        date: todayStr,
        prayer: effectiveKey,
        status: status,
      ));
      Get.snackbar(
        'تقبل الله طاعتكم 🤲',
        'تم تسجيل $prayerName (${status.labelAr}) في سجل صلواتك بنجاح.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F5C4A),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      debugPrint('Error recording prayer from overlay: $e');
    }
    _closeOverlay(notificationId);
  }

  String _guessCurrentPrayerKey() {
    final now = DateTime.now();
    final hour = now.hour;
    if (hour >= 4 && hour < 11) return 'fajr';
    if (hour >= 11 && hour < 15) return 'dhuhr';
    if (hour >= 15 && hour < 17) return 'asr';
    if (hour >= 17 && hour < 20) return 'maghrib';
    return 'isha';
  }

  void _closeOverlay(int? notificationId) {
    NativeAdhanBridge.stopAdhan();
    if (notificationId != null) {
      NotifyHelper().flutterLocalNotificationsPlugin.cancel(notificationId);
    }
    Get.back(closeOverlays: true);
  }
}
