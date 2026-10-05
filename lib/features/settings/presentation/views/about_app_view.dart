import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/util/routes/routes.dart';
import '../../../../core/util/share_helper.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/util/assets.dart';

class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('عن التطبيق والمصادر'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Branding Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        AssetsData.taqarrabLogo,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تطبيق تَقَرُّب',
                    style: TextStyle(
                      fontFamily: AppTypography.decorativeFont,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الإصدار 1.0.0 • رفيقك اليومي إلى الله',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalXl,

            // Mission Statement
            AppCard(
              variant: AppCardVariant.elevated,
              padding: AppSpacing.paddingLg,
              child: Column(
                children: [
                  const Text(
                    '«خَيْرُكُم مَن تَعَلَّمَ القُرْآنَ وعَلَّمَهُ»',
                    style: TextStyle(
                      fontFamily: AppTypography.decorativeFont,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تطبيق تقرّب يهدف لتقديم تجربة قرآنية وإيمانية أصيلة، فائقة السرعة والخفة، خالية تماماً من الإعلانات والمشتتات، تجمع بين صحبة المصحف الشريف بالرسم العثماني المعتمد، والأذكار، ومواقيت الصلاة، وإعانة المسلم على ورد يومي ثابت.',
                    style: TextStyle(fontSize: 12, color: colors.text, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            AppSpacing.verticalLg,

            // Approved Sources Card
            Text(
              'المصادر والمراجع المعتمدة:',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.verticalSm,
            _buildSourceItem(
              title: 'خطوط المصحف الشريف والرسم العثماني',
              source: 'مجمع الملك فهد لطباعة المصحف الشريف بالمدينة المنورة',
              icon: Icons.auto_stories_rounded,
              colors: colors,
            ),
            _buildSourceItem(
              title: 'حساب مواقيت الصلاة واتجاه القبلة',
              source: 'مكتبة Batoul Apps (Adhan) وهيئة المساحة المصرية وأم القرى',
              icon: Icons.access_time_filled_rounded,
              colors: colors,
            ),
            _buildSourceItem(
              title: 'التفاسير المعتمدة',
              source: 'التفسير الميسر (مجمع الملك فهد)، تفسير السعدي، وتفسير ابن كثير',
              icon: Icons.menu_book_outlined,
              colors: colors,
            ),
            _buildSourceItem(
              title: 'الأذكار النبوية والأدعية',
              source: 'كتاب حصن المسلم من أذكار الكتاب والسنة وكتب الحديث المعتمدة',
              icon: Icons.favorite_rounded,
              colors: colors,
            ),
            AppSpacing.verticalLg,

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('شارك التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Share.share(
                        'حمّل تطبيق "تقرّب" لقراءة القرآن الكريم ومواقيت الصلاة والأذكار بدون إعلانات وبحجم خفيف جداً.\nhttps://play.google.com/store/apps/details?id=com.taqarrab.quran',
                        sharePositionOrigin: getSharePositionOrigin(context),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
                    label: const Text('ادعم التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Get.toNamed(AppRoutes.supportApp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceItem({
    required String title,
    required String source,
    required IconData icon,
    required AppColorsExtension colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  source,
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
