import 'package:quran_app_android/features/adhan/presentation/widgets/battery_optimization_guide_dialog.dart';
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
        elevation: 0.5,
        title: Text(
          'إعدادات الأذان والمواقيت',
          style: textTheme.titleMedium?.copyWith(
            fontFamily: AppTypography.uiFont,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
              // 1. Location & GPS Header Card
              _buildLocationCard(context, controller, settings, colors),

              AppSpacing.verticalMd,

              // iOS notification notice if on iOS
              if (Platform.isIOS) ...[
                _buildIosNotice(colors),
                AppSpacing.verticalMd,
              ],

              // Android Battery Optimization & Reliability Card
              if (Platform.isAndroid) ...[
                _buildAndroidBatteryCard(context, controller, colors),
                AppSpacing.verticalMd,
              ],

              // 2. The 5 Prayers Customization (Fajr, Dhuhr, Asr, Maghrib, Isha)
              _buildSectionTitle(
                title: 'تخصيص تنبيهات الصلوات الخمس',
                subtitle: 'تحكم في تفعيل أو إيقاف الأذان لكل صلاة بشكل مستقل مع تحديد نوع التنبيه والدقائق',
                icon: Icons.notifications_active_rounded,
                colors: colors,
              ),
              AppSpacing.verticalSm,

              _buildPrayerCard(
                context: context,
                controller: controller,
                prayerKey: 'fajr',
                nameAr: 'صلاة الفجر',
                icon: Icons.nightlight_round,
                accentColor: const Color(0xFF3F51B5),
                enabled: settings.fajrEnabled,
                mode: settings.fajrMode,
                offset: settings.fajrOffset,
                colors: colors,
              ),
              AppSpacing.verticalSm,

              _buildPrayerCard(
                context: context,
                controller: controller,
                prayerKey: 'dhuhr',
                nameAr: 'صلاة الظهر',
                icon: Icons.wb_sunny_rounded,
                accentColor: const Color(0xFFF57C00),
                enabled: settings.dhuhrEnabled,
                mode: settings.dhuhrMode,
                offset: settings.dhuhrOffset,
                colors: colors,
              ),
              AppSpacing.verticalSm,

              _buildPrayerCard(
                context: context,
                controller: controller,
                prayerKey: 'asr',
                nameAr: 'صلاة العصر',
                icon: Icons.wb_twilight_rounded,
                accentColor: const Color(0xFFE65100),
                enabled: settings.asrEnabled,
                mode: settings.asrMode,
                offset: settings.asrOffset,
                colors: colors,
              ),
              AppSpacing.verticalSm,

              _buildPrayerCard(
                context: context,
                controller: controller,
                prayerKey: 'maghrib',
                nameAr: 'صلاة المغرب',
                icon: Icons.wb_sunny_outlined,
                accentColor: const Color(0xFFC2185B),
                enabled: settings.maghribEnabled,
                mode: settings.maghribMode,
                offset: settings.maghribOffset,
                colors: colors,
              ),
              AppSpacing.verticalSm,

              _buildPrayerCard(
                context: context,
                controller: controller,
                prayerKey: 'isha',
                nameAr: 'صلاة العشاء',
                icon: Icons.bedtime_rounded,
                accentColor: const Color(0xFF1A237E),
                enabled: settings.ishaEnabled,
                mode: settings.ishaMode,
                offset: settings.ishaOffset,
                colors: colors,
              ),

              AppSpacing.verticalLg,

              // 3. Adhan Audio & Live Preview Studio
              _buildSectionTitle(
                title: 'صوت الأذان والتجربة المباشرة',
                subtitle: 'معاينة صوت الأذان المعتمد بجودة عالية للتأكد من وصول التنبيه',
                icon: Icons.volume_up_rounded,
                colors: colors,
              ),
              AppSpacing.verticalSm,
              _buildAdhanAudioCard(context, controller, settings, colors),

              AppSpacing.verticalLg,

              // 4. Sheikh Al-Shaarawy Post-Adhan Du'a
              _buildSectionTitle(
                title: 'دعاء ما بعد الأذان',
                subtitle: 'سُنّة النبي ﷺ بصوت فضيلة الشيخ محمد متولي الشعراوي',
                icon: Icons.record_voice_over_rounded,
                colors: colors,
              ),
              AppSpacing.verticalSm,
              _buildPostAdhanDuaCard(controller, settings, colors),

              AppSpacing.verticalLg,

              // 5. Lock Screen & Notification Banner
              _buildSectionTitle(
                title: 'شريط شاشة القفل والإشعارات',
                subtitle: 'بانر أنيق ومستمر لمواقيت الصلاة ومتابعة الورد اليومي',
                icon: Icons.view_headline_rounded,
                colors: colors,
              ),
              AppSpacing.verticalSm,
              _buildBannerCard(context, colors),

              AppSpacing.verticalLg,

              // 6. Calculation Method & Fiqh
              _buildSectionTitle(
                title: 'طريقة الحساب والمذهب الفقهي',
                subtitle: 'اختيار الهيئة المعتمدة لحساب المواقيت ومذهب صلاة العصر',
                icon: Icons.balance_rounded,
                colors: colors,
              ),
              AppSpacing.verticalSm,
              _buildCalculationCard(context, controller, settings, colors),

              AppSpacing.verticalXl,
            ],
          ),
        );
      }),
    );
  }

  // ==========================================
  // SECTION BUILDERS
  // ==========================================

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
    required dynamic colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                borderRadius: AppRadius.borderSm,
              ),
              child: Icon(icon, size: 18.0, color: colors.primary),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0,
                  color: colors.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3.0),
        Padding(
          padding: const EdgeInsets.only(right: 32.0),
          child: Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11.5,
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    AdhanSettingsController controller,
    dynamic settings,
    dynamic colors,
  ) {
    final hasLocation = !(settings.latitude == 0.0 && settings.longitude == 0.0);
    final cityName = settings.cityName.isNotEmpty
        ? settings.cityName
        : (hasLocation ? 'موقع محدد بالإحداثيات' : 'لم يتم تحديد الموقع');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: hasLocation ? colors.primary.withOpacity(0.25) : Colors.amber.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: hasLocation
                      ? colors.primary.withOpacity(0.12)
                      : Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasLocation ? Icons.location_on_rounded : Icons.location_off_rounded,
                  color: hasLocation ? colors.primary : Colors.amber.shade800,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cityName,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      hasLocation
                          ? 'الإحداثيات: ${settings.latitude.toStringAsFixed(3)}° شمالاً، ${settings.longitude.toStringAsFixed(3)}° شرقاً'
                          : 'يرجى تحديد موقعك لاحتساب مواقيت الصلاة بدقة',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: hasLocation ? colors.textMuted : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Obx(() {
            final isDetecting = controller.isDetectingLocation.value;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isDetecting ? null : () => controller.detectCurrentLocation(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                icon: isDetecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  isDetecting ? 'جاري تحديد موقعك الحالي بدقة...' : 'تحديث وتحديد موقعي تلقائياً (GPS)',
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),

          const Divider(height: 24.0),

          Text(
            'أو اختر مدينتك مباشرة:',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8.0),

          // Quick City Selection Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCityChip(controller, 'القاهرة', 30.0444, 31.2357, settings.cityName, colors),
                _buildCityChip(controller, 'الإسكندرية', 31.2001, 29.9187, settings.cityName, colors),
                _buildCityChip(controller, 'المنصورة', 31.0409, 31.3785, settings.cityName, colors),
                _buildCityChip(controller, 'طنطا', 30.7865, 31.0004, settings.cityName, colors),
                _buildCityChip(controller, 'الزقازيق', 30.5877, 31.5020, settings.cityName, colors),
                _buildCityChip(controller, 'أسيوط', 27.1783, 31.1859, settings.cityName, colors),
                _buildCityChip(controller, 'سوهاج', 26.5569, 31.6948, settings.cityName, colors),
                _buildCityChip(controller, 'بورسعيد', 31.2653, 32.3019, settings.cityName, colors),
                _buildCityChip(controller, 'السويس', 29.9668, 32.5498, settings.cityName, colors),
                _buildCityChip(controller, 'أسوان', 24.0889, 32.8998, settings.cityName, colors),
                _buildCityChip(controller, 'مكة المكرمة', 21.3891, 39.8579, settings.cityName, colors),
                _buildCityChip(controller, 'المدينة المنورة', 24.5247, 39.5692, settings.cityName, colors),
                _buildCityChip(controller, 'القدس الشريف', 31.7683, 35.2137, settings.cityName, colors),
                _buildCityChip(controller, 'الرياض', 24.7136, 46.6753, settings.cityName, colors),
                _buildCityChip(controller, 'دبي', 25.2048, 55.2708, settings.cityName, colors),
                _buildCityChip(controller, 'عمّان', 31.9454, 35.9284, settings.cityName, colors),
                _buildCityChip(controller, 'طرابلس', 32.8872, 13.1913, settings.cityName, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityChip(
    AdhanSettingsController controller,
    String name,
    double lat,
    double lng,
    String currentCity,
    dynamic colors,
  ) {
    final isSelected = currentCity == name;

    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: FilterChip(
        label: Text(name),
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
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colors.primary : colors.text,
        ),
        onSelected: (_) {
          controller.setCity(name, lat, lng);
        },
      ),
    );
  }

  Widget _buildPrayerCard({
    required BuildContext context,
    required AdhanSettingsController controller,
    required String prayerKey,
    required String nameAr,
    required IconData icon,
    required Color accentColor,
    required bool enabled,
    required String mode,
    required int offset,
    required dynamic colors,
  }) {
    String modeLabel;
    IconData modeIcon;
    if (!enabled) {
      modeLabel = 'معطّل (لا يوجد أذان)';
      modeIcon = Icons.notifications_off_rounded;
    } else if (mode == 'adhan') {
      modeLabel = 'أذان كامل بصوت المؤذن';
      modeIcon = Icons.volume_up_rounded;
    } else if (mode == 'notification_only') {
      modeLabel = 'تنبيه هادئ (إشعار فقط)';
      modeIcon = Icons.notifications_active_rounded;
    } else {
      modeLabel = 'صامت';
      modeIcon = Icons.notifications_none_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: enabled ? colors.primary.withOpacity(0.35) : colors.divider,
          width: enabled ? 1.3 : 1.0,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: colors.primary.withOpacity(0.04),
                  blurRadius: 6.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon, Title, Status, Switch
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: enabled ? accentColor.withOpacity(0.12) : colors.textMuted.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? accentColor : colors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameAr,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: enabled ? colors.text : colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          modeIcon,
                          size: 13,
                          color: enabled ? (mode == 'adhan' ? colors.primary : colors.accent) : colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            modeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 11.5,
                              color: enabled ? colors.textMuted : colors.textMuted.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeColor: colors.primary,
                onChanged: (val) {
                  controller.togglePrayer(prayerKey, val);
                },
              ),
            ],
          ),

          // Sub-options when enabled
          if (enabled) ...[
            const Divider(height: 20.0),

            // 1. Alert Type Selector Pills
            Text(
              'نوع التنبيه عند حلول الوقت:',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 8.0),

            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildModePill(
                        label: 'أذان كامل',
                        icon: Icons.volume_up_rounded,
                        isSelected: mode == 'adhan',
                        onTap: () => controller.updateNotificationMode(prayerKey, 'adhan'),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: _buildModePill(
                        label: 'تنبيه فقط',
                        icon: Icons.notifications_active_rounded,
                        isSelected: mode == 'notification_only',
                        onTap: () => controller.updateNotificationMode(prayerKey, 'notification_only'),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: _buildModePill(
                        label: 'صامت',
                        icon: Icons.notifications_off_rounded,
                        isSelected: mode == 'silent',
                        onTap: () => controller.updateNotificationMode(prayerKey, 'silent'),
                        colors: colors,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12.0),

            // 2. Minute Adjustment Stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: colors.bg.withOpacity(0.6),
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: colors.divider.withOpacity(0.6)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 6.0,
                children: [
                  Text(
                    'تعديل الموعد يدوياً:',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12.0,
                      color: colors.textMuted,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decrease (-)
                      InkWell(
                        onTap: () => controller.updateOffset(prayerKey, -1),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 22,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      // Offset Value Badge
                      Container(
                        constraints: const BoxConstraints(minWidth: 54),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(
                            color: offset != 0 ? colors.accent : colors.divider,
                            width: offset != 0 ? 1.2 : 0.8,
                          ),
                        ),
                        child: Text(
                          '${offset > 0 ? '+' : ''}${toArabicDigits(offset)} د',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: offset != 0 ? colors.accent : colors.text,
                          ),
                        ),
                      ),
                      // Increase (+)
                      InkWell(
                        onTap: () => controller.updateOffset(prayerKey, 1),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            size: 22,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      // Reset to 0 button if adjusted
                      if (offset != 0) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => controller.resetOffset(prayerKey),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.replay_rounded,
                              size: 16,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModePill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.14) : colors.bg,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider,
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.primary : colors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colors.primary : colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdhanAudioCard(
    BuildContext context,
    AdhanSettingsController controller,
    dynamic settings,
    dynamic colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.music_note_rounded, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الأذان المعتمد الكامل',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'أذان الحرم المكي الشريف بصوت ندي نقي عالي الجودة',
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

          const Divider(height: 22.0),

          // Live Test Adhan Button
          Obx(() {
            final isPlaying = controller.isPlayingTestAdhan.value;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPlaying ? Colors.red.shade700 : colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                  elevation: isPlaying ? 2 : 0,
                ),
                icon: Icon(
                  isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded,
                  size: 20,
                ),
                label: Text(
                  isPlaying ? 'إيقاف صوت الأذان التجريبي' : 'تشغيل تجريبي للأذان الآن',
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                onPressed: () => controller.testAdhanSound('الفجر'),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPostAdhanDuaCard(
    AdhanSettingsController controller,
    dynamic settings,
    dynamic colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.record_voice_over_rounded, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دعاء ما بعد الأذان (الشيخ الشعراوي)',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'تشغيل دعاء «اللهم رب هذه الدعوة التامة...» بصوت فضيلة الشيخ محمد متولي الشعراوي تلقائياً بعد انتهاء الأذان',
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
          const SizedBox(width: 8),
          Switch.adaptive(
            value: settings.playPostAdhanDua,
            activeColor: colors.primary,
            onChanged: (val) => controller.updatePlayPostAdhanDua(val),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context, dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_clock_rounded, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => Get.toNamed(AppRoutes.lockScreenBannerSettings),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'بانر شاشة القفل والإشعارات',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                                color: colors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'عرض دائم ومحدث في شاشة القفل (اضغط للتخصيص الكامل)',
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
              const SizedBox(width: 8),
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
    );
  }

  Widget _buildCalculationCard(
    BuildContext context,
    AdhanSettingsController controller,
    dynamic settings,
    dynamic colors,
  ) {
    final currentMethod = _sanitizeMethod(settings.calculationMethod);
    final isShafi = settings.madhab.toUpperCase() != 'HANAFI';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Calculation Authority
          Text(
            'طريقة حساب المواقيت الفلكية:',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontWeight: FontWeight.bold,
              fontSize: 13.0,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8.0),
          DropdownButtonFormField<String>(
            value: currentMethod,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: colors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: colors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
            dropdownColor: colors.surface,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13.0,
              color: colors.text,
            ),
            items: const [
              DropdownMenuItem(
                value: 'EGYPTIAN',
                child: Text('الهيئة المصرية العامة للمساحة (مصر والدول المجاورة)'),
              ),
              DropdownMenuItem(
                value: 'UMM_AL_QURA',
                child: Text('جامعة أم القرى (مكة المكرمة والسعودية والخليج)'),
              ),
              DropdownMenuItem(
                value: 'MUSLIM_WORLD_LEAGUE',
                child: Text('رابطة العالم الإسلامي (أوروبا ومعظم الدول)'),
              ),
              DropdownMenuItem(
                value: 'KARACHI',
                child: Text('جامعة العلوم الإسلامية (كراتشي، باكستان)'),
              ),
              DropdownMenuItem(
                value: 'NORTH_AMERICA',
                child: Text('الجمعية الإسلامية لأمريكا الشمالية (ISNA)'),
              ),
              DropdownMenuItem(
                value: 'DUBAI',
                child: Text('دائرة الشؤون الإسلامية والعمل الخيري (دبي)'),
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

          const Divider(height: 24.0),

          // 2. Asr Madhab
          Text(
            'مذهب صلاة العصر:',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontWeight: FontWeight.bold,
              fontSize: 13.0,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'المعمول به في مساجد مصر ومعظم الدول العربية هو «جمهور الفقهاء». في «المذهب الحنفي» يدخل وقت العصر متأخراً بنحو 50 دقيقة (عند بلوغ الظل مثليه).',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.0,
                      color: colors.text,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 280) {
                return Column(
                  children: [
                    _buildMadhabCard(
                      title: 'جمهور الفقهاء',
                      subtitle: 'الشافعي، المالكي، الحنبلي (الظل مثله)',
                      isSelected: isShafi,
                      onTap: () => controller.updateMadhab('SHAFI'),
                      colors: colors,
                    ),
                    const SizedBox(height: 8.0),
                    _buildMadhabCard(
                      title: 'المذهب الحنفي',
                      subtitle: 'الإمام أبو حنيفة (الظل مثليه)',
                      isSelected: !isShafi,
                      onTap: () {
                        if (isShafi) {
                          _confirmHanafiSwitch(context, controller, colors);
                        }
                      },
                      colors: colors,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildMadhabCard(
                      title: 'جمهور الفقهاء',
                      subtitle: 'الشافعي، المالكي، الحنبلي (الظل مثله)',
                      isSelected: isShafi,
                      onTap: () => controller.updateMadhab('SHAFI'),
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMadhabCard(
                      title: 'المذهب الحنفي',
                      subtitle: 'الإمام أبو حنيفة (الظل مثليه)',
                      isSelected: !isShafi,
                      onTap: () {
                        if (isShafi) {
                          _confirmHanafiSwitch(context, controller, colors);
                        }
                      },
                      colors: colors,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMadhabCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colors.primary : colors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 10.5,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosNotice(dynamic colors) {
    return Container(
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
    );
  }

  Widget _buildAndroidBatteryCard(
    BuildContext context,
    AdhanSettingsController controller,
    dynamic colors,
  ) {
    return Obx(() {
      final status = controller.reliabilityStatus.value;
      if (status == null) return const SizedBox.shrink();

      final isGood = status.isFullyConfigured;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: isGood ? colors.primary.withOpacity(0.35) : Colors.amber.withOpacity(0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isGood ? colors.primary.withOpacity(0.12) : Colors.amber.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGood ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
                    color: isGood ? colors.primary : Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGood
                            ? 'عمل الأذان في الخلفية: مثالي وغير مقيد ✅'
                            : 'الأذان مقيد بموفر البطارية أو المنبهات ⚠️',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGood
                            ? 'التطبيق مستثنى من توفير البطارية وصلاحيات الأذان تعمل بأعلى دقة.'
                            : 'لضمان انطلاق الأذان في وقته بدقة تامة، يرجى استثناء التطبيق من موفر البطارية.',
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
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isGood)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text(
                      'شرح خطوات هاتفك 📱',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      BatteryOptimizationGuideDialog.show(context, onSettingsCompleted: () {
                        controller.checkReliability();
                      });
                    },
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text(
                      'ضبط استثناء البطارية (دليل هاتفك) 📱',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    onPressed: () {
                      BatteryOptimizationGuideDialog.show(context, onSettingsCompleted: () {
                        controller.checkReliability();
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      );
    });
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
  void _confirmHanafiSwitch(
    BuildContext context,
    AdhanSettingsController controller,
    dynamic colors,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        backgroundColor: colors.surface,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تأكيد تغيير مذهب العصر',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: colors.text,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'في المذهب الحنفي، لا يدخل وقت صلاة العصر إلا عندما يصير ظل كل شيء مثليه، مما يجعل موعد أذان العصر متأخراً بنحو 45 إلى 55 دقيقة مقارنة بالمساجد والأذان الرسمي في مصر ومعظم الدول العربية.\n\nهل ترغب بالتأكيد في التحويل للمذهب الحنفي؟',
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 12.5,
            color: colors.text,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'إلغاء (البقاء على الجمهور)',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                color: colors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.updateMadhab('HANAFI');
            },
            child: const Text(
              'تأكيد التحويل',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
