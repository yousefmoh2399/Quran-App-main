import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/native/native_azkar_bridge.dart';
import 'package:quran_app_android/core/service/settings/notifications_services.dart';
import 'package:quran_app_android/core/util/widgets/custom_toast.dart';
import 'package:quran_app_android/features/settings/presentation/view_model/settins_view_model.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/settings_group_card.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/settings_tile.dart';

class SectionAzkarNotification extends StatefulWidget {
  final SettingsViewModel controller;

  const SectionAzkarNotification({
    super.key,
    required this.controller,
  });

  @override
  State<SectionAzkarNotification> createState() =>
      _SectionAzkarNotificationState();
}

class _SectionAzkarNotificationState extends State<SectionAzkarNotification> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = widget.controller;
    final isMorningEnabled =
        controller.settingsServices.sharedPref!.getBool('enable') ?? true;
    final isPeriodicEnabled =
        controller.settingsServices.sharedPref!.getBool('stop_noti') ?? true;

    final formattedMorningTime = controller.timeOfDay != null
        ? controller.timeOfDay!.format(context)
        : '٠٨:٠٠ ص (افتراضي)';

    return SettingsGroupCard(
      title: 'تنبيهات الأذكار والأوراد',
      icon: Icons.notifications_active_outlined,
      children: [
        // Morning Azkar Switch
        SettingsTile(
          icon: Icons.wb_sunny_outlined,
          title: 'إشعار أذكار الصباح',
          subtitle: 'تذكير يومي لقراءة أذكار الصباح والمساء',
          trailing: Switch.adaptive(
            value: isMorningEnabled,
            activeColor: colors.primary,
            activeTrackColor: colors.primary.withOpacity(0.5),
            onChanged: (value) async {
              await _toggleMorningSwitch(controller, value);
              setState(() {});
            },
          ),
        ),

        // Morning Azkar Time Picker Row
        SettingsTile(
          icon: Icons.access_time_rounded,
          title: 'توقيت أذكار الصباح',
          subtitle: formattedMorningTime,
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'تعديل',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
          onTap: () async {
            await _showMorningTimePicker(context, controller);
            setState(() {});
          },
        ),

        // Periodic Azkar Reminder Switch
        SettingsTile(
          icon: Icons.repeat_rounded,
          title: 'التنبيهات الدورية للأذكار',
          subtitle: 'تذكير بأذكار واستغفار متفرقة خلال اليوم',
          trailing: Switch.adaptive(
            value: isPeriodicEnabled,
            activeColor: colors.primary,
            activeTrackColor: colors.primary.withOpacity(0.5),
            onChanged: (value) async {
              controller.toggleSwitchStopNoti(value);
              if (value) {
                defaultToast(text: 'تم تفعيل التنبيهات الدورية للأذكار');
              } else {
                defaultToast(text: 'تم إيقاف التنبيهات الدورية للأذكار');
                await NotifyHelper().flutterLocalNotificationsPlugin.cancel(20);
              }
              setState(() {});
            },
          ),
        ),

        // Cancel All Scheduled Notifications
        SettingsTile(
          icon: Icons.notifications_off_outlined,
          iconColor: colors.error,
          title: 'إلغاء التنبيهات المجدولة',
          subtitle: 'مسح وإعادة ضبط التنبيهات الحالية',
          onTap: () async {
            await NativeAzkarBridge.cancelAzkar();
            defaultToast(text: 'تم إلغاء التنبيهات المجدولة بنجاح');
          },
        ),
      ],
    );
  }

  Future<void> _toggleMorningSwitch(
      SettingsViewModel controller, bool value) async {
    controller.toggleSwitch(value);
    if (value) {
      defaultToast(text: 'تم تفعيل إشعار أذكار الصباح');
      await NotifyHelper().scheduleAzkar(
        timeOfDay: controller.timeOfDay ?? const TimeOfDay(hour: 8, minute: 0),
      );
    } else {
      defaultToast(text: 'تم إيقاف إشعار أذكار الصباح');
      await NotifyHelper().flutterLocalNotificationsPlugin.cancel(1);
    }
  }

  Future<void> _showMorningTimePicker(
      BuildContext context, SettingsViewModel controller) async {
    try {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime:
            controller.timeOfDay ?? const TimeOfDay(hour: 8, minute: 0),
      );

      if (selectedTime == null) return;

      controller.timeOfDay = selectedTime;
      if (!context.mounted) return;
      final formattedTime = selectedTime.format(context);

      if (controller.settingsServices.sharedPref!.getBool('enable') == true) {
        await NotifyHelper().scheduleAzkar(timeOfDay: selectedTime);
        defaultToast(
          text: 'تم ضبط موعد إشعار الصباح على $formattedTime',
        );
      } else {
        defaultToast(text: 'تم حفظ الوقت (الإشعار متوقف حالياً)');
      }
    } catch (e, st) {
      debugPrint('Error setting azkar notification time: $e\n$st');
      defaultToast(text: 'حدث خطأ أثناء تحديد الوقت');
    }
  }
}
