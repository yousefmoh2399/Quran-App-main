import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/service/theme_controller.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/settings_group_card.dart';

class SectionThemeMode extends StatelessWidget {
  const SectionThemeMode({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeController = Get.find<ThemeController>();

    return SettingsGroupCard(
      title: 'المظهر والسمة',
      icon: Icons.palette_outlined,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر السمة المفضلة للتطبيق:',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.5,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                final currentMode = themeController.appThemeMode;
                return Row(
                  children: [
                    _buildCompactThemeTile(
                      context: context,
                      label: 'تلقائي',
                      icon: Icons.brightness_auto_rounded,
                      accentColor: const Color(0xFF0288D1),
                      isSelected: currentMode == AppThemeModeType.system,
                      onTap: () => themeController.setAppThemeMode(AppThemeModeType.system),
                    ),
                    const SizedBox(width: 6),
                    _buildCompactThemeTile(
                      context: context,
                      label: 'فاتح',
                      icon: Icons.wb_sunny_rounded,
                      accentColor: const Color(0xFFE65100),
                      isSelected: currentMode == AppThemeModeType.light,
                      onTap: () => themeController.setAppThemeMode(AppThemeModeType.light),
                    ),
                    const SizedBox(width: 6),
                    _buildCompactThemeTile(
                      context: context,
                      label: 'داكن',
                      icon: Icons.dark_mode_rounded,
                      accentColor: const Color(0xFF7E57C2),
                      isSelected: currentMode == AppThemeModeType.dark,
                      onTap: () => themeController.setAppThemeMode(AppThemeModeType.dark),
                    ),
                    const SizedBox(width: 6),
                    _buildCompactThemeTile(
                      context: context,
                      label: 'ورق دافئ',
                      icon: Icons.menu_book_rounded,
                      accentColor: const Color(0xFF8D6E63),
                      isSelected: currentMode == AppThemeModeType.sepia,
                      onTap: () => themeController.setAppThemeMode(AppThemeModeType.sepia),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactThemeTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(colors.isDark ? 0.18 : 0.09)
                  : (colors.isDark ? colors.surface : colors.bg),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : colors.divider.withOpacity(colors.isDark ? 0.35 : 0.5),
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: accentColor.withOpacity(colors.isDark ? 0.22 : 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(colors.isDark ? 0.1 : 0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Clay Mini-Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(isSelected ? 0.28 : 0.12),
                        accentColor.withOpacity(isSelected ? 0.10 : 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: accentColor.withOpacity(isSelected ? 0.45 : 0.22),
                      width: 1.1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 17,
                      color: isSelected ? accentColor : colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Label
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? colors.text : colors.textMuted,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                // Small Active Indicator Pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 12 : 0,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
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
