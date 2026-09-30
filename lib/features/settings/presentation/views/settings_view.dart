import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/gallery/design_gallery_view.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/settings/presentation/view_model/settins_view_model.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/section_azkar_notification.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/section_theme_mode.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/settings_group_card.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/settings_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      title: 'الإعدادات',
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: GetBuilder<SettingsViewModel>(
          init: SettingsViewModel(),
          builder: (controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Identity Card
                _buildAppHeaderCard(context, colors),
                AppSpacing.verticalLg,

                // 1. Appearance / Theme Mode
                const SectionThemeMode(),

                // 2. Azkar & Notifications
                SectionAzkarNotification(controller: controller),

                // 3. Prayer Times & Adhan Settings
                SettingsGroupCard(
                  title: 'مواقيت الصلاة والأذان',
                  icon: Icons.access_time_filled_rounded,
                  children: [
                    SettingsTile(
                      icon: Icons.tune_rounded,
                      title: 'إعدادات الأذان والمؤذن والمواقيت',
                      subtitle:
                          'طريقة الحساب، المذهب، أصوات المؤذنين، وتعديل الدقائق',
                      onTap: () {
                        Get.toNamed(AppRoutes.adhanSettings);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.mosque_outlined,
                      title: 'عرض مواقيت الصلاة اليوم',
                      subtitle: 'متابعة العد التنازلي والمواقيت الكاملة',
                      onTap: () {
                        Get.toNamed(AppRoutes.adhan);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.security_rounded,
                      title: 'حالة الصلاحيات والتنبيهات',
                      subtitle:
                          'فحص أذونات الموقع، الإشعارات، المنبهات والبطارية',
                      onTap: () {
                        Get.toNamed(AppRoutes.permissionsStatus);
                      },
                    ),
                    if (kDebugMode)
                      SettingsTile(
                        icon: Icons.bug_report_outlined,
                        title: 'تشخيص محرك الأذان (Debug)',
                        subtitle:
                            'جدول الـ 7 أيام واختبار التنبيه بعد 10 ثوانٍ',
                        onTap: () {
                          Get.toNamed(AppRoutes.adhanDebug);
                        },
                      ),
                  ],
                ),

                // 4. App Info & Sources
                SettingsGroupCard(
                  title: 'عن التطبيق والمصادر',
                  icon: Icons.info_outline_rounded,
                  children: [
                    const SettingsTile(
                      icon: Icons.verified_outlined,
                      title: 'مصادر النصوص والبيانات',
                      subtitle:
                          'مصحف المدينة (مجمع الملك فهد) • التفسير الميسر • موطأ مالك',
                    ),
                    const SettingsTile(
                      icon: Icons.wifi_off_rounded,
                      title: 'وضع التشغيل',
                      subtitle: 'أوفلاين بالكامل دون الحاجة لشبكة الإنترنت',
                    ),
                    SettingsTile(
                      icon: Icons.palette_outlined,
                      title: 'معرض مكونات التصميم (Design System)',
                      subtitle: 'استعراض الألوان والرموز والمكونات',
                      onTap: () {
                        Get.to(() => const DesignGalleryView());
                      },
                    ),
                    const SettingsTile(
                      icon: Icons.phonelink_setup_rounded,
                      title: 'إصدار التطبيق',
                      subtitle: '1.0.0 (تحديث شامل لواجهة المستخدم)',
                    ),
                  ],
                ),

                // Spiritual Footer Card
                AppCard(
                  variant: AppCardVariant.flat,
                  padding: AppSpacing.paddingMd,
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 22,
                        color: colors.primary,
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        '«اللهم اجعل القرآن ربيع قلوبنا ونور صدورنا وجلاء أحزاننا»',
                        style: TextStyle(
                          fontFamily: AppTypography.decorativeFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        'تطبيق مجاني وخالٍ تماماً من الإعلانات • صدقة جارية',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalXl,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppHeaderCard(BuildContext context, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.12),
            colors.accent.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تطبيق القرآن الكريم والأذكار',
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'رفيقك اليومي للتلاوة والذكر ومواقيت الصلاة',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
