import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../data/models/salary_zakat_model.dart';

class CharitySuggestionCard extends StatelessWidget {
  final SalaryZakatResult result;
  final int selectedChoice;
  final double customAmount;
  final ValueChanged<int> onSelectChoice;
  final ValueChanged<double> onCustomAmountChanged;
  final VoidCallback onOpenReminders;

  const CharitySuggestionCard({
    super.key,
    required this.result,
    required this.selectedChoice,
    required this.customAmount,
    required this.onSelectChoice,
    required this.onCustomAmountChanged,
    required this.onOpenReminders,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Calculate currently active monthly charity
    final double activeMonthlyAmount;
    switch (selectedChoice) {
      case 1:
        activeMonthlyAmount = result.suggestedCharity1Percent > 0 ? result.suggestedCharity1Percent : 30.0;
        break;
      case 2:
        activeMonthlyAmount = result.suggestedCharity2Percent > 0 ? result.suggestedCharity2Percent : 60.0;
        break;
      case 3:
        activeMonthlyAmount = result.suggestedCharity2HalfPercent > 0 ? result.suggestedCharity2HalfPercent : 75.0;
        break;
      case 4:
      default:
        activeMonthlyAmount = customAmount > 0 ? customAmount : result.recommendedMonthlyAmount;
        break;
    }

    final yearlyTotal = activeMonthlyAmount * 12;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFB8860B), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'باب الصدقة والبركة المفتوح 🌿',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      'الصدقة لا تشترط نصاباً وتُبارك القليل وتدفع البلاء',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Prophetic Guidance Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F0),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: const Color(0xFFE8D8B8)),
            ),
            child: Row(
              children: const [
                Icon(Icons.format_quote_rounded, color: Color(0xFF8B6B1B), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'قال رسول الله ﷺ: «مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ، وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلَّا عِزًّا»',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12,
                      color: Color(0xFF4A3E1B),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'مقترحات صدقة شهرية يسيرة من مرتبك:',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 10),

          // Suggestion 1: 1% of salary
          _buildSuggestionTile(
            colors: colors,
            choiceId: 1,
            title: 'صدقة التيسير (1% من المرتب)',
            amount: result.suggestedCharity1Percent > 0 ? result.suggestedCharity1Percent : 30.0,
            subtitle: 'مبلغ يسير جداً لا يُثقل نفقاتك ويُدخل السرور على محتاج',
          ),
          const SizedBox(height: 8),

          // Suggestion 2: 2% of salary
          _buildSuggestionTile(
            colors: colors,
            choiceId: 2,
            title: 'صدقة النماء والبركة (2% من المرتب)',
            amount: result.suggestedCharity2Percent > 0 ? result.suggestedCharity2Percent : 60.0,
            subtitle: 'قليل دائم خيرٌ من كثير منقطع لزيادة الرزق ودفع السوء',
          ),
          const SizedBox(height: 8),

          // Suggestion 3: 2.5% of salary
          _buildSuggestionTile(
            colors: colors,
            choiceId: 3,
            title: 'صدقة ربع العُشر المستحبة (2.5%)',
            amount: result.suggestedCharity2HalfPercent > 0 ? result.suggestedCharity2HalfPercent : 75.0,
            subtitle: 'تطوع مبارك تقتدي فيه بنسبة الزكاة محبةً لله وتطهيراً للمال',
          ),
          const SizedBox(height: 12),

          // Quick preset buttons
          Text(
            'أو حدد مبلغاً شهرياً يسيراً تجود به نفسك:',
            style: TextStyle(fontSize: 12, color: colors.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [20.0, 50.0, 100.0, 200.0, 500.0].map((amt) {
                final isSelected = selectedChoice == 4 && customAmount == amt;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text('${amt.toStringAsFixed(0)} جـ'),
                    selected: isSelected,
                    selectedColor: colors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      onCustomAmountChanged(amt);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Impact calculation card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withOpacity(0.08),
                  colors.primary.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.primary.withOpacity(0.18)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'صدقتك المقترحة شهرياً:',
                        style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12.5, color: colors.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${activeMonthlyAmount.toStringAsFixed(0)} وحدة نقدية',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'أثر الصدقة التراكمي في العام:',
                        style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12.5, color: colors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${yearlyTotal.toStringAsFixed(0)} وحدة في السنة 🌟',
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8860B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Schedule Monthly Reminder Action
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: onOpenReminders,
            icon: const Icon(Icons.alarm_on_rounded, size: 20),
            label: const Text(
              'ضبط تذكير شهري بالصدقة في التطبيق',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile({
    required AppColorsExtension colors,
    required int choiceId,
    required String title,
    required double amount,
    required String subtitle,
  }) {
    final isSelected = selectedChoice == choiceId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => onSelectChoice(choiceId),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary.withOpacity(0.08) : colors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? colors.primary : colors.divider.withOpacity(0.6),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Radio<int>(
                value: choiceId,
                groupValue: selectedChoice,
                activeColor: colors.primary,
                onChanged: (val) {
                  if (val != null) onSelectChoice(val);
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${amount.toStringAsFixed(0)} جـ',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colors.primary : const Color(0xFFB8860B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
