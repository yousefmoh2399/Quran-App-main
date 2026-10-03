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
import 'package:quran_app_android/features/settings/presentation/views/widget/section_theme_mode.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/settings_group_card.dart';
import 'package:quran_app_android/features/settings/presentation/views/widget/settings_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      title: 'المزيد',
      constrainContentWidth: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Identity Header Card
            _buildAppHeaderCard(context, colors),
            AppSpacing.verticalLg,

            // 1. عباداتي
            SettingsGroupCard(
              title: 'عباداتي',
              icon: Icons.auto_awesome_rounded,
              children: [
                SettingsTile(
                  icon: Icons.fact_check_rounded,
                  title: 'سجل الصلوات وقضاء الفوائت',
                  subtitle: 'تسجيل الصلوات اليومية ونسب الالتزام',
                  onTap: () => Get.toNamed(AppRoutes.prayerTracker),
                ),
                SettingsTile(
                  icon: Icons.calendar_today_rounded,
                  title: 'التقويم الهجري والمناسبات',
                  subtitle: 'المناسبات الإسلامية، صيام السنن، وتحويل التاريخ',
                  onTap: () => Get.toNamed(AppRoutes.islamicCalendar),
                ),
                SettingsTile(
                  icon: Icons.nightlight_round,
                  iconColor: const Color(0xFFD4AF37),
                  title: 'واحة رمضان المبارك',
                  subtitle: 'الإمساكية، الختمة، مدفع الإفطار، التراويح، وحاسبة الزكاة',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () => Get.toNamed(AppRoutes.ramadanHub),
                ),
                SettingsTile(
                  icon: Icons.radio_button_checked_rounded,
                  title: 'أذكار ما بعد الصلاة المفروضة',
                  subtitle: 'التسبيح والتحميد والتكبير بعد الفريضة',
                  onTap: () => Get.toNamed(AppRoutes.postPrayerAzkar),
                ),
                SettingsTile(
                  icon: Icons.library_books_rounded,
                  title: 'التفسير الميسر',
                  subtitle: 'تفسير ومعاني آيات وسور القرآن الكريم',
                  onTap: () => Get.toNamed(AppRoutes.tafsser),
                ),
                SettingsTile(
                  icon: Icons.military_tech_rounded,
                  title: 'إنجازاتي وأوسمة القراءة',
                  subtitle: 'متابعة الختمات وأيام الالتزام المستمر',
                  onTap: () => Get.toNamed(AppRoutes.achievements),
                ),
              ],
            ),

            // 2. التذكيرات
            SettingsGroupCard(
              title: 'التذكيرات والتنبيهات',
              icon: Icons.notifications_active_rounded,
              children: [
                SettingsTile(
                  icon: Icons.alarm_on_rounded,
                  iconColor: colors.primary,
                  title: 'تذكيراتي',
                  subtitle: 'الورد اليومي، ورد المواصلات، الصدقة الشهرية، والأذكار',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () => Get.toNamed(AppRoutes.myReminders),
                ),
                SettingsTile(
                  icon: Icons.music_note_rounded,
                  iconColor: colors.primary,
                  title: 'أصوات ونغمات التنبيهات',
                  subtitle: 'تخصيص رنين الإشعارات (الورد، الأذكار، الصدقة) أو توحيدها',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () => Get.toNamed(AppRoutes.notificationSoundsSettings),
                ),
              ],
            ),

            // 3. الأذان ومواقيت الصلاة
            SettingsGroupCard(
              title: 'الأذان ومواقيت الصلاة',
              icon: Icons.access_time_filled_rounded,
              children: [
                SettingsTile(
                  icon: Icons.mosque_outlined,
                  title: 'مواقيت الصلاة اليوم',
                  subtitle: 'متابعة العد التنازلي والمواقيت الكاملة',
                  onTap: () => Get.toNamed(AppRoutes.adhan),
                ),
                SettingsTile(
                  icon: Icons.tune_rounded,
                  title: 'إعدادات الأذان والمؤذن والمواقيت',
                  subtitle: 'طريقة الحساب، المذهب، أصوات المؤذنين، وتعديل الدقائق',
                  onTap: () => Get.toNamed(AppRoutes.adhanSettings),
                ),
                SettingsTile(
                  icon: Icons.screen_lock_portrait_rounded,
                  iconColor: colors.primary,
                  title: 'بانر شاشة القفل والإشعارات',
                  subtitle: 'تثبيت بانر دائم بمواقيت الصلاة، الورد، والذكر وتخصيص ما يظهر فيه',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () => Get.toNamed(AppRoutes.lockScreenBannerSettings),
                ),
                SettingsTile(
                  icon: Icons.security_rounded,
                  title: 'حالة الصلاحيات والتنبيهات',
                  subtitle: 'فحص أذونات الموقع، الإشعارات، والمنبهات في الخلفية',
                  onTap: () => Get.toNamed(AppRoutes.permissionsStatus),
                ),
                if (kDebugMode)
                  SettingsTile(
                    icon: Icons.bug_report_outlined,
                    title: 'فحص جدولة الأذان والتنبيهات',
                    subtitle: 'جدول الـ 7 أيام واختبار التنبيه التجريبي',
                    onTap: () => Get.toNamed(AppRoutes.adhanDebug),
                  ),
              ],
            ),

            // 4. المظهر
            const SectionThemeMode(),

            // 5. النسخ الاحتياطي والبيانات
            SettingsGroupCard(
              title: 'النسخ الاحتياطي واستعادة البيانات',
              icon: Icons.backup_rounded,
              children: [
                SettingsTile(
                  icon: Icons.cloud_sync_rounded,
                  title: 'النسخ الاحتياطي والاستعادة',
                  subtitle: 'تصدير واستيراد العلامات والورد وسجل الصلوات كملف آمن',
                  onTap: () => Get.toNamed(AppRoutes.backupRestore),
                ),
              ],
            ),

            // 6. عن التطبيق
            SettingsGroupCard(
              title: 'عن التطبيق والمصادر',
              icon: Icons.info_outline_rounded,
              children: [
                SettingsTile(
                  icon: Icons.info_rounded,
                  title: 'عن التطبيق والمطور',
                  subtitle: 'معلومات الترخيص والمراجع ومشاركة الأجر',
                  onTap: () => Get.toNamed(AppRoutes.aboutApp),
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: 'سياسة الخصوصية والأمان',
                  subtitle: 'تطبيق محلي تماماً بدون تتبع أو جمع أي بيانات',
                  onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                ),
                const SettingsTile(
                  icon: Icons.verified_outlined,
                  title: 'مصادر النصوص والبيانات',
                  subtitle:
                      'مصحف المدينة (مجمع الملك فهد) • التفسير الميسر • موطأ مالك',
                ),
                const SettingsTile(
                  icon: Icons.wifi_off_rounded,
                  title: 'وضع التشغيل',
                  subtitle: 'يعمل بالكامل دون الحاجة للاتصال بالإنترنت',
                ),
                if (kDebugMode)
                  SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'معرض مكونات التصميم',
                    subtitle: 'استعراض الألوان والرموز والمكونات المرئية',
                    onTap: () => Get.to(() => const DesignGalleryView()),
                  ),
                const SettingsTile(
                  icon: Icons.phonelink_setup_rounded,
                  title: 'إصدار التطبيق',
                  subtitle: '1.1.0 (الإصدار الشامل)',
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
