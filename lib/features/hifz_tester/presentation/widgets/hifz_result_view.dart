import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/components/app_card.dart';
import '../controllers/hifz_tester_controller.dart';
import '../../data/models/hifz_test_models.dart';

class HifzResultView extends StatelessWidget {
  final HifzTesterController controller;

  const HifzResultView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Obx(() {
      final result = controller.lastResult.value;
      if (result == null) {
        return const Center(child: Text('لا توجد نتائج سابقة'));
      }

      final hasMistakes = result.incorrectQuestionIndices.isNotEmpty;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score Banner Card
            _buildScoreCard(context, result, colors),
            const SizedBox(height: 18),

            // Statistics Grid
            _buildStatsGrid(context, result, colors),
            const SizedBox(height: 20),

            // Action Buttons
            if (hasMistakes) ...[
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: controller.retryMistakes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(
                    'إعادة اختبار الأخطاء فقط (${result.wrongAnswers})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: controller.returnToSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'اختبار جديد',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: controller.openMutashabihatGuide,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              icon: Icon(Icons.auto_stories_rounded, color: colors.accent),
              label: Text(
                'تصفح دليل المتشابهات اللفظية',
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Questions Review Section
            Row(
              children: [
                Icon(Icons.fact_check_rounded, color: colors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'مراجعة الأسئلة وتثبيت الأجوبة:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuestionsReview(context, result, colors),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  Widget _buildScoreCard(
    BuildContext context,
    HifzTestResult result,
    AppColorsExtension colors,
  ) {
    final isDark = colors.isDark;
    final isPassed = result.accuracyPercentage >= 65;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed
              ? (isDark
                  ? [const Color(0xFF1E3A2F), const Color(0xFF10261E)]
                  : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)])
              : (isDark
                  ? [const Color(0xFF38231E), const Color(0xFF241512)]
                  : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)]),
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isPassed ? colors.accent : Colors.red.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isPassed ? colors.primary : Colors.red.shade700,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isPassed ? colors.primary : Colors.red).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              '${result.accuracyPercentage}%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            result.gradeTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPassed ? (isDark ? Colors.white : colors.primary) : Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            result.gradeDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    HifzTestResult result,
    AppColorsExtension colors,
  ) {
    final minutes = result.duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (result.duration.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        _buildStatCard(
          context,
          title: 'صحيحة',
          value: '${result.correctAnswers}',
          color: Colors.green,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          context,
          title: 'خاطئة',
          value: '${result.wrongAnswers}',
          color: Colors.red,
          icon: Icons.cancel_rounded,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          context,
          title: 'الوقت',
          value: '$minutes:$seconds',
          color: colors.accent,
          icon: Icons.timer_outlined,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsReview(
    BuildContext context,
    HifzTestResult result,
    AppColorsExtension colors,
  ) {
    return Column(
      children: List.generate(result.questions.length, (index) {
        final q = result.questions[index];
        final userChoiceIdx = index < result.userAnswers.length ? result.userAnswers[index] : -1;
        final isCorrect = userChoiceIdx == q.correctAnswerIndex;
        final userChoiceText = (userChoiceIdx >= 0 && userChoiceIdx < q.options.length)
            ? q.options[userChoiceIdx]
            : 'لم يُجب';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'سؤال ${index + 1}: ${q.mode.titleAr}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'سورة ${q.surahName} [${q.ayahNumber}]',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q.prompt,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    q.displayText,
                    style: const TextStyle(
                      fontFamily: 'uthman',
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (!isCorrect) ...[
                  Text(
                    'إجابتك: $userChoiceText',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  'الصواب: ${q.correctAnswer}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                if (q.ruleExplanation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    q.ruleExplanation!,
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}
