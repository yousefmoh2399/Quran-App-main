import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';

class HomeNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const HomeNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  void _onItemTapped(int index) {
    if (index == currentIndex) return;
    if (onTap != null) {
      onTap!(index);
      return;
    }
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Get.toNamed(AppRoutes.quranScreen);
        break;
      case 2:
        Get.toNamed(AppRoutes.azkar);
        break;
      case 3:
        Get.toNamed(AppRoutes.bookmarks);
        break;
      case 4:
        Get.toNamed(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.divider, width: 1),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: colors.primary.withOpacity(0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              );
            }
            return TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textMuted,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: colors.surface,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.mosque_outlined, color: colors.textMuted, size: 24),
              selectedIcon: Icon(Icons.mosque_rounded, color: colors.primary, size: 24),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined, color: colors.textMuted, size: 24),
              selectedIcon: Icon(Icons.auto_stories_rounded, color: colors.primary, size: 24),
              label: 'المصحف',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: colors.textMuted, size: 24),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 24),
              label: 'الأذكار',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmarks_outlined, color: colors.textMuted, size: 24),
              selectedIcon: Icon(Icons.bookmarks_rounded, color: colors.primary, size: 24),
              label: 'علاماتي',
            ),
            NavigationDestination(
              icon: Icon(Icons.widgets_outlined, color: colors.textMuted, size: 24),
              selectedIcon: Icon(Icons.widgets_rounded, color: colors.primary, size: 24),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }
}
