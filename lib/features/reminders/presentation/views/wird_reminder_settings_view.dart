import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/design/responsive.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';

class WirdReminderSettingsView extends StatefulWidget {
  const WirdReminderSettingsView({super.key});

  @override
  State<WirdReminderSettingsView> createState() => _WirdReminderSettingsViewState();
}

class _WirdReminderSettingsViewState extends State<WirdReminderSettingsView> {
  final UserRepository _userRepo = UserRepository();
  bool _isLoading = true;
  WirdPlan? _plan;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    final plan = await _userRepo.getWirdPlan();
    if (plan != null) {
      _plan = plan;
      _enabled = plan.enabled;
      if (plan.reminderTime.isNotEmpty) {
        final parts = plan.reminderTime.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 20;
          final m = int.tryParse(parts[1]) ?? 0;
          _reminderTime = TimeOfDay(hour: h, minute: m);
        }
      }
    } else {
      // Default template
      final range = UserRepository.calculateWirdRange(
        type: WirdType.pagesPerDay,
        target: 10,
        fromPage: 1,
      );
      _plan = WirdPlan(
        type: WirdType.pagesPerDay,
        target: 10,
        startDate: DateTime.now().toIso8601String().substring(0, 10),
        reminderTime: '20:00',
        enabled: true,
        startPage: range['startPage']!,
        endPage: range['endPage']!,
        streak: 0,
      );
      await _userRepo.saveWirdPlan(_plan!);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _saveSettings() async {
    if (_plan == null) return;
    final timeStr = '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
    final updated = _plan!.copyWith(
      reminderTime: timeStr,
      enabled: _enabled,
    );
    await _userRepo.saveWirdPlan(updated);

    // Save in Native Reminders Engine
    await NativeRemindersBridge.saveReminder({
      'id': 'wird_daily',
      'type': 'wird_daily',
      'schedule_json': jsonEncode({'hour': _reminderTime.hour, 'minute': _reminderTime.minute}),
      'payload_json': jsonEncode({
        'title': 'وردك القرآني اليومي',
        'body': 'حان وقت وردك القرآني (صـ ${updated.startPage} إلى ${updated.endPage})',
        'start_page': updated.startPage,
      }),
      'enabled': _enabled ? 1 : 0,
      'last_triggered': 0,
    });

    Get.snackbar(
      'تم الحفظ',
      'تم تحديث موعد تذكير الورد القرآني وجدولته بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1B4D3E),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1B4D3E);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تذكير الورد اليومي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MaxWidthContainer(
              child: ListView(
                padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF14382D), const Color(0xFF0F2B22)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              const Text('🔥 ', style: TextStyle(fontSize: 20)),
                              Text(
                                '${_plan?.streak ?? 0}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                  color: isDark ? const Color(0xFF81C784) : primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text('أيام متتالية', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                      Column(
                        children: [
                          Text(
                            'صـ ${_plan?.startPage ?? 1} - ${_plan?.endPage ?? 10}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: isDark ? const Color(0xFF81C784) : primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('ورد اليوم المستهدف', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Enable Switch Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: const Text('تفعيل تذكير الورد اليومي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('يلغى الإشعار تلقائياً إذا أتممت قراءة وردك اليوم قبل حلول الموعد'),
                    value: _enabled,
                    activeColor: primary,
                    onChanged: (val) {
                      setState(() => _enabled = val);
                      _saveSettings();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Time Selection Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.access_time_rounded, color: Color(0xFF1B4D3E)),
                    title: const Text('وقت التذكير اليومي', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${_reminderTime.hour > 12 ? _reminderTime.hour - 12 : (_reminderTime.hour == 0 ? 12 : _reminderTime.hour)}:${_reminderTime.minute.toString().padLeft(2, '0')} ${_reminderTime.hour >= 12 ? 'م' : 'ص'}',
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary.withOpacity(0.12),
                        foregroundColor: primary,
                        elevation: 0,
                      ),
                      onPressed: _pickTime,
                      child: const Text('تغيير'),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('حفظ التفضيلات وجدولة التذكير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: _saveSettings,
                ),

                const SizedBox(height: 12),

                // Test Trigger
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.notification_important_rounded),
                  label: const Text('تجربة إشعار الورد اليومي الآن'),
                  onPressed: () async {
                    await NativeRemindersBridge.testTriggerReminder('wird_daily');
                    Get.snackbar(
                      'تم إرسال الإشعار',
                      'تفقّد لوحة الإشعارات واضغط عليه للفتح المباشر على المصحف',
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: primary,
                      colorText: Colors.white,
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}
