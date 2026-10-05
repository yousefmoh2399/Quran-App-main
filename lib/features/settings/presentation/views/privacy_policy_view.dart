import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/components/app_card.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('سياسة الخصوصية والأمان'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              variant: AppCardVariant.elevated,
              padding: AppSpacing.paddingLg,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined, size: 40, color: colors.primary),
                  ),
                  AppSpacing.verticalMd,
                  const Text(
                    'خصوصيتك أمانة لا نفرط فيها',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تطبيق تقرّب مصمم ليعمل بمبدأ (الخصوصية أولاً Offline-First). لا نقوم بجمع أو بيع أو مشاركة أي بيانات شخصية لك مع أي طرف ثالث على الإطلاق.',
                    style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            AppSpacing.verticalLg,

            _buildSection(
              title: '١. البيانات المخزنة محلياً',
              content:
                  'جميع بياناتك الشخصية المتعلقة بالورد القرآني، والعلامات المرجعية، والآيات المحفوظة، وسجل الصلوات والصيام، تُخزن فقط وبشكل حصري في قاعدة بيانات مشفرة ومحمية محلياً على جهازك، ولا يتم رفعها إلى أي خوادم خارجية.',
              icon: Icons.storage_rounded,
              colors: colors,
            ),
            AppSpacing.verticalMd,

            _buildSection(
              title: '٢. إذن الموقع الجغرافي (Location)',
              content:
                  'يُطلب إذن الموقع الجغرافي فقط عند الحاجة لتحديد خطوط الطول والعرض الخاصة بمدينتك لحساب مواقيت الصلاة الدقيقة وتحديد زاوية اتجاه القبلة نحو الكعبة المشرفة. يتم الحساب داخل جهازك مباشرة ولا يتم تتبع تحركاتك مطلقاً.',
              icon: Icons.location_on_outlined,
              colors: colors,
            ),
            AppSpacing.verticalMd,

            _buildSection(
              title: '٣. إذن الإشعارات والمنبهات (Alarms & Notifications)',
              content:
                  'يستخدم التطبيق نظام التنبيهات الدقيقة (Exact Alarms) فقط لإطلاق نداء الأذان في موعده والتذكير بالورد اليومي والأذكار. يمكنك في أي وقت تخصيص أو كتم هذه الإشعارات من إعدادات التطبيق أو الهاتف.',
              icon: Icons.notifications_none_rounded,
              colors: colors,
            ),
            AppSpacing.verticalMd,

            _buildSection(
              title: '٤. إذن الصور والتخزين (Media Storage)',
              content:
                  'يُستخدم فقط عند قيامك باختيار "مشاركة الآية كصورة" أو "تصدير نسخة احتياطية"، لتمكينك من حفظ بطاقة الآية في معرض الصور أو حفظ ملف النسخ الاحتياطي.',
              icon: Icons.photo_library_outlined,
              colors: colors,
            ),
            AppSpacing.verticalMd,

            _buildSection(
              title: '٥. الإعلانات والتتبع',
              content:
                  'تطبيق تقرّب خالٍ تماماً من أي إعلانات تجارية (100% Ad-Free) ولا يحتوي على أي كود برمجي لتتبع المستخدمين أو التحليلات الإعلانية التطفلية.',
              icon: Icons.block_flipped,
              colors: colors,
            ),
            AppSpacing.verticalLg,

            // Contact Card
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: colors.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: colors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'لأي استفسار بشأن الخصوصية:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'support@taqarrab-app.com',
                          style: TextStyle(fontSize: 12, color: colors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required AppColorsExtension colors,
  }) {
    return AppCard(
      variant: AppCardVariant.flat,
      padding: AppSpacing.paddingMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(fontSize: 12, color: colors.textMuted, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
