import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/design/components/app_scaffold.dart';
import 'package:get/get.dart';
import '../../../../core/util/assets.dart';
import '../../../../core/util/routes/routes.dart';
import '../../../../core/util/share_helper.dart';

class SupportAppView extends StatefulWidget {
  const SupportAppView({super.key});

  @override
  State<SupportAppView> createState() => _SupportAppViewState();
}

class _SupportAppViewState extends State<SupportAppView> {
  static const String walletNumber = '01064053764';
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }

  void _copyWalletNumber(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: walletNumber));
    HapticFeedback.mediumImpact();
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم نسخ رقم المحفظة بنجاح: $walletNumber',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: context.appColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        duration: const Duration(seconds: 3),
      ),
    );

    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _shareApp(BuildContext context) {
    final storeLink = Platform.isIOS
        ? 'https://apps.apple.com/app/id6470000000'
        : 'https://play.google.com/store/apps/details?id=com.taqarrab.quran';
    Share.share(
      'تطبيق "تقرّب" — رفيقك اليومي للقرآن الكريم، الأذكار، ومواقيت الصلاة، تطبيق مجاني وخالٍ تماماً 100% من الإعلانات.\nحمّله وشاركه صدقة جارية:\n$storeLink',
      sharePositionOrigin: getSharePositionOrigin(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      title: 'دعم وتطوير تقرّب',
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
            // 1. Header Card with Taqarrab Brand & Ad-Free Promise
            _buildHeroHeader(colors),
            AppSpacing.verticalLg,

            // 2. Donation & Wallet Card (Android only) vs Islamic Community Support Card (iOS)
            if (!Platform.isIOS) ...[
              _buildWalletCard(context, colors),
              AppSpacing.verticalLg,
            ] else ...[
              _buildIosSupportCard(context, colors),
              AppSpacing.verticalLg,
            ],

            // 3. Why Support Matters (Impact Breakdown)
            _buildImpactSection(colors),
            AppSpacing.verticalLg,

            // 4. Alternative Ways to Support (Non-Monetary) on Android
            if (!Platform.isIOS) ...[
              _buildAlternativeSupportCard(context, colors),
              AppSpacing.verticalLg,
            ],

            // 5. Spiritual Blessing Card
            _buildSpiritualClosing(colors),
            AppSpacing.verticalXl,
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.14),
            const Color(0xFFD4AF37).withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.primary.withOpacity(0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                AssetsData.taqarrabLogo,
                fit: BoxFit.cover,
              ),
            ),
          ),
          AppSpacing.verticalMd,
          Text(
            'تطبيق «تقرّب» نقيّ وبدون أي إعلانات',
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalXs,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary.withOpacity(0.3)),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.verified_rounded, size: 16, color: colors.primary),
                    ),
                  ),
                  TextSpan(
                    text: '100% خالٍ من الإعلانات التجارية',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          AppSpacing.verticalMd,
          Text(
            Platform.isIOS
                ? 'حرصاً على قدسية كتاب الله وهيبة الذكر، عاهدنا أنفسنا ألا نضع أي إعلان يقطع خشوعك أو يشتت تلاوتك.\n\nاستمرار التطبيق مجاناً بالكامل متاحٌ بفضل الله ثم بدعواتكم الطيبة ومشاركتكم للتطبيق ليكون صدقةً جارية لنا ولكم بإذن الله.'
                : 'حرصاً على قدسية كتاب الله وهيبة الذكر، عاهدنا أنفسنا ألا نضع أي إعلان يقطع خشوعك أو يشتت تلاوتك.\n\nاستمرار التطبيق مجاناً، وتحديث خوادم الأذان والقبلة، وتطوير ميزات جديدة يحتاج جهداً وتكاليف تشغيلية مستمرة. مساهمتك الكريمة تُمكّننا من مواصلة هذه الرسالة صدقةً جارية بإذن الله.',
            style: TextStyle(
              fontSize: 13,
              height: 1.65,
              color: colors.text,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIosSupportCard(BuildContext context, AppColorsExtension colors) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: colors.primary,
                  size: 24,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شارك في نشر الخير والأجر',
                      style: TextStyle(
                        fontFamily: AppTypography.decorativeFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      'الدال على الخير كفاعله • صدقة جارية',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.divider),
            ),
            child: Text(
              'تطبيق تقرّب وقف إسلامي مجاني بالكامل لوجه الله تعالى وخالٍ 100% من الإعلانات التجارية. أعظم دعم تقدمه لنا هو إيصال هذا الخير إلى أهلك وأصدقائك وكتابة تقييمك الطيب على متجر App Store.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: colors.text,
              ),
            ),
          ),
          AppSpacing.verticalMd,
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            icon: const Icon(Icons.share_rounded, size: 20),
            label: const Text(
              'مشاركة تطبيق تقرّب مع الأهل والأصدقاء',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            onPressed: () => _shareApp(context),
          ),
          AppSpacing.verticalSm,
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            icon: const Icon(Icons.star_rate_rounded, color: Color(0xFFD4AF37), size: 20),
            label: const Text(
              'تقييم التطبيق 5 نجوم على App Store ⭐',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () => _shareApp(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, AppColorsExtension colors) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFFD4AF37),
                  size: 24,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم المحفظة الإلكترونية للتحويل',
                      style: TextStyle(
                        fontFamily: AppTypography.decorativeFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      'فودافون كاش • إنستاباي • محافظ البنوك الذكية',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalLg,

          // Wallet Number Box
          InkWell(
            onTap: () => _copyWalletNumber(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: _copied ? Colors.green : colors.primary.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      walletNumber,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                        color: colors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                        color: _copied ? Colors.green : colors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _copied ? 'تم النسخ بنجاح!' : 'اضغط للنسخ إلى الحافظة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _copied ? Colors.green : colors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalMd,

          // Copy Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              elevation: 2,
            ),
            onPressed: () => _copyWalletNumber(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _copied ? Icons.check_rounded : Icons.content_copy_rounded,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _copied ? 'تم نسخ الرقم بنجاح' : 'نسخ رقم المحفظة (01064053764)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalSm,
          Text(
            '💡 يمكنك التحويل عبر أي تطبيق محفظة (فودافون كاش، أورنج كاش، وي باي، إتصالات كاش، إنستاباي، أو محفظة بنكك الإلكترونية).',
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: colors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection(AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            Platform.isIOS ? 'رسالتنا وأهدافنا في تطبيق تقرّب' : 'أين يُصرف دعمك ومساهمتك؟',
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
        ),
        AppSpacing.verticalSm,
        _buildPillarTile(
          icon: Icons.block_flipped,
          color: Colors.redAccent,
          title: 'بقاء التطبيق خالياً من الإعلانات تماماً',
          description:
              'الحفاظ على بيئة تلاوة روحانية نقية بدون أي إعلانات تجارية تعكر صفو تدبرك.',
          colors: colors,
        ),
        _buildPillarTile(
          icon: Icons.dns_rounded,
          color: Colors.teal,
          title: 'تغطية تكاليف الخوادم والخدمات السحابية',
          description:
              'ضمان التحديث اللحظي لمواقيت الصلاة، اتجاه القبلة، والتنبيهات الدقيقة.',
          colors: colors,
        ),
        _buildPillarTile(
          icon: Icons.auto_stories_rounded,
          color: const Color(0xFFD4AF37),
          title: 'تطوير ميزات جديدة ومصاحف معتمدة',
          description:
              'إضافة تفاسير وقراءات ومصاحف متنوعة وتجربة تصفح أسرع وأسلس.',
          colors: colors,
        ),
        _buildPillarTile(
          icon: Icons.volunteer_activism_rounded,
          color: colors.primary,
          title: 'صدقة جارية ومشاركة للأجر',
          description:
              'لك مثل أجر كل آية تُتلى وتسبيحة تُرفع من مستخدمي التطبيق حول العالم.',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildPillarTile({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required AppColorsExtension colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
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

  Widget _buildAlternativeSupportCard(
      BuildContext context, AppColorsExtension colors) {
    return AppCard(
      variant: AppCardVariant.flat,
      padding: AppSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_rounded, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'طرق أخرى لدعمنا إن لم يتيسر التبرع المادي',
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,
          Text(
            'الدعم لا يقتصر على المال، فمشاركتك ودعاؤك لهما عظيم الأثر:',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
          AppSpacing.verticalSm,
          _buildAlternativeItem('🤲 الدعاء للقائمين على التطبيق بالتوفيق والقبول والإخلاص.'),
          _buildAlternativeItem('⭐ تقييم التطبيق 5 نجوم على المتجر لمساعدتنا على الوصول لمسلمين أكثر.'),
          _buildAlternativeItem('📢 مشاركة التطبيق مع أهلك وأصدقائك (الدال على الخير كفاعله).'),
          AppSpacing.verticalMd,
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
            ),
            onPressed: () => Get.toNamed(AppRoutes.appShare),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.share_rounded, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'مشاركة تطبيق تقرّب مع الأهل والأصدقاء',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
    );
  }

  Widget _buildSpiritualClosing(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.primary.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFD4AF37), size: 24),
          const SizedBox(height: 6),
          Text(
            '«مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ»',
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'جزاكم الله خير الجزاء وتقبّل منا ومنكم صالح الأعمال',
            style: TextStyle(
              fontSize: 12,
              color: colors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
