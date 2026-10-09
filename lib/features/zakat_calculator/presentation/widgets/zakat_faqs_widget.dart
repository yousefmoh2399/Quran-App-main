import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';

class ZakatFaqsWidget extends StatelessWidget {
  const ZakatFaqsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final faqs = [
      {
        'q': 'هل تجب الزكاة في المرتب الشهري فور استلامه؟',
        'a': 'لا تجب الزكاة في المرتب الشهري بمجرد قبضه، لأن شرط وجوب زكاة المال هو «حَوَلان الحَوْل» (مرور سنة قمرية كاملة) على المال المدخر البالغ للنصاب. فالمرتب الذي يُنفق في الحاجات المعيشية الأساسية لا زكاة فيه باتفاق الفقهاء، وإنما تجب الزكاة فيما يفيض ويُدخر ويبلغ النصاب ويمر عليه عام كامل.',
      },
      {
        'q': 'ما هو النصاب الشرعي للزكاة وكيف يُحسب؟',
        'a': 'النصاب الشرعي هو الحد الأدنى من المال الذي إذا ملكه المسلم وجبت فيه الزكاة، وهو ما يعادل قيمة 85 جراماً من الذهب الخالص (عيار 24) أو ما يعادلها من عيار 21 (نحو 97.14 جرام). يُحسب بضرب وزن الذهب بسعر الجرام في يوم إخراج الزكاة.',
      },
      {
        'q': 'إذا كان مرتبي يقل عن النصاب، فماذا أفعل؟',
        'a': 'تكون في سعة وراحة، فالشريعة لم توجب عليك الزكاة. ولكن يُستحب لك إخراج صدقة تطوعية يسيرة شهرياً (مثل 1% أو 2% من الراتب أو ما تيسر)، فإن الصدقة تطهر النفس وتبارك في الرزق القليل وتدفع البلاء: «مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ».',
      },
      {
        'q': 'هل تُخصم الديون والأقساط قبل حساب الزكاة؟',
        'a': 'تُخصم الديون الفورية الحالية المستحقة عليك التي يلزمك سدادها حالاً. أما الأقساط المؤجلة لسنوات مقبلة (كأقساط العقار أو السيارة) فلا يُخصم منها إلا قسط العام الحالي فقط عند جمهور الفقهاء المعاصرين.',
      },
      {
        'q': 'من هم المستحقون للزكاة (المصارف الثمانية)؟',
        'a': 'حدد القرآن الكريم مصارف الزكاة في قوله تعالى: «إِنَّمَا الصَّدَقَاتُ لِلْفُقَرَاءِ وَالْمَسَاكِينِ وَالْعَامِلِينَ عَلَيْهَا وَالْمُؤَلَّفَةِ قُلُوبُهُمْ وَفِي الرِّقَابِ وَالْغَارِمِينَ وَفِي سَبِيلِ اللَّهِ وَابْنِ السَّبِيلِ فَرِيضَةً مِّنَ اللَّهِ وَاللَّهُ عَلِيمٌ حَكِيمٌ» [التوبة: 60].',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_rounded, color: colors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الضوابط الفقهية والأسئلة الشائعة حول الزكاة',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...faqs.map((faq) => _buildFaqTile(colors, faq['q']!, faq['a']!)),
        ],
      ),
    );
  }

  Widget _buildFaqTile(AppColorsExtension colors, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          collapsedBackgroundColor: colors.bg,
          backgroundColor: colors.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          title: Text(
            question,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12,
                color: colors.textMuted,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
