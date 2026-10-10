import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/responsive.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/service/settings/notifications_services.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/adhan/presentation/controllers/adhan_settings_controller.dart';
import 'package:quran_app_android/features/adhan/presentation/view_model/adhan_view_model.dart';
import 'package:quran_app_android/features/mushaf/presentation/utils/mushaf_utils.dart';

class AdhanSettingsView extends StatelessWidget {
  const AdhanSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdhanSettingsController());
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'إعدادات الأذان والمواقيت',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        centerTitle: true,
        actions: [
          if (kDebugMode)
            IconButton(
              icon: Icon(Icons.bug_report_rounded, color: colors.accent),
              tooltip: 'شاشة فحص المنبهات (Debug)',
              onPressed: () => Get.toNamed(AppRoutes.adhanDebug),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }

        final settings = controller.settings.value;

        return MaxWidthContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            children: [
              if (settings.latitude == 0.0 && settings.longitude == 0.0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off_rounded, size: 22, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'لم يتم تحديد موقعك بعد. يرجى تفعيل الموقع أو اختيار مدينتك يدوياً لحساب المواقيت وجدولة تنبيهات الأذان.',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.0,
                          color: colors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (Platform.isIOS) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: colors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تنبيهات أذان iOS: يتم جدولة 8 أيام مسبقاً (40 إشعاراً) بصوت الأذان المبارك وبتصنيف الوقت الحساس (Time-Sensitive). تتجدد الجدولة تلقائياً عند فتح التطبيق.',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.0,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // 1. Calculation Method Card
            _buildSectionHeader('طريقة حساب المواقيت', Icons.calculate_rounded, colors),
            AppSpacing.verticalXs,
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _sanitizeMethod(settings.calculationMethod),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: BorderSide(color: colors.divider),
                      ),
                    ),
                    dropdownColor: colors.surface,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 13.5,
                      color: colors.text,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'EGYPTIAN',
                        child: Text('الهيئة المصرية العامة للمساحة'),
                      ),
                      DropdownMenuItem(
                        value: 'UMM_AL_QURA',
                        child: Text('جامعة أم القرى (مكة المكرمة)'),
                      ),
                      DropdownMenuItem(
                        value: 'MUSLIM_WORLD_LEAGUE',
                        child: Text('رابطة العالم الإسلامي'),
                      ),
                      DropdownMenuItem(
                        value: 'KARACHI',
                        child: Text('جامعة العلوم الإسلامية (كراتشي)'),
                      ),
                      DropdownMenuItem(
                        value: 'NORTH_AMERICA',
                        child: Text('أمريكا الشمالية (ISNA)'),
                      ),
                      DropdownMenuItem(
                        value: 'DUBAI',
                        child: Text('دائرة الشؤون الإسلامية (دبي)'),
                      ),
                      DropdownMenuItem(
                        value: 'KUWAIT',
                        child: Text('وزارة الأوقاف والشؤون الإسلامية (الكويت)'),
                      ),
                      DropdownMenuItem(
                        value: 'QATAR',
                        child: Text('وزارة الأوقاف والشؤون الإسلامية (قطر)'),
                      ),
                      DropdownMenuItem(
                        value: 'SINGAPORE',
                        child: Text('مجلس أوغاما إسلام (سنغافورة)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.updateCalculationMethod(val);
                    },
                  ),
                ],
              ),
            ),

            AppSpacing.verticalMd,

            // 2. Madhab Card (Asr)
            _buildSectionHeader('مذهب صلاة العصر', Icons.balance_rounded, colors),
            AppSpacing.verticalXs,
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.divider),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Text(
                        'جمهور الفقهاء (الشافعي، المالكي، الحنبلي)',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      subtitle: Text(
                        'العصر عند صيرورة ظل الشيء مثله',
                        style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12.0, color: colors.textMuted),
                      ),
                      value: 'SHAFI',
                      groupValue: settings.madhab.toUpperCase(),
                      activeColor: colors.primary,
                      onChanged: (val) => controller.updateMadhab(val!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Text(
                        'المذهب الحنفي',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      subtitle: Text(
                        'العصر عند صيرورة ظل الشيء مثليه',
                        style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12.0, color: colors.textMuted),
                      ),
                      value: 'HANAFI',
                      groupValue: settings.madhab.toUpperCase(),
                      activeColor: colors.primary,
                      onChanged: (val) => controller.updateMadhab(val!),
                    ),
                  ],
                ),
              ),
            ),

            AppSpacing.verticalMd,

            // 3. Adhan Audio Choice
            _buildSectionHeader('صوت الأذان', Icons.volume_up_rounded, colors),
            AppSpacing.verticalXs,
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: 'default',
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: BorderSide(color: colors.divider),
                      ),
                    ),
                    dropdownColor: colors.surface,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 13.5,
                      color: colors.text,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'default',
                        child: Text('الأذان المعتمد الكامل (صوت ندي عالي الجودة)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.updateAdhanSound(val);
                    },
                  ),
                  AppSpacing.verticalSm,
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() {
                      final isPlaying = controller.isPlayingTestAdhan.value;
                      return OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isPlaying ? Colors.redAccent : colors.primary,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMd,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          backgroundColor: isPlaying
                              ? Colors.redAccent.withOpacity(0.08)
                              : null,
                        ),
                        icon: Icon(
                          isPlaying
                              ? Icons.stop_circle_rounded
                              : Icons.play_circle_filled_rounded,
                          color: isPlaying ? Colors.redAccent : colors.primary,
                        ),
                        label: Text(
                          isPlaying
                              ? 'إيقاف صوت الأذان التجريبي'
                              : 'تشغيل تجريبي للأذان الآن',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            color: isPlaying ? Colors.redAccent : colors.primary,
                          ),
                        ),
                        onPressed: () => controller.testAdhanSound('الفجر'),
                      );
                    }),
                  ),
                ],
              ),
            ),

            AppSpacing.verticalMd,

            // 4. Post-Adhan Du'a (Sheikh Al-Shaarawy)
            _buildSectionHeader('دعاء ما بعد الأذان', Icons.record_voice_over_rounded, colors),
            AppSpacing.verticalXs,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.divider),
              ),
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'دعاء ما بعد الأذان (الشيخ الشعراوي)',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  subtitle: Text(
                    'تشغيل دعاء «اللهم رب هذه الدعوة التامة...» بصوت فضيلة الشيخ محمد متولي الشعراوي تلقائياً بعد انتهاء الأذان مباشرة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5,
                      color: colors.textMuted,
                    ),
                  ),
                  value: settings.playPostAdhanDua,
                  activeColor: colors.primary,
                  onChanged: (val) => controller.updatePlayPostAdhanDua(val),
                ),
              ),
            ),

            AppSpacing.verticalMd,

            // Prayer Times Notification Banner Toggle
            _buildSectionHeader('شريط الإشعارات لمواقيت الصلاة', Icons.view_headline_rounded, colors),
            AppSpacing.verticalXs,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.divider),
              ),
              child: StatefulBuilder(
                builder: (context, setBannerState) {
                  final settings = Get.find<SettingsServices>();
                  final isBannerOn = settings.sharedPref?.getBool('prayer_banner_enabled') ?? true;

                  return Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Get.toNamed(AppRoutes.lockScreenBannerSettings),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'بانر مواقيت الصلاة وشاشة القفل',
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: colors.text,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'عرض دائم في شاشة القفل والإشعارات (اضغط للتخصيص)',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 11.5,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: isBannerOn,
                        activeColor: colors.primary,
                        onChanged: (val) async {
                          await settings.sharedPref?.setBool('prayer_banner_enabled', val);
                          setBannerState(() {});
                          if (Get.isRegistered<AdhanViewModel>()) {
                            await Get.find<AdhanViewModel>().syncOngoingPrayerBanner();
                          } else {
                            if (!val) {
                              await NotifyHelper().cancelOngoingPrayerBanner();
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            AppSpacing.verticalMd,

            // 4. Per-Prayer Settings (Toggle, Notification Mode, Minute Adjustments)
            _buildSectionHeader('تخصيص الصلوات والتعديل بالدقائق', Icons.tune_rounded, colors),
            AppSpacing.verticalXs,

            _buildPrayerCustomCard(
              context: context,
              controller: controller,
              prayerKey: 'fajr',
              nameAr: 'صلاة الفجر',
              icon: Icons.nightlight_round,
              enabled: settings.fajrEnabled,
              mode: settings.fajrMode,
              offset: settings.fajrOffset,
              colors: colors,
            ),
            AppSpacing.verticalSm,

            _buildPrayerCustomCard(
              context: context,
              controller: controller,
              prayerKey: 'dhuhr',
              nameAr: 'صلاة الظهر',
              icon: Icons.wb_sunny_rounded,
              enabled: settings.dhuhrEnabled,
              mode: settings.dhuhrMode,
              offset: settings.dhuhrOffset,
              colors: colors,
            ),
            AppSpacing.verticalSm,

            _buildPrayerCustomCard(
              context: context,
              controller: controller,
              prayerKey: 'asr',
              nameAr: 'صلاة العصر',
              icon: Icons.wb_twilight_rounded,
              enabled: settings.asrEnabled,
              mode: settings.asrMode,
              offset: settings.asrOffset,
              colors: colors,
            ),
            AppSpacing.verticalSm,

            _buildPrayerCustomCard(
              context: context,
              controller: controller,
              prayerKey: 'maghrib',
              nameAr: 'صلاة المغرب',
              icon: Icons.wb_sunny_outlined,
              enabled: settings.maghribEnabled,
              mode: settings.maghribMode,
              offset: settings.maghribOffset,
              colors: colors,
            ),
            AppSpacing.verticalSm,

            _buildPrayerCustomCard(
              context: context,
              controller: controller,
              prayerKey: 'isha',
              nameAr: 'صلاة العشاء',
              icon: Icons.bedtime_rounded,
              enabled: settings.ishaEnabled,
              mode: settings.ishaMode,
              offset: settings.ishaOffset,
              colors: colors,
            ),

            AppSpacing.verticalLg,

            // 5. City & Location manual selection
            _buildSectionHeader('الموقع والمدينة', Icons.location_on_rounded, colors),
            AppSpacing.verticalXs,
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderLg,
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.cityName.isNotEmpty
                        ? 'المدينة المحددة: ${settings.cityName}'
                        : 'الإحداثيات: ${settings.latitude.toStringAsFixed(4)}, ${settings.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                      fontSize: 13.5,
                    ),
                  ),
                  AppSpacing.verticalSm,
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ActionChip(
                        label: const Text('القاهرة'),
                        onPressed: () => controller.setCity('القاهرة', 30.0444, 31.2357),
                      ),
                      ActionChip(
                        label: const Text('مكة المكرمة'),
                        onPressed: () => controller.setCity('مكة المكرمة', 21.3891, 39.8579),
                      ),
                      ActionChip(
                        label: const Text('المدينة المنورة'),
                        onPressed: () => controller.setCity('المدينة المنورة', 24.5247, 39.5692),
                      ),
                      ActionChip(
                        label: const Text('الرياض'),
                        onPressed: () => controller.setCity('الرياض', 24.7136, 46.6753),
                      ),
                      ActionChip(
                        label: const Text('الإسكندرية'),
                        onPressed: () => controller.setCity('الإسكندرية', 31.2001, 29.9187),
                      ),
                      ActionChip(
                        label: const Text('المنصورة'),
                        onPressed: () => controller.setCity('المنصورة', 31.0409, 31.3785),
                      ),
                      ActionChip(
                        label: const Text('القدس الشريف'),
                        onPressed: () => controller.setCity('القدس الشريف', 31.7683, 35.2137),
                      ),
                      ActionChip(
                        label: const Text('دبي'),
                        onPressed: () => controller.setCity('دبي', 25.2048, 55.2708),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            AppSpacing.verticalXl,
          ],
        ),
      );
    }),
  );
}

  String _sanitizeMethod(String method) {
    const valid = [
      'EGYPTIAN',
      'UMM_AL_QURA',
      'MUSLIM_WORLD_LEAGUE',
      'KARACHI',
      'NORTH_AMERICA',
      'DUBAI',
      'KUWAIT',
      'QATAR',
      'SINGAPORE',
    ];
    return valid.contains(method.toUpperCase()) ? method.toUpperCase() : 'EGYPTIAN';
  }

  Widget _buildSectionHeader(String title, IconData icon, dynamic colors) {
    return Row(
      children: [
        Icon(icon, size: 18.0, color: colors.primary),
        AppSpacing.horizontalXs,
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            color: colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerCustomCard({
    required BuildContext context,
    required AdhanSettingsController controller,
    required String prayerKey,
    required String nameAr,
    required IconData icon,
    required bool enabled,
    required String mode,
    required int offset,
    required dynamic colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: enabled ? colors.primary : colors.textMuted),
              AppSpacing.horizontalSm,
              Expanded(
                child: Text(
                  nameAr,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: enabled ? colors.text : colors.textMuted,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeColor: colors.primary,
                onChanged: (val) => controller.togglePrayer(prayerKey, val),
              ),
            ],
          ),
          if (enabled) ...[
            const Divider(height: 16.0),
            Row(
              children: [
                Text(
                  'نوع التنبيه: ',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12.5,
                    color: colors.textMuted,
                  ),
                ),
                AppSpacing.horizontalXs,
                Expanded(
                  child: DropdownButton<String>(
                    value: mode,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'adhan', child: Text('أذان كامل بصوت المؤذن')),
                      DropdownMenuItem(value: 'notification_only', child: Text('تنبيه فقط (بدون صوت أذان)')),
                      DropdownMenuItem(value: 'silent', child: Text('صامت (بدون تنبيه)')),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.updateNotificationMode(prayerKey, val);
                    },
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تعديل الموعد بالدقائق:',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12.5,
                    color: colors.textMuted,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                      color: colors.primary,
                      onPressed: () => controller.updateOffset(prayerKey, -1),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(color: colors.divider),
                      ),
                      child: Text(
                        '${offset >= 0 ? '+' : ''}${toArabicDigits(offset)} د',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                          color: offset != 0 ? colors.accent : colors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                      color: colors.primary,
                      onPressed: () => controller.updateOffset(prayerKey, 1),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
