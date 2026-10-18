import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/responsive.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';
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

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final primarySlot = _slots.isNotEmpty
        ? _slots.first
        : CommuteSlot(id: 'morning', title: 'الصباح', hour: 7, minute: 30, targetPages: 3);

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

  String _formatSlotTime(int hour, int minute) {
    final period = hour >= 12 ? 'م' : 'ص';
    final displayH = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteTens = minute ~/ 10;
    final minuteUnits = minute % 10;
    return '${toArabicDigits(displayH)}:${toArabicDigits(minuteTens)}${toArabicDigits(minuteUnits)} $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'ورد المواصلات',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : MaxWidthContainer(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                children: [
                  // 1. Streak & Progress Banner Card
                  _buildHeaderCard(colors),

                  const SizedBox(height: 14),

                  // 2. Master Enable Card
                  _buildMasterToggleCard(colors),

                  const SizedBox(height: 12),

                  // 3. Count Towards Main Wird Card
                  _buildCountTowardsMainCard(colors),

                  const SizedBox(height: 14),

                  // 4. Days Selection Card
                  _buildDaysSelectionCard(colors),

                  const SizedBox(height: 14),

                  // 5. Commute Slots List Card
                  _buildSlotsCard(colors),

                  const SizedBox(height: 20),

                  // 6. Primary Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      ),
                      onPressed: _saveSettings,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Text(
                                'حفظ المواعيد والجدولة',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 7. Open Mushaf in Commute Mode Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      ),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Text(
                                'فتح المصحف الآن في "وضع المواصلات"',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(dynamic colors) {
    final streak = _state?.streak ?? 0;
    final page = _state?.currentPage ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.primary.withOpacity(0.22), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Travel Icon
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: AppRadius.borderMd,
            ),
            child: Image.asset(
              'assets/images/icon_3d_travel.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.directions_bus_rounded,
                color: colors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Progress statistics
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 3),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                toArabicDigits(streak),
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: colors.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'أيام متتالية',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: colors.divider),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, color: colors.primary, size: 17),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'صـ ${toArabicDigits(page)}',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: colors.text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'الموضع الحالي للورد',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggleCard(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_rounded, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفعيل تذكير ورد المواصلات',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'فتح المصحف تلقائياً على موضعك في أوقات الطريق المحددة',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.5,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: _enabled,
            activeColor: colors.primary,
            onChanged: (val) {
              setState(() => _enabled = val);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountTowardsMainCard(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.track_changes_rounded, color: colors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'احتسابه ضمن الورد الأساسي',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'إضافة صفحات قراءة المواصلات تلقائياً لتقدمك اليومي',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.5,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: _countTowardsMain,
            activeColor: colors.primary,
            onChanged: (val) => setState(() => _countTowardsMain = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelectionCard(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 17, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أيام التذكير الأسبوعية',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: colors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _dayNames.entries.map((entry) {
              final isSel = _activeDays.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: isSel,
                showCheckmark: false,
                backgroundColor: colors.surface,
                selectedColor: colors.primary.withOpacity(0.18),
                side: BorderSide(
                  color: isSel ? colors.primary : colors.divider,
                  width: isSel ? 1.4 : 0.8,
                ),
                labelStyle: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? colors.primary : colors.text,
                ),
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
    );
  }

  Widget _buildSlotsCard(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 17, color: colors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'مواعيد وفترات الطريق اليومية',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: colors.text,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary.withOpacity(0.12),
                  foregroundColor: colors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'إضافة فترة',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                onPressed: _addSlot,
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._slots.asMap().entries.map((entry) {
            final idx = entry.key;
            final slot = entry.value;
            final timeStr = _formatSlotTime(slot.hour, slot.minute);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: slot.title,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'اسم الفترة (مثال: طريق الذهاب)',
                            hintStyle: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 14,
                              color: colors.textMuted,
                            ),
                          ),
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: colors.text,
                          ),
                          onChanged: (val) => slot.title = val,
                        ),
                      ),
                      if (_slots.length > 1)
                        InkWell(
                          onTap: () => setState(() => _slots.removeAt(idx)),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.delete_outline_rounded, color: colors.error, size: 18),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 14),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InkWell(
                        onTap: () => _editSlotTime(slot),
                        borderRadius: AppRadius.borderSm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: AppRadius.borderSm,
                            border: Border.all(color: colors.primary.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, size: 15, color: colors.primary),
                              const SizedBox(width: 6),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: colors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'الهدف: ',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 12.5,
                              color: colors.textMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: AppRadius.borderSm,
                              border: Border.all(color: colors.divider),
                            ),
                            child: DropdownButton<int>(
                              value: slot.targetPages,
                              underline: const SizedBox(),
                              isDense: true,
                              dropdownColor: colors.surface,
                              icon: Icon(Icons.arrow_drop_down_rounded, color: colors.primary),
                              items: [1, 2, 3, 4, 5, 6, 8, 10]
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          '${toArabicDigits(p)} صفحات',
                                          style: TextStyle(
                                            fontFamily: AppTypography.uiFont,
                                            fontSize: 12,
                                            color: colors.text,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => slot.targetPages = val);
                              },
                            ),
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
    );
  }
}
