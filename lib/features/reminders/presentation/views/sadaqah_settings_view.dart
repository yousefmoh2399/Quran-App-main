import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/responsive.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';

class SadaqahSettingsView extends StatefulWidget {
  const SadaqahSettingsView({super.key});

  @override
  State<SadaqahSettingsView> createState() => _SadaqahSettingsViewState();
}

class _SadaqahSettingsViewState extends State<SadaqahSettingsView> {
  bool _isLoading = true;
  bool _enabled = true;
  String _calendar = 'hijri'; // 'hijri' or 'gregorian'
  String _dayType = 'day_of_month'; // 'day_of_month', 'last_working_day', 'last_thursday'
  int _dayOfMonth = 25;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 10, minute: 0);
  bool _secondReminder = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final reminder = await NativeRemindersBridge.getReminder('sadaqah_monthly');
    if (reminder != null) {
      _enabled = reminder['enabled'] == 1;
      try {
        final schedule = jsonDecode(reminder['schedule_json'] as String) as Map<String, dynamic>;
        _calendar = (schedule['calendar'] as String?) ?? 'hijri';
        _dayType = (schedule['day_type'] as String?) ?? 'day_of_month';
        _dayOfMonth = (schedule['day'] as num?)?.toInt() ?? 25;
        final h = (schedule['hour'] as num?)?.toInt() ?? 10;
        final m = (schedule['minute'] as num?)?.toInt() ?? 0;
        _reminderTime = TimeOfDay(hour: h, minute: m);
        _secondReminder = (schedule['second_reminder'] as bool?) ?? true;
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final scheduleMap = {
      'calendar': _calendar,
      'day_type': _dayType,
      'day': _dayOfMonth,
      'hour': _reminderTime.hour,
      'minute': _reminderTime.minute,
      'second_reminder': _secondReminder,
    };

    final payloadMap = {
      'title': 'تذكير الصدقة الشهرية',
      'amount': 0,
    };

    final item = {
      'id': 'sadaqah_monthly',
      'type': 'sadaqah_monthly',
      'schedule_json': jsonEncode(scheduleMap),
      'payload_json': jsonEncode(payloadMap),
      'enabled': _enabled ? 1 : 0,
      'last_triggered': 0,
    };

    await NativeRemindersBridge.saveReminder(item);

    if (mounted) {
      AppSnackbar.show(
        'تم الحفظ',
        'تم تحديث إعدادات تذكير الصدقة وإعادة جدولتها بنجاح 🌿',
        context: context,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1B4D3E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تذكير الصدقة الشهرية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل الصدقات',
            onPressed: () => Get.toNamed('/sadaqahLogs'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MaxWidthContainer(
              child: ListView(
                padding: const EdgeInsets.all(16),
              children: [
                // Enable Toggle Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: const Text('تفعيل تذكير الصدقة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('إشعار شهري ذكي مع أحاديث نبوية وزر "تصدّقت"', style: TextStyle(fontSize: 12.5)),
                    value: _enabled,
                    activeColor: primary,
                    onChanged: (val) {
                      setState(() => _enabled = val);
                      _saveSettings();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Calendar Type Selection
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('نوع التقويم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('تقويم هجري 🌙')),
                                selected: _calendar == 'hijri',
                                selectedColor: primary.withOpacity(0.2),
                                onSelected: (sel) {
                                  if (sel) setState(() => _calendar = 'hijri');
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('تقويم ميلادي 📅')),
                                selected: _calendar == 'gregorian',
                                selectedColor: primary.withOpacity(0.2),
                                onSelected: (sel) {
                                  if (sel) setState(() => _calendar = 'gregorian');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Day Selection Option
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('موعد التذكير في الشهر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),

                        RadioListTile<String>(
                          value: 'day_of_month',
                          groupValue: _dayType,
                          title: Text('يوم محدد من الشهر (يوم $_dayOfMonth)'),
                          subtitle: const Text('إذا كان الشهر أقصر، يتم التذكير تلقائياً في آخر يوم من الشهر'),
                          activeColor: primary,
                          onChanged: (val) => setState(() => _dayType = val!),
                        ),

                        if (_dayType == 'day_of_month') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Text('اليوم: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('$_dayOfMonth', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 18)),
                                Expanded(
                                  child: Slider(
                                    value: _dayOfMonth.toDouble(),
                                    min: 1,
                                    max: 31,
                                    divisions: 30,
                                    activeColor: primary,
                                    label: '$_dayOfMonth',
                                    onChanged: (val) => setState(() => _dayOfMonth = val.toInt()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        RadioListTile<String>(
                          value: 'last_working_day',
                          groupValue: _dayType,
                          title: const Text('آخر يوم عمل في الشهر'),
                          subtitle: const Text('آخر يوم عمل رسمي (الأحد - الخميس، مع تجنب الجمعة والسبت)'),
                          activeColor: primary,
                          onChanged: (val) => setState(() => _dayType = val!),
                        ),

                        RadioListTile<String>(
                          value: 'last_thursday',
                          groupValue: _dayType,
                          title: const Text('آخر خميس في الشهر'),
                          subtitle: const Text('يوم الخميس الأخير من الشهر تزامناً مع فضل صيام أو ختام الأسبوع'),
                          activeColor: primary,
                          onChanged: (val) => setState(() => _dayType = val!),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Time Picker & Second Reminder
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.access_time_rounded, color: Color(0xFF1B4D3E)),
                        title: const Text('وقت التذكير', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('تذكير ثانٍ بعد يومين', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('إشعار متابعة لطيف بعد 48 ساعة إذا لم تسجل الصدقة في التذكير الأول'),
                        value: _secondReminder,
                        activeColor: primary,
                        onChanged: (val) => setState(() => _secondReminder = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button & Test Trigger
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

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.notification_important_rounded),
                  label: const Text('تجربة إشعار الصدقة وزر "تصدّقت" الآن'),
                  onPressed: () async {
                    await NativeRemindersBridge.testTriggerReminder('sadaqah_monthly');
                    if (context.mounted) {
                      AppSnackbar.show(
                        'تم إرسال الإشعار',
                        'تفقّد لوحة الإشعارات واضغط على زر "تصدّقت ✓" لتجربة التسجيل المباشر',
                        context: context,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }
}
