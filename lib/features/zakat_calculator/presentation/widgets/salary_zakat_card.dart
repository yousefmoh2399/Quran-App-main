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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.primary.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withOpacity(0.1),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, size: 28, color: colors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            'حاسبة زكاة المرتب والمدخرات',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أدخل قيمة مرتبك أو مدخراتك وسعر جرام الذهب لتحديد ما إذا بلغت النصاب الشرعي أم لا، واحتساب الزكاة الواجبة أو مقترح الصدقة الشهرية المناسب.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.5,
              color: colors.textMuted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObligatoryZakatCard(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09291E), Color(0xFF134839)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF09291E).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge & Copy Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded, color: Color(0xFFE8D08D), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'بلغ مالك النصاب الشرعي',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE8D08D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'نسخ',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.5,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'مقدار الزكاة الواجب إخراجها شرعاً (2.5% = ربع العُشر):',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              color: Colors.white70,
              fontSize: 12.5,
            ),
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
                      fontFamily: AppTypography.uiFont,
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
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Breakdown metrics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                _buildMetricRow(
                  'صافي الوعاء الخاضع للزكاة:',
                  '${result.netWealthSubjectToZakat.toStringAsFixed(0)} وحدة',
                ),
                const SizedBox(height: 6),
                _buildMetricRow(
                  'قيمة النصاب الشرعي (${result.goldKarat.nisabGrams.toStringAsFixed(1)} جم):',
                  '${result.nisabThresholdAmount.toStringAsFixed(0)} وحدة',
                ),
                const SizedBox(height: 6),
                _buildMetricRow(
                  'الفائض المتجاوز للنصاب:',
                  '+${(result.netWealthSubjectToZakat - result.nisabThresholdAmount).toStringAsFixed(0)} وحدة',
                  valueColor: const Color(0xFF81C784),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '«خُذْ مِنْ أَمْوَالِهِمْ صَدَقَةً تُطَهِّرُهُمْ وَتُزَكِّيهِم بِهَا وَصَلِّ عَلَيْهِمْ إِنَّ صَلَاتَكَ سَكَنٌ لَّهُمْ» [التوبة: 103]',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.uiFont,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge & Copy Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                          SizedBox(width: 5),
                          Text(
                            'المال دون النصاب الشرعي',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, color: colors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'نسخ',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.5,
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Friendly, comforting message
          Text(
            'لا تجب عليك الزكاة شرعاً بحمد الله',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'مرتبك أو مدخراتك (${result.amountEntered.toStringAsFixed(0)} وحدة) أقل من النصاب الشرعي المحدد بـ (${result.nisabThresholdAmount.toStringAsFixed(0)} وحدة)، وهو ما يعادل ${result.goldKarat.nisabGrams.toStringAsFixed(1)} جرام ذهب.\n\nالشريعة الإسلامية لا تكلف نفساً إلا وسعها ولا زكاة عليك، ولكن يمكنك إخراج صدقة تطوعية يسيرة بالقدر الذي يناسبك لزيادة البركة.',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.5,
              color: colors.textMuted,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),

          // Nisab Progress Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.divider.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'المتبقي لبلوغ النصاب: +${result.shortfallToNisab.toStringAsFixed(0)} وحدة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: colors.divider.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
              ],
            ),
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
            style: const TextStyle(
              fontFamily: AppTypography.uiFont,
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            color: valueColor,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
