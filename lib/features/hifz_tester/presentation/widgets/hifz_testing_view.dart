import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/app_card.dart';
import '../controllers/hifz_tester_controller.dart';
import '../../data/models/hifz_test_models.dart';

class HifzTestingView extends StatelessWidget {
  final HifzTesterController controller;

  const HifzTestingView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Obx(() {
      final question = controller.currentQuestion;
      if (question == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final currentIndex = controller.currentQuestionIndex.value;
      final total = controller.questions.length;
      final progress = (currentIndex + 1) / total;
      final isLastQuestion = currentIndex == total - 1;

      return Column(
        children: [
          // Top Progress Header
          _buildTopBar(context, currentIndex, total, progress, colors),

          // Scrollable Question & Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Card
                  _buildQuestionCard(context, question, colors),
                  const SizedBox(height: 16),

                  // Prompt Text
                  Text(
                    'اختر الإجابة الصحيحة:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Options
                  _buildOptions(context, question, colors),
                  const SizedBox(height: 16),

                  // Explanation / Tafsir Reveal
                  if (controller.isAnswerRevealed.value)
                    _buildExplanationCard(context, question, colors),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Bar (Next / Finish button)
          if (controller.isAnswerRevealed.value)
            _buildBottomActionBar(context, isLastQuestion, colors),
        ],
      );
    });
  }

  Widget _buildTopBar(
    BuildContext context,
    int currentIndex,
    int total,
    double progress,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                tooltip: 'إنهاء الاختبار',
                onPressed: () => _showExitConfirmation(context),
              ),

              const SizedBox(width: 4),

              Text(
                'السؤال ${currentIndex + 1} من $total',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              // Streak badge
              Obx(() {
                final streak = controller.streak.value;
                if (streak < 2) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Timer badge
              Obx(() {
                final sec = controller.elapsedSeconds.value;
                final m = (sec ~/ 60).toString().padLeft(2, '0');
                final s = (sec % 60).toString().padLeft(2, '0');
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$m:$s',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    HifzQuestion question,
    AppColorsExtension colors,
  ) {
    final isDark = colors.isDark;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(question.mode.icon, size: 14, color: colors.accent),
                    const SizedBox(width: 4),
                    Text(
                      question.mode.titleAr,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'سورة ${question.surahName} [${question.ayahNumber}]',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            question.prompt,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16251E) : const Color(0xFFF7FAF7),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Text(
              question.displayText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppTypography.quranFont,
                fontFamilyFallback: AppTypography.fallbackFonts,
                fontSize: 20,
                height: 1.9,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1B3B2B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(
    BuildContext context,
    HifzQuestion question,
    AppColorsExtension colors,
  ) {
    final letters = ['أ', 'ب', 'ج', 'د'];

    return Column(
      children: List.generate(question.options.length, (index) {
        final optionText = question.options[index];
        final letter = index < letters.length ? letters[index] : '';

        return Obx(() {
          final isRevealed = controller.isAnswerRevealed.value;
          final selectedIdx = controller.selectedAnswerIndex.value;
          final isCorrect = index == question.correctAnswerIndex;
          final isSelected = index == selectedIdx;

          Color borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.4);
          Color bgColor = Theme.of(context).cardColor;
          Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
          Widget? trailingIcon;

          if (isRevealed) {
            if (isCorrect) {
              borderColor = Colors.green.shade600;
              bgColor = Colors.green.withValues(alpha: 0.12);
              textColor = Colors.green.shade800;
              trailingIcon = const Icon(Icons.check_circle_rounded, color: Colors.green);
            } else if (isSelected) {
              borderColor = Colors.red.shade400;
              bgColor = Colors.red.withValues(alpha: 0.12);
              textColor = Colors.red.shade800;
              trailingIcon = const Icon(Icons.cancel_rounded, color: Colors.red);
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: isRevealed ? null : () => controller.selectOption(index),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: borderColor, width: isRevealed && (isCorrect || isSelected) ? 2 : 1),
                  boxShadow: [
                    if (!isRevealed)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isRevealed && isCorrect
                            ? Colors.green
                            : (isRevealed && isSelected ? Colors.red : colors.primary.withValues(alpha: 0.1)),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isRevealed && (isCorrect || isSelected) ? Colors.white : colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        optionText,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: AppTypography.quranFont,
                          fontFamilyFallback: AppTypography.fallbackFonts,
                          fontSize: optionText.split(' ').length > 2 ? 16 : 19,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.7,
                        ),
                      ),
                    ),

                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      trailingIcon,
                    ],
                  ],
                ),
              ),
            ),
          );
        });
      }),
    );
  }

  Widget _buildExplanationCard(
    BuildContext context,
    HifzQuestion question,
    AppColorsExtension colors,
  ) {
    final isDark = colors.isDark;
    final isCorrect = controller.selectedAnswerIndex.value == question.correctAnswerIndex;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? (isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF2E1919) : const Color(0xFFFFEBEE)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCorrect ? Colors.green.shade400 : Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: isCorrect ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'أحسنت! إجابة صحيحة وثابتة' : 'الإجابة الصحيحة هي:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCorrect ? Colors.green.shade800 : Colors.red.shade900,
                ),
              ),
            ],
          ),

          if (!isCorrect) ...[
            const SizedBox(height: 6),
            Text(
              '﴿ ${question.correctAnswer} ﴾',
              style: TextStyle(
                fontFamily: 'uthman',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],

          if (question.ruleExplanation != null && question.ruleExplanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 16, color: colors.accent),
                const SizedBox(width: 6),
                Text(
                  'ضابط الحفظ والبيان:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              question.ruleExplanation!,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    bool isLastQuestion,
    AppColorsExtension colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: controller.nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: Icon(
              isLastQuestion ? Icons.workspace_premium_rounded : Icons.arrow_forward_rounded,
            ),
            label: Text(
              isLastQuestion ? 'عرض النتيجة النهائية' : 'السؤال التالي',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الاختبار؟'),
        content: const Text('هل أنت متأكد من إنهاء جلسة اختبار الحفظ الحالية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('متابعة الاختبار'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.returnToSetup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إنهاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
