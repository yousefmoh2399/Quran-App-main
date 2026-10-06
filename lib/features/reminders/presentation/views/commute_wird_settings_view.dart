import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/responsive.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';
import 'package:quran_app_android/features/reminders/data/commute_wird_repository.dart';

class CommuteSlot {
  String id;
  String title;
  int hour;
  int minute;
  int targetPages;

  CommuteSlot({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.targetPages,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'hour': hour,
        'minute': minute,
        'target_pages': targetPages,
      };

  factory CommuteSlot.fromMap(Map<String, dynamic> map) => CommuteSlot(
        id: map['id'] as String? ?? 'slot_${DateTime.now().millisecondsSinceEpoch}',
        title: map['title'] as String? ?? 'فترة طريق',
        hour: (map['hour'] as num?)?.toInt() ?? 8,
        minute: (map['minute'] as num?)?.toInt() ?? 0,
        targetPages: (map['target_pages'] as num?)?.toInt() ?? 3,
      );
}

class CommuteWirdSettingsView extends StatefulWidget {
  const CommuteWirdSettingsView({super.key});

  @override
  State<CommuteWirdSettingsView> createState() => _CommuteWirdSettingsViewState();
}

class _CommuteWirdSettingsViewState extends State<CommuteWirdSettingsView> {
  bool _isLoading = true;
  bool _enabled = true;
  bool _countTowardsMain = true;
  List<int> _activeDays = [1, 2, 3, 4, 5]; // Sun-Thu by default
  List<CommuteSlot> _slots = [
    CommuteSlot(id: 'morning', title: 'طريق الذهاب (صباحاً)', hour: 7, minute: 30, targetPages: 3),
    CommuteSlot(id: 'evening', title: 'طريق العودة (مساءً)', hour: 17, minute: 0, targetPages: 3),
  ];
  CommuteWirdState? _state;

  final Map<int, String> _dayNames = {
    1: 'الأحد',
    2: 'الإثنين',
    3: 'الثلاثاء',
    4: 'الأربعاء',
    5: 'الخميس',
    6: 'الجمعة',
    7: 'السبت',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final repo = CommuteWirdRepository();
    final st = await repo.getState();
    _state = st;

    final reminder = await NativeRemindersBridge.getReminder('wird_commute');
    if (reminder != null) {
      _enabled = reminder['enabled'] == 1;
      try {
        final schedule = jsonDecode(reminder['schedule_json'] as String) as Map<String, dynamic>;
        _countTowardsMain = (schedule['count_towards_main'] as bool?) ?? true;
        if (schedule['days'] is List) {
          _activeDays = (schedule['days'] as List).map((e) => (e as num).toInt()).toList();
        }
        if (schedule['slots'] is List) {
          _slots = (schedule['slots'] as List)
              .map((e) => CommuteSlot.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {}
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    // Primary slot time for backward compat
    final primarySlot = _slots.isNotEmpty ? _slots.first : CommuteSlot(id: 'morning', title: 'الصباح', hour: 7, minute: 30, targetPages: 3);

    final scheduleMap = {
      'hour': primarySlot.hour,
      'minute': primarySlot.minute,
      'target_pages': primarySlot.targetPages,
      'days': _activeDays,
      'slots': _slots.map((s) => s.toMap()).toList(),
      'count_towards_main': _countTowardsMain,
      'last_page': _state?.currentPage ?? 1,
    };

    final payloadMap = {
      'title': 'ورد المواصلات',
      'body': 'استثمر طريقك في تلاوة القرآن الكريم',
    };

    final item = {
      'id': 'wird_commute',
      'type': 'wird_commute',
      'schedule_json': jsonEncode(scheduleMap),
      'payload_json': jsonEncode(payloadMap),
      'enabled': _enabled ? 1 : 0,
      'last_triggered': 0,
    };

    await NativeRemindersBridge.saveReminder(item);

    if (mounted) {
      AppSnackbar.show(
        'تم الحفظ',
        'تم تحديث مواعيد ورد المواصلات وجدولتها بنجاح',
        context: context,
      );
    }
  }

  void _addSlot() {
    setState(() {
      _slots.add(
        CommuteSlot(
          id: 'slot_${DateTime.now().millisecondsSinceEpoch}',
          title: 'فترة إضافية',
          hour: 14,
          minute: 0,
          targetPages: 2,
        ),
      );
    });
  }

  Future<void> _editSlotTime(CommuteSlot slot) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: slot.hour, minute: slot.minute),
    );
    if (picked != null) {
      setState(() {
        slot.hour = picked.hour;
        slot.minute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = const Color(0xFF1B4D3E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ورد المواصلات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : MaxWidthContainer(
              child: ListView(
                padding: const EdgeInsets.all(16),
              children: [
                // Streak & Progress Card
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
                              const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 24),
                              const SizedBox(width: 4),
                              Text(
                                '${_state?.streak ?? 0}',
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
                            'صـ ${_state?.currentPage ?? 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: isDark ? const Color(0xFF81C784) : primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('الموضع الحالي للورد', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Enable Switch
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: const Text('تفعيل تذكير ورد المواصلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('فتح المصحف تلقائياً على آخر صفحة بوضع مواصلات مريح'),
                    value: _enabled,
                    activeColor: primary,
                    onChanged: (val) {
                      setState(() => _enabled = val);
                      _saveSettings();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Count Towards Main Option
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: const Text('احتسبه من الورد الأساسي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: const Text('عند إتمام قراءة صفحات المواصلات، تُضاف تلقائياً لتقدم وردك وسجل القراءة اليومي'),
                    value: _countTowardsMain,
                    activeColor: primary,
                    onChanged: (val) => setState(() => _countTowardsMain = val),
                  ),
                ),

                const SizedBox(height: 16),

                // Days Selection Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('أيام التذكير الأسبوعية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _dayNames.entries.map((entry) {
                            final isSel = _activeDays.contains(entry.key);
                            return FilterChip(
                              label: Text(entry.value),
                              selected: isSel,
                              selectedColor: primary.withOpacity(0.2),
                              checkmarkColor: primary,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _activeDays.add(entry.key);
                                  } else {
                                    if (_activeDays.length > 1) {
                                      _activeDays.remove(entry.key);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Slots / Multi-time Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const Text(
                              'مواعيد وفترات الطريق اليومية',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.standard,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'إضافة موعد',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: _addSlot,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ..._slots.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final slot = entry.value;
                          final period = slot.hour >= 12 ? 'م' : 'ص';
                          final displayH = slot.hour > 12 ? slot.hour - 12 : (slot.hour == 0 ? 12 : slot.hour);
                          final timeStr = '$displayH:${slot.minute.toString().padLeft(2, '0')} $period';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2622) : const Color(0xFFF6F9F7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: slot.title,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        onChanged: (val) => slot.title = val,
                                      ),
                                    ),
                                    if (_slots.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        onPressed: () => setState(() => _slots.removeAt(idx)),
                                      ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.access_time_rounded, size: 16),
                                      label: Text(timeStr),
                                      onPressed: () => _editSlotTime(slot),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('الهدف: ', style: TextStyle(fontSize: 13)),
                                        DropdownButton<int>(
                                          value: slot.targetPages,
                                          underline: const SizedBox(),
                                          items: [1, 2, 3, 4, 5, 6, 8, 10]
                                              .map((p) => DropdownMenuItem(value: p, child: Text('$p صفحات')))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) setState(() => slot.targetPages = val);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
                  label: const Text('حفظ الإعدادات وجدولة المواعيد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: _saveSettings,
                ),

                const SizedBox(height: 12),

                // Test Trigger & Open Mushaf Commute Mode
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('فتح المصحف الآن في "وضع المواصلات"'),
                  onPressed: () {
                    final primarySlot = _slots.isNotEmpty
                        ? _slots.first
                        : CommuteSlot(id: 'morning', title: 'الصباح', hour: 7, minute: 30, targetPages: 3);
                    Get.toNamed('/mushaf', arguments: {
                      'commute_mode': true,
                      'page': _state?.currentPage ?? 1,
                      'target_pages': primarySlot.targetPages,
                      'slot_id': primarySlot.id,
                      'count_towards_main': _countTowardsMain,
                    })?.then((_) => _loadSettings());
                  },
                ),
              ],
            ),
          ),
    );
  }
}
