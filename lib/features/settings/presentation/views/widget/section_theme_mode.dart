import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/service/theme_controller.dart';

class SectionThemeMode extends StatelessWidget {
  const SectionThemeMode({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeController = Get.find<ThemeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            'مظهر التطبيق',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
          ),
        ),
        Obx(() {
          final currentMode = themeController.themeMode;
          return Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                _buildThemeOption(
                  context: context,
                  label: 'حسب النظام',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () => themeController.setThemeMode(ThemeMode.system),
                ),
                Container(width: 1, height: 36, color: colors.divider),
                _buildThemeOption(
                  context: context,
                  label: 'فاتح',
                  icon: Icons.light_mode_rounded,
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () => themeController.setThemeMode(ThemeMode.light),
                ),
                Container(width: 1, height: 36, color: colors.divider),
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
        borderRadius: AppRadius.borderMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? colors.primary : colors.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isSelected ? colors.primary : colors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
