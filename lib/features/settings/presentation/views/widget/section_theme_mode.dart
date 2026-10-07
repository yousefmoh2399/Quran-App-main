import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/service/theme_controller.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/settings_group_card.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';

class SectionThemeMode extends StatelessWidget {
  const SectionThemeMode({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeController = Get.find<ThemeController>();
    final prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());

    return SettingsGroupCard(
      title: 'المظهر والسمة',
      icon: Icons.palette_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر المظهر المفضل للتطبيق:',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 13,
                  color: colors.textMuted,
                ),
              ),
              AppSpacing.verticalSm,
              Obx(() {
                final currentMode = themeController.themeMode;
                return Container(
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    children: [
                      _buildThemeOption(
                        context: context,
                        label: 'تلقائي النظام',
                        icon: Icons.brightness_auto_rounded,
                        isSelected: currentMode == ThemeMode.system,
                        onTap: () => themeController.setThemeMode(ThemeMode.system),
                      ),
                      Container(width: 1, height: 40, color: colors.divider),
                      _buildThemeOption(
                        context: context,
                        label: 'فاتح',
                        icon: Icons.light_mode_rounded,
                        isSelected: currentMode == ThemeMode.light,
                        onTap: () => themeController.setThemeMode(ThemeMode.light),
                      ),
                      Container(width: 1, height: 40, color: colors.divider),
                      _buildThemeOption(
                        context: context,
                        label: 'داكن',
                        icon: Icons.dark_mode_rounded,
                        isSelected: currentMode == ThemeMode.dark,
                        onTap: () => themeController.setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Obx(() {
                final isElderly = prefsController.isElderlyMode.value;
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.accessibility_new_rounded,
                    color: isElderly ? colors.primary : colors.textMuted,
                  ),
                  title: Text(
                    'وضع كبار السن وسهولة الاستخدام',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  subtitle: Text(
                    'تكبير الخطوط والأزرار، تباين لوني عالي، واهتزاز قوي لتسهيل التفاعل',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                  value: isElderly,
                  activeColor: colors.primary,
                  onChanged: (_) => prefsController.toggleElderlyMode(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return Expanded(
      child: Material(
        color: isSelected ? colors.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? colors.primary : colors.textMuted,
                ),
                AppSpacing.verticalXs,
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12,
                    color: isSelected ? colors.primary : colors.textMuted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
