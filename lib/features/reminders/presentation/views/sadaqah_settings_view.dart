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
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
        'تم تحديث إعدادات تذكير الصدقة وإعادة جدولتها بنجاح',
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
          'تذكير الصدقة الشهرية',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.text),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: colors.primary),
            tooltip: 'سجل الصدقات',
            onPressed: () => Get.toNamed('/sadaqahLogs'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : MaxWidthContainer(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                children: [
                  // 1. Hadith & Motivation Card
                  _buildHadithCard(colors),

                  const SizedBox(height: 14),

                  // 2. Master Enable Card
                  _buildMasterToggleCard(colors),

                  const SizedBox(height: 14),

                  // 3. Calendar Type Selection Card
                  _buildCalendarSelectionCard(colors),

                  const SizedBox(height: 14),

                  // 4. Day of Month Selection Card
                  _buildDayTypeSelectionCard(colors),

                  const SizedBox(height: 14),

                  // 5. Time & Second Reminder Card
                  _buildTimeAndFollowupCard(colors),

                  const SizedBox(height: 14),

                  // 6. Sadaqah Logs Quick Link Card
                  _buildSadaqahLogsCard(colors),

                  const SizedBox(height: 22),

                  // 7. Save Button
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

                  // 8. Test Trigger Button
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
                        'تجربة إشعار الصدقة وزر "تصدّقت" الآن',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      onPressed: () async {
                        await NativeRemindersBridge.testTriggerReminder('sadaqah_monthly');
                        if (context.mounted) {
                          AppSnackbar.show(
                            'تم إرسال الإشعار',
                            'تفقّد لوحة الإشعارات واضغط على زر "تصدّقت" لتجربة التسجيل المباشر',
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

  Widget _buildHadithCard(dynamic colors) {
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
          // 3D Praying Hands Icon
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: AppRadius.borderMd,
            ),
            child: Image.asset(
              'assets/images/icon_3d_praying_hands.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.volunteer_activism_rounded,
                color: colors.primary,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قال رسول الله ﷺ:',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '«مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ، وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلَّا عِزًّا»',
                  style: TextStyle(
                    fontFamily: AppTypography.quranFont,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'رواه مسلم',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11,
                    color: colors.textMuted,
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
            child: Icon(Icons.volunteer_activism_rounded, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تفعيل تذكير الصدقة الشهرية',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'إشعار شهري ذكي مع أحاديث نبوية وزر "تصدّقت" لتسجيلها فوراً',
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

  Widget _buildCalendarSelectionCard(dynamic colors) {
    final isHijri = _calendar == 'hijri';

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
              Icon(Icons.calendar_month_rounded, size: 17, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'نوع التقويم المعتمد',
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
          Row(
            children: [
              Expanded(
                child: _buildCalendarOptionPill(
                  title: 'التقويم الهجري',
                  subtitle: 'حسب الأهلة والأشهر الهجرية',
                  isSelected: isHijri,
                  onTap: () => setState(() => _calendar = 'hijri'),
                  colors: colors,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCalendarOptionPill(
                  title: 'التقويم الميلادي',
                  subtitle: 'مناسب لمواعيد الرواتب',
                  isSelected: !isHijri,
                  onTap: () => setState(() => _calendar = 'gregorian'),
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarOptionPill({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.12) : colors.bg,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 16,
                  color: isSelected ? colors.primary : colors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colors.primary : colors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(right: 22.0),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 10.5,
                  color: colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTypeSelectionCard(dynamic colors) {
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
              Icon(Icons.event_repeat_rounded, size: 17, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'موعد التذكير في الشهر',
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

          // Option 1: Fixed day of month
          _buildDayTypeTile(
            value: 'day_of_month',
            title: 'يوم محدد من الشهر (يوم ${toArabicDigits(_dayOfMonth)})',
            subtitle: 'إذا كان الشهر أقصر، يتم التذكير تلقائياً في اليوم الأخير',
            colors: colors,
          ),

          if (_dayType == 'day_of_month') ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Text(
                    'اليوم: ',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colors.textMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      toArabicDigits(_dayOfMonth),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _dayOfMonth.toDouble(),
                      min: 1,
                      max: 31,
                      divisions: 30,
                      activeColor: colors.primary,
                      inactiveColor: colors.divider,
                      label: toArabicDigits(_dayOfMonth),
                      onChanged: (val) => setState(() => _dayOfMonth = val.toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 12),

          // Option 2: Last working day
          _buildDayTypeTile(
            value: 'last_working_day',
            title: 'آخر يوم عمل في الشهر',
            subtitle: 'آخر يوم عمل رسمي (الأحد إلى الخميس) تزامناً مع نزول الراتب',
            colors: colors,
          ),

          const Divider(height: 12),

          // Option 3: Last Thursday
          _buildDayTypeTile(
            value: 'last_thursday',
            title: 'آخر خميس في الشهر',
            subtitle: 'يوم الخميس الأخير من الشهر تزامناً مع فضل الصيام وختام الأسبوع',
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildDayTypeTile({
    required String value,
    required String title,
    required String subtitle,
    required dynamic colors,
  }) {
    final isSelected = _dayType == value;

    return InkWell(
      onTap: () => setState(() => _dayType = value),
      borderRadius: AppRadius.borderSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 18,
                color: isSelected ? colors.primary : colors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13.5,
                      color: isSelected ? colors.primary : colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAndFollowupCard(dynamic colors) {
    final timeStr = _formatReminderTime(_reminderTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.access_time_rounded, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وقت التذكير في اليوم',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
          const Divider(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_outlined, color: colors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تذكير متابعة ثانٍ بعد ٤٨ ساعة',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'إشعار تذكيري لطيف بعد يومين إذا لم تسجل الصدقة في التذكير الأول',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: _secondReminder,
                activeColor: colors.primary,
                onChanged: (val) => setState(() => _secondReminder = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSadaqahLogsCard(dynamic colors) {
    return InkWell(
      onTap: () => Get.toNamed('/sadaqahLogs'),
      borderRadius: AppRadius.borderLg,
      child: Container(
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
              child: Icon(Icons.history_edu_rounded, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سجل وتاريخ الصدقات المسجلة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'استعرض كافة الصدقات التي قمت بتسجيلها وتتبع بركتها الشهرية',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
