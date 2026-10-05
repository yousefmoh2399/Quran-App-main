import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/core/util/assets.dart';
import 'package:quran_app_android/core/util/share_helper.dart';
import 'package:quran_app_android/core/util/native_url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class AppShareView extends StatelessWidget {
  const AppShareView({super.key});

  static const String appDownloadUrl =
      'https://play.google.com/store/apps/details?id=com.taqarrab.quran';

  static const String shareMessage =
      '✨ أنصحكم بتحميل تطبيق «تَقَرُّب» 🕌\n'
      'رفيقك اليومي للتلاوة والذكر ومواقيت الصلاة • تطبيق مجاني تماماً وبدون أي إعلانات!\n\n'
      '📖 مصحف إلكتروني متكامل بالرسم العثماني مع تقليب صفحات واقعي وسلس\n'
      '🕌 مواقيت الصلاة الدقيقة، أصوات الأذان العذبة، وبانر دائم لشاشة القفل\n'
      '📿 أذكار الصباح والمساء، الورد القرآني اليومي، وتنبيهات مخصصة\n'
      '🌙 واحة رمضان المبارك، ختمات التلاوة، وحاسبة الزكاة\n\n'
      'حمّل التطبيق الآن واكسب صدقة جارية بنشره:\n'
      '$appDownloadUrl';

  Future<void> _launchSocialUrl(
    BuildContext context, {
    required String deepLink,
    required String webFallback,
    String? packageName,
    String? customSuccessMessage,
  }) async {
    AppHaptics.selection();

    // 1. Try launching the deep link via NativeUrlLauncher
    bool launched = await NativeUrlLauncher.launchUrl(deepLink, packageName: packageName);

    // 2. If deep link failed, try launching web fallback
    if (!launched) {
      launched = await NativeUrlLauncher.launchUrl(webFallback);
    }

    // 3. If both failed, copy to clipboard as ultimate fallback
    if (!launched && context.mounted) {
      Clipboard.setData(const ClipboardData(text: shareMessage));
      _showToast(context, 'تعذر فتح التطبيق مباشرة، تم نسخ الرسالة والرابط إلى الحافظة');
      return;
    }

    if (customSuccessMessage != null && context.mounted) {
      _showToast(context, customSuccessMessage);
    }
  }

  void _shareViaInstagram(BuildContext context) async {
    AppHaptics.selection();
    await Clipboard.setData(const ClipboardData(text: shareMessage));
    if (context.mounted) {
      _showToast(
        context,
        'تم نسخ نص ورابط المشاركة! جاري فتح إنستغرام للصقه في القصة أو الرسائل ✨',
      );
    }

    final launched = await NativeUrlLauncher.launchUrl(
      'instagram://app',
      packageName: 'com.instagram.android',
    );
    if (!launched) {
      await NativeUrlLauncher.launchUrl('https://instagram.com');
    }
  }

  void _showToast(BuildContext context, String message) {
    final colors = context.appColors;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTypography.uiFont, fontSize: 13),
        ),
        backgroundColor: colors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'نشر التطبيق ومشاركة الأجر',
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
            // Islamic Hadith Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4AF37).withOpacity(0.18),
                    colors.primary.withOpacity(0.12),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            AssetsData.taqarrabLogo,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      AppSpacing.horizontalMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الدال على الخير كفاعله',
                              style: TextStyle(
                                fontFamily: AppTypography.decorativeFont,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '«مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ»',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalMd,
                  Text(
                    'ساهم في نشر كتاب الله والأذكار ومواقيت الصلاة لكل مسلم، واجعلها صدقة جارية يُكتب لك أجر كل من قرأ أو سبّح أو صلى من خلالك.',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12,
                      color: colors.textMuted,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
            AppSpacing.verticalLg,

            // Message Preview & Quick Copy Box
            AppCard(
              variant: AppCardVariant.elevated,
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note_rounded,
                              size: 18, color: colors.primary),
                          AppSpacing.horizontalXs,
                          Text(
                            'نص الرسالة المقترحة للمشاركة:',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          'جاهز للإرسال',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSm,
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.7),
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: colors.divider),
                    ),
                    child: Text(
                      shareMessage,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: AppTypography.uiFont,
                        height: 1.65,
                        color: colors.text,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  AppSpacing.verticalMd,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AppHaptics.selection();
                            Clipboard.setData(
                                const ClipboardData(text: shareMessage));
                            _showToast(context, 'تم نسخ الرسالة بالكامل بنجاح 📋');
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('نسخ الرسالة'),
                        ),
                      ),
                      AppSpacing.horizontalSm,
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AppHaptics.selection();
                            Clipboard.setData(
                                const ClipboardData(text: appDownloadUrl));
                            _showToast(context, 'تم نسخ رابط التطبيق بنجاح 🔗');
                          },
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('نسخ الرابط فقط'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.verticalLg,

            // Direct Social Media Platforms Grid
            Text(
              'اختر منصة المشاركة المباشرة:',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            AppSpacing.verticalSm,

            // 1. WhatsApp & Telegram
            Row(
              children: [
                Expanded(
                  child: _SocialShareCard(
                    title: 'واتساب',
                    subtitle: 'WhatsApp',
                    icon: Icons.chat_rounded,
                    brandColor: const Color(0xFF25D366),
                    onTap: () {
                      final encoded = Uri.encodeComponent(shareMessage);
                      _launchSocialUrl(
                        context,
                        deepLink: 'whatsapp://send?text=$encoded',
                        webFallback: 'https://api.whatsapp.com/send?text=$encoded',
                        packageName: 'com.whatsapp',
                      );
                    },
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: _SocialShareCard(
                    title: 'تيليجرام',
                    subtitle: 'Telegram',
                    icon: Icons.send_rounded,
                    brandColor: const Color(0xFF229ED9),
                    onTap: () {
                      final encodedText = Uri.encodeComponent(shareMessage);
                      final encodedUrl = Uri.encodeComponent(appDownloadUrl);
                      _launchSocialUrl(
                        context,
                        deepLink: 'tg://msg?text=$encodedText',
                        webFallback:
                            'https://t.me/share/url?url=$encodedUrl&text=$encodedText',
                        packageName: 'org.telegram.messenger',
                      );
                    },
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,

            // 2. Messenger & Facebook
            Row(
              children: [
                Expanded(
                  child: _SocialShareCard(
                    title: 'ماسنجر',
                    subtitle: 'Messenger',
                    icon: Icons.messenger_rounded,
                    brandColor: const Color(0xFF0084FF),
                    onTap: () {
                      final encodedUrl = Uri.encodeComponent(appDownloadUrl);
                      _launchSocialUrl(
                        context,
                        deepLink: 'fb-messenger://share?link=$encodedUrl',
                        webFallback:
                            'https://www.facebook.com/dialog/send?link=$encodedUrl&app_id=291494419107518&redirect_uri=https://www.facebook.com',
                        packageName: 'com.facebook.orca',
                      );
                    },
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: _SocialShareCard(
                    title: 'فيسبوك',
                    subtitle: 'Facebook',
                    icon: Icons.facebook_rounded,
                    brandColor: const Color(0xFF1877F2),
                    onTap: () {
                      final encodedUrl = Uri.encodeComponent(appDownloadUrl);
                      final encodedQuote = Uri.encodeComponent(shareMessage);
                      _launchSocialUrl(
                        context,
                        deepLink: 'fb://facewebmodal/f?href=https://www.facebook.com/sharer/sharer.php?u=$encodedUrl',
                        webFallback:
                            'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl&quote=$encodedQuote',
                        packageName: 'com.facebook.katana',
                      );
                    },
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,

            // 3. Instagram & LinkedIn
            Row(
              children: [
                Expanded(
                  child: _SocialShareCard(
                    title: 'إنستجرام',
                    subtitle: 'Instagram',
                    icon: Icons.camera_alt_rounded,
                    brandColor: const Color(0xFFE1306C),
                    onTap: () => _shareViaInstagram(context),
                  ),
                ),
                AppSpacing.horizontalMd,
                Expanded(
                  child: _SocialShareCard(
                    title: 'لينكد إن',
                    subtitle: 'LinkedIn',
                    icon: Icons.work_rounded,
                    brandColor: const Color(0xFF0A66C2),
                    onTap: () {
                      final encodedUrl = Uri.encodeComponent(appDownloadUrl);
                      _launchSocialUrl(
                        context,
                        deepLink: 'linkedin://',
                        webFallback:
                            'https://www.linkedin.com/sharing/share-offsite/?url=$encodedUrl',
                        packageName: 'com.linkedin.android',
                      );
                    },
                  ),
                ),
              ],
            ),
            AppSpacing.verticalLg,

            // Universal Native Share Button
            Builder(
              builder: (btnContext) => FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMd,
                  ),
                ),
                onPressed: () async {
                  AppHaptics.selection();
                  await Share.share(
                    shareMessage,
                    subject: 'تطبيق تقرّب القرآني 🕌',
                    sharePositionOrigin: getSharePositionOrigin(btnContext),
                  );
                },
                icon: const Icon(Icons.share_rounded, size: 20),
                label: const Text(
                  'مشاركة عبر تطبيقات أخرى (System Share)',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            AppSpacing.verticalXl,
          ],
        ),
      ),
    );
  }
}

class _SocialShareCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color brandColor;
  final VoidCallback onTap;

  const _SocialShareCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.brandColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.14),
              borderRadius: AppRadius.borderMd,
              border: Border.all(
                color: brandColor.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: brandColor,
              size: 24,
            ),
          ),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: colors.textMuted.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}
