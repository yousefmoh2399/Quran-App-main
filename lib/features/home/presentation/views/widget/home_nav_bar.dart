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
              icon: Opacity(
                opacity: 0.75,
                child: Image.asset(
                  'assets/images/icon_3d_qiblah.png',
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
              selectedIcon: Image.asset(
                'assets/images/icon_3d_qiblah.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Opacity(
                opacity: 0.75,
                child: Image.asset(
                  'assets/images/icon_3d_quran.png',
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
              selectedIcon: Image.asset(
                'assets/images/icon_3d_quran.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              label: 'المصحف',
            ),
            NavigationDestination(
              icon: Opacity(
                opacity: 0.75,
                child: Image.asset(
                  'assets/images/icon_3d_tasbeeh.png',
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
              selectedIcon: Image.asset(
                'assets/images/icon_3d_tasbeeh.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              label: 'الأذكار',
            ),
            NavigationDestination(
              icon: Opacity(
                opacity: 0.75,
                child: Image.asset(
                  'assets/images/icon_3d_khatma_circles.png',
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
              selectedIcon: Image.asset(
                'assets/images/icon_3d_khatma_circles.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              label: 'علاماتي',
            ),
            NavigationDestination(
              icon: Opacity(
                opacity: 0.75,
                child: Image.asset(
                  'assets/images/icon_3d_card_studio.png',
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
              ),
              selectedIcon: Image.asset(
                'assets/images/icon_3d_card_studio.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }
}
