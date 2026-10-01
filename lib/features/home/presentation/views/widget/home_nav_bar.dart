import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
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
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withOpacity(0.15),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: colors.textMuted),
            selectedIcon: Icon(Icons.home_rounded, color: colors.primary),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: colors.textMuted),
            selectedIcon: Icon(Icons.menu_book_rounded, color: colors.primary),
            label: 'المصحف',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined, color: colors.textMuted),
            selectedIcon: Icon(Icons.spa_rounded, color: colors.primary),
            label: 'الأذكار',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded, color: colors.textMuted),
            selectedIcon: Icon(Icons.bookmark_rounded, color: colors.primary),
            label: 'علاماتي والورد',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: colors.textMuted),
            selectedIcon: Icon(Icons.grid_view_rounded, color: colors.primary),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}
