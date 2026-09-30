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

                // 4. Worship Tracking & Calendar
                SettingsGroupCard(
                  title: 'العبادات والتقويم الإسلامي',
                  icon: Icons.calendar_month_rounded,
                  children: [
                    SettingsTile(
                      icon: Icons.fact_check_rounded,
                      title: 'سجل الصلوات وقضاء الفوائت',
                      subtitle: 'تسجيل الصلوات اليومية، نسب الالتزام، والصلوات الفائتة',
                      onTap: () {
                        Get.toNamed(AppRoutes.prayerTracker);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.calendar_today_rounded,
                      title: 'التقويم الهجري والمناسبات',
                      subtitle: 'تحويل التاريخ، المناسبات الإسلامية، وصيام السنن',
                      onTap: () {
                        Get.toNamed(AppRoutes.islamicCalendar);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.nights_stay_rounded,
                      title: 'إمساكية شهر رمضان المبارك',
                      subtitle: 'مواقيت الإمساك والإفطار للشهر الفضيل',
                      onTap: () {
                        Get.toNamed(AppRoutes.ramadanImsakia);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.radio_button_checked_rounded,
                      title: 'أذكار ما بعد الصلاة المفروضة',
                      subtitle: 'التسبيح والتحميد والتكبير بعد الفريضة',
                      onTap: () {
                        Get.toNamed(AppRoutes.postPrayerAzkar);
                      },
                    ),
                  ],
                ),

                // 5. Stats & Backup
                SettingsGroupCard(
                  title: 'الإنجازات والبيانات',
                  icon: Icons.emoji_events_rounded,
                  children: [
                    SettingsTile(
                      icon: Icons.military_tech_rounded,
                      title: 'إحصائيات القراءة والشارات',
                      subtitle: 'متابعة الختمات، أيام الالتزام، والأوسمة التقديرية',
                      onTap: () {
                        Get.toNamed(AppRoutes.achievements);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.backup_rounded,
                      title: 'النسخ الاحتياطي واستعادة البيانات',
                      subtitle: 'تصدير واستيراد العلامات والورد وسجل الصلوات كملف آمن',
                      onTap: () {
                        Get.toNamed(AppRoutes.backupRestore);
                      },
                    ),
                  ],
                ),

                // 6. App Info & Sources
                SettingsGroupCard(
                  title: 'عن التطبيق والمصادر',
                  icon: Icons.info_outline_rounded,
                  children: [
                    SettingsTile(
                      icon: Icons.info_rounded,
                      title: 'عن التطبيق والمطور',
                      subtitle: 'معلومات الترخيص، المراجع، ومشاركة الأجر',
                      onTap: () {
                        Get.toNamed(AppRoutes.aboutApp);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      title: 'سياسة الخصوصية والأمان',
                      subtitle: 'تطبيق محلي 100% بدون تتبع أو جمع بيانات',
                      onTap: () {
                        Get.toNamed(AppRoutes.privacyPolicy);
                      },
                    ),
                    const SettingsTile(
                      icon: Icons.verified_outlined,
                      title: 'مصادر النصوص والبيانات',
                      subtitle:
                          'مصحف المدينة (مجمع الملك فهد) • التفسير الميسر والسعدي • موطأ مالك',
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
                      subtitle: '1.1.0 (الإصدار الإسلامي الشامل)',
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
