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
    'quranic': 'أدعية قرآنية مباركة',
    'prophetic': 'أدعية نبوية مأثورة',
    'tasbeeh': 'تسابيح وتحميد وتهليل',
    'istighfar': 'استغفار وتوبة وذكر',
    'general': 'أذكار وأدعية عامة وشاملة',
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
      title: 'الأذكار الدورية',
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Banner Card with 3D Tasbeeh Icon
                  _buildHeaderBanner(colors),

                  AppSpacing.verticalMd,

                  // 2. Master Switch Card
                  _buildMasterToggleCard(colors),

                  AppSpacing.verticalLg,

                  // 3. Interval Section
                  _buildSectionHeader('الفترة الزمنية بين الأذكار', Icons.timelapse_rounded, colors),
                  AppSpacing.verticalSm,
                  _buildIntervalCard(colors),

                  AppSpacing.verticalLg,

                  // 4. Active Hours Section
                  _buildSectionHeader('ساعات التشغيل (أوقات النشاط)', Icons.nightlight_round, colors),
                  AppSpacing.verticalSm,
                  _buildActiveHoursCard(colors),

                  AppSpacing.verticalLg,

                  // 5. Quiet Window Around Prayer Times
                  _buildSectionHeader('مراعاة أوقات الصلاة', Icons.mosque_rounded, colors),
                  AppSpacing.verticalSm,
                  _buildQuietPrayerCard(colors),

                  AppSpacing.verticalLg,

                  // 6. Category Selection
                  _buildSectionHeader('فئات الأذكار المختارة', Icons.category_rounded, colors),
                  AppSpacing.verticalSm,
                  _buildCategoriesCard(colors),

                  AppSpacing.verticalLg,

                  // 7. Sound & Vibration Section
                  _buildSectionHeader('الصوت والاهتزاز', Icons.volume_up_rounded, colors),
                  AppSpacing.verticalSm,
                  _buildSoundAndVibrationCard(colors),

                  AppSpacing.verticalXl,

                  // 8. Test Notification Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      icon: Icon(
                        Icons.play_circle_outline_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      label: Text(
                        'إرسال إشعار ذكر تجريبي الآن',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      onPressed: () async {
                        await NativeAzkarBridge.testNotification();
                        defaultToast(text: 'تم إرسال إشعار الذكر التجريبي');
                      },
                    ),
                  ),

                  AppSpacing.verticalXxl,
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, dynamic colors) {
    return Row(
      children: [
        Icon(icon, size: 17, color: colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBanner(dynamic colors) {
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
          // 3D Tasbeeh Icon
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: AppRadius.borderMd,
            ),
            child: Image.asset(
              'assets/images/icon_3d_tasbeeh.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.auto_awesome_rounded,
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
                  'رطّب لسانك بذكر الله',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'تنبيهات عطرية بأحاديث وأذكار نبوية وتسابيح موزعة بذكاء على مدار يومك',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.5,
                    color: colors.textMuted,
                    height: 1.35,
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
    return AppCard(
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
              size: 22,
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                AppSpacing.verticalXs,
                Text(
                  'تذكير مستمر بذكر الله واستغفاره في الخلفية',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.5,
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
    );
  }

  Widget _buildIntervalCard(dynamic colors) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildIntervalChip('١٥ دقيقة', 15),
              _buildIntervalChip('٣٠ دقيقة', 30),
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
                    size: 20,
                  ),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      'تنبيه: الفترات القصيرة جداً (أقل من ١٥ دقيقة) قد تزيد من استهلاك البطارية.',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
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
    );
  }

  Widget _buildActiveHoursCard(dynamic colors) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => _pickTime(isFrom: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'من الساعة',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      _formatTimeOfDay(_fromTime),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 15,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إلى الساعة',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      _formatTimeOfDay(_toTime),
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 15,
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
    );
  }

  Widget _buildQuietPrayerCard(dynamic colors) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
          'كتم التنبيهات تلقائياً خلال ±١٠ دقائق حول مواعيد الأذان والصلوات المفروضة منعاً لأي تشويش',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 11.5,
            color: colors.textMuted,
          ),
        ),
        onChanged: (val) {
          setState(() => _quietPrayerWindow = val);
          _saveSettings();
        },
      ),
    );
  }

  Widget _buildCategoriesCard(dynamic colors) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: _allCategories.entries.map((entry) {
          final isSelected = _selectedCategories.contains(entry.key);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  if (_selectedCategories.length > 1) {
                    _selectedCategories.remove(entry.key);
                  } else {
                    defaultToast(text: 'يجب اختيار فئة واحدة على الأقل');
                  }
                } else {
                  _selectedCategories.add(entry.key);
                }
              });
              _saveSettings();
            },
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: isSelected ? colors.primary : colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colors.text : colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundAndVibrationCard(dynamic colors) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
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
                fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildIntervalChip(String label, int minutes) {
    final colors = context.appColors;
    final isSelected = _intervalMinutes == minutes;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: colors.surface,
      selectedColor: colors.primary.withOpacity(0.18),
      side: BorderSide(
        color: isSelected ? colors.primary : colors.divider,
        width: isSelected ? 1.4 : 0.8,
      ),
      labelStyle: TextStyle(
        fontFamily: AppTypography.uiFont,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colors.primary : colors.text,
        fontSize: 12,
      ),
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
        size: 15,
        color: isCustom ? colors.primary : colors.textMuted,
      ),
      label: Text(
        isCustom
            ? 'مخصص: ${toArabicDigits(_intervalMinutes)} دقيقة'
            : 'تخصيص...',
      ),
      labelStyle: TextStyle(
        fontFamily: AppTypography.uiFont,
        color: isCustom ? colors.primary : colors.text,
        fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: isCustom ? colors.primary.withOpacity(0.18) : colors.surface,
      side: BorderSide(
        color: isCustom ? colors.primary : colors.divider,
        width: isCustom ? 1.4 : 0.8,
      ),
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
        backgroundColor: colors.surface,
        title: Text(
          'حدد الفترة المخصصة (بالدقائق)',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: colors.text,
          ),
        ),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 15,
            color: colors.text,
          ),
          decoration: InputDecoration(
            hintText: 'مثلاً: 45',
            hintStyle: TextStyle(color: colors.textMuted),
            suffixText: 'دقيقة',
            suffixStyle: TextStyle(
              fontFamily: AppTypography.uiFont,
              color: colors.textMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                color: colors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
            ),
            onPressed: () {
              final val = int.tryParse(textController.text.trim());
              if (val != null && val >= 5 && val <= 720) {
                Navigator.pop(ctx, val);
              } else {
                defaultToast(text: 'يرجى إدخال مدة بين 5 و 720 دقيقة');
              }
            },
            child: Text(
              'حفظ',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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
