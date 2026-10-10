import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/services/app_haptics_service.dart';
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

    // Calculate active monthly amount
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFB8860B), size: 22),
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
                    const SizedBox(height: 2),
                    Text(
                      'الصدقة لا تشترط نصاباً، وتُبارك القليل وتدفع البلاء',
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
          const SizedBox(height: 12),

          // Prophetic Hadith Quote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.07),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB8860B), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'قال رسول الله ﷺ: «مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ»',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12,
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'اختر نسبة صدقة شهرية يسيرة من دخلك:',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),

          // 3 Balanced Proportion Tiles (Equal Height & Equal Styling)
          _buildSuggestionTile(
            colors: colors,
            choiceId: 1,
            badge: '1%',
            title: 'صدقة التيسير (1% من المرتب)',
            subtitle: 'مبلغ يسير جداً لا يُثقل نفقاتك',
            amount: result.suggestedCharity1Percent > 0 ? result.suggestedCharity1Percent : 30.0,
          ),
          const SizedBox(height: 8),

          _buildSuggestionTile(
            colors: colors,
            choiceId: 2,
            badge: '2%',
            title: 'صدقة النماء والبركة (2% من المرتب)',
            subtitle: 'قليل دائم خيرٌ من كثير منقطع',
            amount: result.suggestedCharity2Percent > 0 ? result.suggestedCharity2Percent : 60.0,
          ),
          const SizedBox(height: 8),

          _buildSuggestionTile(
            colors: colors,
            choiceId: 3,
            badge: '2.5%',
            title: 'صدقة ربع العُشر المستحبة',
            subtitle: 'تطوع مبارك يُماثل نسبة الزكاة',
            amount: result.suggestedCharity2HalfPercent > 0 ? result.suggestedCharity2HalfPercent : 75.0,
          ),
          const SizedBox(height: 14),

          // Equal-sized Preset Quick Amount Buttons
          Text(
            'أو حدد مبلغاً شهرياً ثابتاً تجود به نفسك:',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),

          // 5 EQUAL SIZED BUTTONS in a balanced Row (No scrolling, exact same size!)
          Row(
            children: [20.0, 50.0, 100.0, 200.0, 500.0].map((amt) {
              final isSelected = selectedChoice == 4 && customAmount == amt;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        AppHaptics.selection();
                        onSelectChoice(4);
                        onCustomAmountChanged(amt);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 42,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary : colors.bg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSelected ? colors.primary : colors.divider.withOpacity(0.5),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${amt.toStringAsFixed(0)} جـ',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : colors.text,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Monthly vs Annual Impact Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.divider.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'صدقتك المقترحة شهرياً:',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12.5,
                          color: colors.text,
                        ),
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
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${yearlyTotal.toStringAsFixed(0)} وحدة في السنة 🌟',
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 13.5,
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

          // Action Button: Schedule Monthly Reminder
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              onPressed: () {
                AppHaptics.selection();
                onOpenReminders();
              },
              icon: const Icon(Icons.alarm_on_rounded, size: 18),
              label: const Text(
                'ضبط تذكير شهري بالصدقة في التطبيق',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
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
    required String badge,
    required String title,
    required String subtitle,
    required double amount,
  }) {
    final isSelected = selectedChoice == choiceId;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          AppHaptics.selection();
          onSelectChoice(choiceId);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary.withOpacity(0.08) : colors.bg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isSelected ? colors.primary : colors.divider.withOpacity(0.4),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Badge
              Container(
                width: 40,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : colors.divider.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : colors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Subtitle
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
                    const SizedBox(height: 1),
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

              // Amount
              Text(
                '${amount.toStringAsFixed(0)} جـ',
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colors.primary : const Color(0xFFB8860B),
                ),
              ),
              const SizedBox(width: 8),

              // Radio / Check icon
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: isSelected ? colors.primary : colors.divider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
