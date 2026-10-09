import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/repositories/gharib_quran_repository.dart';
import '../../../card_studio/presentation/views/card_studio_view.dart';
import '../../../mushaf/presentation/utils/mushaf_utils.dart';
import '../../../mushaf/presentation/views/mushaf_view.dart';

/// Interactive daily Quranic vocabulary card on the Home screen.
class DailyQuranWordCard extends StatelessWidget {
  const DailyQuranWordCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;
    final word = GharibQuranRepository.instance.getDailyWord();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AppCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.menu_book_rounded, color: colors.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'كلمة قرآنية ومعناها',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'من معجم غريب القرآن • تدبر المفردات',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'جذر: ${word.root}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Word and meaning banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14241C) : const Color(0xFFF7FAF7),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '﴿ ${word.word} ﴾',
                        style: TextStyle(
                          fontFamily: 'uthman',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : colors.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'سورة ${word.surahName} [${toArabicDigits(word.ayahNumber)}]',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    word.meaning,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Ayah snippet
            Text(
              'قال تعالى: ﴿ ${word.ayahSnippet} ﴾',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'uthman',
                fontSize: 14.5,
                height: 1.6,
                color: colors.text,
              ),
            ),

            if (word.linguisticBenefit != null) ...[
              const SizedBox(height: 8),
              Text(
                word.linguisticBenefit!,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppHaptics.selection();
                      Get.to(() => MushafView(initialPage: word.pageNumber));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.primary.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: Icon(Icons.auto_stories_rounded, size: 16, color: colors.primary),
                    label: Text(
                      'المصحف (صـ ${toArabicDigits(word.pageNumber)})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AppHaptics.selection();
                      Get.to(() => CardStudioView(
                            initialText: word.ayahSnippet,
                            initialSurahName: 'سورة ${word.surahName}',
                            initialAyahNumber: word.ayahNumber,
                            initialTafsir: '${word.word}: ${word.meaning}',
                            initialSource: 'معجم غريب القرآن',
                          ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.palette_rounded, size: 16),
                    label: const Text(
                      'تصميم بطاقة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
