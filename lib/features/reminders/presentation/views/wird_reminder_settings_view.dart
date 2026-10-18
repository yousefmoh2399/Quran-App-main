import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/models/user_models.dart';
import 'package:quran_app_android/core/data/repositories/user_repository.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/responsive.dart';
import 'package:quran_app_android/core/native/native_reminders_bridge.dart';
import 'package:quran_app_android/core/util/app_snackbar.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

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
      // Default template for display; persistent save occurs when user presses save
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
    }
    if (mounted) {
      setState(() => _isLoading = false);
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

  Future<void> _saveSettings() async {
    if (_plan == null) return;
    final timeStr =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
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

    if (Get.isRegistered<HomeViewModel>()) {
      Get.find<HomeViewModel>().loadUserQuranData();
    }

    if (mounted) {
      AppSnackbar.show(
        'تم الحفظ',
        'تم تحديث موعد تذكير الورد القرآني وجدولته بنجاح',
        context: context,
      );
    }
  }

  String _formatReminderTime(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteTens = time.minute ~/ 10;
    final minuteUnits = time.minute % 10;
    return '${toArabicDigits(hour)}:${toArabicDigits(minuteTens)}${toArabicDigits(minuteUnits)} $period';
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
          'تذكير الورد اليومي',
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
                  // 1. Streak & Target Pages Header Card
                  _buildHeaderCard(colors),

                  const SizedBox(height: 14),

                  // 2. Master Enable Card
                  _buildMasterToggleCard(colors),

                  const SizedBox(height: 14),

                  // 3. Time Selection Card
                  _buildTimeCard(colors),

                  const SizedBox(height: 14),

                  // 4. Smart Cancellation Info Banner
                  _buildSmartCancellationBadge(colors),

                  const SizedBox(height: 22),

                  // 5. Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'حفظ التفضيلات وجدولة التذكير',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),
                      onPressed: _saveSettings,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 6. Test Trigger Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      ),
                      icon: const Icon(Icons.notification_important_rounded, size: 20),
                      label: const Text(
                        'تجربة إشعار الورد اليومي الآن',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      onPressed: () async {
                        await NativeRemindersBridge.testTriggerReminder('wird_daily');
                        if (context.mounted) {
                          AppSnackbar.show(
                            'تم إرسال الإشعار',
                            'تفقّد لوحة الإشعارات واضغط عليه للفتح المباشر على المصحف',
                            context: context,
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(dynamic colors) {
    final streak = _plan?.streak ?? 0;
    final startP = _plan?.startPage ?? 1;
    final endP = _plan?.endPage ?? 10;

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
          // 3D Quran Icon
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: AppRadius.borderMd,
            ),
            child: Image.asset(
              'assets/images/icon_3d_quran.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.menu_book_rounded,
                color: colors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Statistics
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
                                'صـ ${toArabicDigits(startP)} - ${toArabicDigits(endP)}',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                          'ورد اليوم المستهدف',
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
                  'تفعيل تذكير الورد اليومي',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'إشعار يومي منتظم يذكّرك بوردك القرآني وتلاوته',
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

  Widget _buildTimeCard(dynamic colors) {
    final timeStr = _formatReminderTime(_reminderTime);

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
            child: Icon(Icons.access_time_rounded, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وقت التذكير اليومي',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary.withOpacity(0.12),
              foregroundColor: colors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
            ),
            onPressed: _pickTime,
            child: const Text(
              'تغيير',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartCancellationBadge(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.08),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: colors.primary.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'إلغاء ذكي تلقائي: إذا أتممت قراءة وردك القرآني اليومي عبر التطبيق قبل حلول موعد الإشعار، يتم إلغاء التنبيه تلقائياً لذلك اليوم لمنع أي إزعاج.',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12,
                color: colors.text,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
