import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/components/app_card.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../../mushaf/presentation/utils/mushaf_utils.dart';
import '../../data/models/quran_vocabulary_word.dart';
import '../../data/repositories/gharib_quran_repository.dart';

/// Modal bottom sheet displaying the key vocabulary and rare words for a specific Mushaf page.
class PageVocabularyBottomSheet extends StatelessWidget {
  final int pageNumber;
  final String surahName;

  const PageVocabularyBottomSheet({
    super.key,
    required this.pageNumber,
    required this.surahName,
  });

  static Future<void> show(
    BuildContext context, {
    required int pageNumber,
    required String surahName,
  }) {
    AppHaptics.selection();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PageVocabularyBottomSheet(
        pageNumber: pageNumber,
        surahName: surahName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final words = GharibQuranRepository.instance.getWordsForPage(pageNumber);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10.0, bottom: 6.0),
              width: 44.0,
              height: 4.5,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(3.0),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.spellcheck_rounded, color: colors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'غريب مفردات الصفحة ${toArabicDigits(pageNumber)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        surahName.isNotEmpty ? 'سورة $surahName • معجم السراج في غريب القرآن' : 'معجم غريب القرآن المعتمد',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Vocabulary List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              itemCount: words.length,
              itemBuilder: (context, index) {
                return _buildWordCard(context, words[index], colors);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(
    BuildContext context,
    QuranVocabularyWord word,
    AppColorsExtension colors,
  ) {
    final isDark = colors.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Word header & root badge
            Row(
              children: [
                // Quranic Word in Uthmanic Script
                Text(
                  '﴿ ${word.word} ﴾',
                  style: TextStyle(
                    fontFamily: 'uthman',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : colors.primary,
                  ),
                ),
                const Spacer(),
                // Root badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'جذر: ${word.root}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Verse badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'آية ${word.ayahNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Contextual Meaning
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right_rounded, color: colors.accent, size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    word.meaning,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Ayah snippet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'موضع الآية: ﴿ ${word.ayahSnippet} ﴾ [${word.surahName}: ${word.ayahNumber}]',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'uthman',
                  color: colors.textMuted,
                ),
              ),
            ),

            if (word.linguisticBenefit != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF192B21) : const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 15, color: colors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        word.linguisticBenefit!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
