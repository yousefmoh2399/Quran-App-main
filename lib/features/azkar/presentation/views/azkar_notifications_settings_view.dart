import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/native/native_azkar_bridge.dart';
import 'package:quran_app_android/core/util/widgets/custom_toast.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

class AzkarNotificationsSettingsView extends StatefulWidget {
  const AzkarNotificationsSettingsView({super.key});

  @override
  State<AzkarNotificationsSettingsView> createState() =>
      _AzkarNotificationsSettingsViewState();
}

class _AzkarNotificationsSettingsViewState
    extends State<AzkarNotificationsSettingsView> {
  bool _isLoading = true;
  bool _enabled = true;
  int _intervalMinutes = 60;
  TimeOfDay _fromTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 22, minute: 0);
  bool _quietPrayerWindow = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  final Set<String> _selectedCategories = {
    'morning_evening',
    'quranic',
    'prophetic',
    'tasbeeh',
    'istighfar',
    'general'
  };

  final Map<String, String> _allCategories = {
    'morning_evening': 'أذكار الصباح والمساء',
    'quranic': 'أدعية قرآنية',
    'prophetic': 'أدعية نبوية مأثورة',
    'tasbeeh': 'تسابيح وتحميد وتهليل',
    'istighfar': 'استغفار وتوبة',
    'general': 'أذكار وأدعية عامة',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await NativeAzkarBridge.getSettings();
    if (data != null && mounted) {
      setState(() {
        _enabled = data['enabled'] as bool? ?? true;
        _intervalMinutes = data['interval'] as int? ?? 60;
        _fromTime = TimeOfDay(
          hour: data['fromHour'] as int? ?? 8,
          minute: data['fromMin'] as int? ?? 0,
        );
        _toTime = TimeOfDay(
          hour: data['toHour'] as int? ?? 22,
          minute: data['toMin'] as int? ?? 0,
        );
        _quietPrayerWindow = data['quietPrayer'] as bool? ?? true;
        _soundEnabled = data['sound'] as bool? ?? true;
        _vibrationEnabled = data['vibration'] as bool? ?? true;

        final rawList = data['categories'] as List?;
        if (rawList != null && rawList.isNotEmpty) {
          _selectedCategories.clear();
          _selectedCategories.addAll(rawList.map((e) => e.toString()));
        }
      });
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final map = {
      'enabled': _enabled,
      'interval': _intervalMinutes,
      'fromHour': _fromTime.hour,
      'fromMin': _fromTime.minute,
      'toHour': _toTime.hour,
      'toMin': _toTime.minute,
      'quietPrayer': _quietPrayerWindow,
      'categories': _selectedCategories.toList(),
      'sound': _soundEnabled,
      'vibration': _vibrationEnabled,
    };

    final ok = await NativeAzkarBridge.saveSettings(map);
    if (ok) {
      defaultToast(text: 'تم حفظ إعدادات تنبيهات الأذكار بنجاح');
    } else {
      defaultToast(text: 'حدث خطأ أثناء حفظ الإعدادات');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      title: 'إعدادات تنبيهات الأذكار',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Master switch card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: colors.primary,
                            size: 26,
                          ),
                        ),
                        AppSpacing.horizontalMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفعيل تنبيهات الأذكار الدورية',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.text,
                                ),
                              ),
                              AppSpacing.verticalXs,
                              Text(
                                'تذكير مستمر بذكر الله واستغفاره في الخلفية',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                  ),

                  AppSpacing.verticalLg,

                  // Interval Section
                  Text(
                    'الفترة الزمنية بين الأذكار',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _buildIntervalChip('15 دقيقة', 15),
                            _buildIntervalChip('30 دقيقة', 30),
                            _buildIntervalChip('ساعة', 60),
                            _buildIntervalChip('ساعتين', 120),
                            _buildCustomIntervalChip(),
                          ],
                        ),

                        // Battery Warning banner if interval < 15 mins
                        if (_intervalMinutes < 15) ...[
                          AppSpacing.verticalMd,
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: colors.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: colors.accent.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.battery_alert_rounded,
                                  color: colors.accent,
                                  size: 22,
                                ),
                                AppSpacing.horizontalSm,
                                Expanded(
                                  child: Text(
                                    'تنبيه: الفترات القصيرة جدًا (أقل من 15 دقيقة) تزيد من استهلاك البطارية.',
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 12,
                                      color: colors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  AppSpacing.verticalLg,

                  // Active Hours Section (ساعات التشغيل)
                  Text(
                    'ساعات التشغيل (عدم الإزعاج أثناء النوم)',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () => _pickTime(isFrom: true),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.6),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'من الساعة',
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 12,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                  AppSpacing.verticalXs,
                                  Text(
                                    _formatTimeOfDay(_fromTime),
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.horizontalMd,
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () => _pickTime(isFrom: false),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.6),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إلى الساعة',
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 12,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                  AppSpacing.verticalXs,
                                  Text(
                                    _formatTimeOfDay(_toTime),
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.verticalLg,

                  // Quiet Window Around Prayer Times
                  Text(
                    'مراعاة أوقات الصلاة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _quietPrayerWindow,
                      activeColor: colors.primary,
                      title: Text(
                        'تعطيل التنبيهات وقت الصلاة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      subtitle: Text(
                        'كتم التنبيهات تلقائيًا خلال ±10 دقائق حول مواعيد الأذان والصلوات المفروضة منعًا لأي تشويش',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _quietPrayerWindow = val);
                        _saveSettings();
                      },
                    ),
                  ),

                  AppSpacing.verticalLg,

                  // Category Selection
                  Text(
                    'فئات الأذكار المختارة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: _allCategories.entries.map((entry) {
                        final isSelected =
                            _selectedCategories.contains(entry.key);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.value,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 14,
                              color: colors.text,
                            ),
                          ),
                          activeColor: colors.primary,
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedCategories.add(entry.key);
                              } else {
                                if (_selectedCategories.length > 1) {
                                  _selectedCategories.remove(entry.key);
                                } else {
                                  defaultToast(
                                    text: 'يجب اختيار فئة واحدة على الأقل',
                                  );
                                }
                              }
                            });
                            _saveSettings();
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  AppSpacing.verticalLg,

                  // Sound & Vibration Section
                  Text(
                    'الصوت والاهتزاز',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _soundEnabled,
                          activeColor: colors.primary,
                          title: Text(
                            'تشغيل صوت الإشعار',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 14,
                              color: colors.text,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() => _soundEnabled = val);
                            _saveSettings();
                          },
                        ),
                        Divider(height: 1, color: colors.divider),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _vibrationEnabled,
                          activeColor: colors.primary,
                          title: Text(
                            'تفعيل الاهتزاز',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 14,
                              color: colors.text,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() => _vibrationEnabled = val);
                            _saveSettings();
                          },
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.verticalXl,

                  // Test Notification Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      side: BorderSide(color: colors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: Icon(
                      Icons.play_circle_outline_rounded,
                      color: colors.primary,
                    ),
                    label: Text(
                      'إرسال إشعار تجريبي الآن',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    onPressed: () async {
                      await NativeAzkarBridge.testNotification();
                      defaultToast(text: 'تم إرسال إشعار الذكر التجريبي');
                    },
                  ),

                  AppSpacing.verticalXxl,
                ],
              ),
            ),
    );
  }

  Widget _buildIntervalChip(String label, int minutes) {
    final colors = context.appColors;
    final isSelected = _intervalMinutes == minutes;

    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontFamily: AppTypography.uiFont,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : colors.text,
      ),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: colors.surface.withOpacity(0.8),
      onSelected: (selected) {
        if (selected) {
          setState(() => _intervalMinutes = minutes);
          _saveSettings();
        }
      },
    );
  }

  Widget _buildCustomIntervalChip() {
    final colors = context.appColors;
    final isCustom = ![15, 30, 60, 120].contains(_intervalMinutes);

    return ActionChip(
      avatar: Icon(
        Icons.edit_outlined,
        size: 16,
        color: isCustom ? Colors.white : colors.text,
      ),
      label: Text(
        isCustom
            ? 'مخصص: ${toArabicDigits(_intervalMinutes)} دقيقة'
            : 'تخصيص...',
      ),
      labelStyle: TextStyle(
        fontFamily: AppTypography.uiFont,
        color: isCustom ? Colors.white : colors.text,
        fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor:
          isCustom ? colors.primary : colors.surface.withOpacity(0.8),
      onPressed: _showCustomIntervalDialog,
    );
  }

  Future<void> _showCustomIntervalDialog() async {
    final textController =
        TextEditingController(text: _intervalMinutes.toString());
    final colors = context.appColors;

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حدد الفترة المخصصة (بالدقائق)'),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'مثلاً: 45',
            suffixText: 'دقيقة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
            onPressed: () {
              final val = int.tryParse(textController.text.trim());
              if (val != null && val >= 5 && val <= 720) {
                Navigator.pop(ctx, val);
              } else {
                defaultToast(text: 'يرجى إدخال مدة بين 5 و 720 دقيقة');
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() => _intervalMinutes = selected);
      _saveSettings();
    }
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final initial = isFrom ? _fromTime : _toTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
      _saveSettings();
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteTens = time.minute ~/ 10;
    final minuteUnits = time.minute % 10;
    return '${toArabicDigits(hour)}:${toArabicDigits(minuteTens)}${toArabicDigits(minuteUnits)} $period';
  }
}
