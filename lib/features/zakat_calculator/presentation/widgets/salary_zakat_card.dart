import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../data/models/salary_zakat_model.dart';

class SalaryZakatCard extends StatelessWidget {
  final SalaryZakatResult result;
  final VoidCallback onCopy;

  const SalaryZakatCard({
    super.key,
    required this.result,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (result.amountEntered <= 0) {
      return _buildEmptyPromptCard(colors);
    }

    if (result.isZakatObligatory) {
      return _buildObligatoryZakatCard(colors);
    }

    return _buildBelowNisabCard(colors);
  }

  Widget _buildEmptyPromptCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_rounded, size: 40, color: colors.primary),
          const SizedBox(height: 10),
          Text(
            'حاسبة زكاة المرتب والمدخرات',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أدخل قيمة مرتبك أو مدخراتك وسعر جرام الذهب لتحديد ما إذا بلغت النصاب الشرعي أم لا، واحتساب الزكاة أو مقترح الصدقة الشهرية المناسب.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.5,
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObligatoryZakatCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09261E), Color(0xFF144D3E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF09261E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.verified_rounded, color: Color(0xFFD4AF37), size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'بلغ مالك النصاب الشرعي',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE8D08D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                onPressed: onCopy,
                tooltip: 'نسخ النتيجة',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'مقدار الزكاة الواجب إخراجها شرعاً (2.5% = ربع العُشر):',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    result.zakatDue.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'وحدة نقدية',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _buildMetricRow(
                  'صافي الوعاء الخاضع للزكاة:',
                  '${result.netWealthSubjectToZakat.toStringAsFixed(0)} جـ',
                ),
                const SizedBox(height: 6),
                _buildMetricRow(
                  'قيمة النصاب (${result.goldKarat.nisabGrams.toStringAsFixed(1)} جم ذهب):',
                  '${result.nisabThresholdAmount.toStringAsFixed(0)} جـ',
                ),
                const SizedBox(height: 6),
                _buildMetricRow(
                  'الفائض المتجاوز للنصاب:',
                  '+${(result.netWealthSubjectToZakat - result.nisabThresholdAmount).toStringAsFixed(0)} جـ',
                  valueColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '«خُذْ مِنْ أَمْوَالِهِمْ صَدَقَةً تُطَهِّرُهُمْ وَتُزَكِّيهِم بِهَا وَصَلِّ عَلَيْهِمْ إِنَّ صَلَاتَكَ سَكَنٌ لَّهُمْ» [التوبة: 103]',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBelowNisabCard(AppColorsExtension colors) {
    final progress = result.nisabProgressPercentage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A5F),
            const Color(0xFF162E4A),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.teal.shade300.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.spa_rounded, color: Colors.tealAccent, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'المال دون النصاب الشرعي',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                onPressed: onCopy,
                tooltip: 'نسخ النتيجة',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: Colors.tealAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'لا تجب عليك الزكاة شرعاً بحمد الله',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'مرتبك أو مدخراتك (${result.amountEntered.toStringAsFixed(0)} جـ) أقل من قيمة النصاب الشرعي البالغ (${result.nisabThresholdAmount.toStringAsFixed(0)} جـ)، وهو ما يعادل ${result.goldKarat.nisabGrams.toStringAsFixed(1)} جرام ذهب. الشريعة الإسلامية لا تكلف نفساً إلا وسعها، ولا زكاة عليك.',
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFont,
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Nisab Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'المتبقي لبلوغ النصاب: ${result.shortfallToNisab.toStringAsFixed(0)} جـ',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
