import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/core/util/widgets/islamic_quote_card_generator_view.dart';
import 'package:quran_app_android/features/bookmarks/presentation/controllers/bookmarks_controller.dart';
import 'package:quran_app_android/features/bookmarks/presentation/views/bookmarks_view.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_bookmark_model.dart';
import 'package:quran_app_android/features/hadith/data/repositories/hadith_bookmark_repository.dart';

class HomeHadithMemorizationCard extends StatefulWidget {
  const HomeHadithMemorizationCard({super.key});

  @override
  State<HomeHadithMemorizationCard> createState() =>
      _HomeHadithMemorizationCardState();
}

class _HomeHadithMemorizationCardState extends State<HomeHadithMemorizationCard> {
  final HadithBookmarkRepository _repo = HadithBookmarkRepository();
  List<HadithBookmarkModel> _bookmarks = [];
  int _memorizedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.getAllBookmarks();
    final memCount = list.where((e) => e.isMemorized).length;
    if (mounted) {
      setState(() {
        _bookmarks = list;
        _memorizedCount = memCount;
        _isLoading = false;
      });
    }
  }

  void _openBookmarksHadithTab() {
    Get.to(() => const BookmarksView())?.then((_) => _load());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<BookmarksController>()) {
        final ctrl = Get.find<BookmarksController>();
        if (ctrl.tabController.length >= 4) {
          ctrl.tabController.animateTo(3);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final hasBookmarks = _bookmarks.isNotEmpty;
    final latestHadith = hasBookmarks ? _bookmarks.first : null;

    return AppCard(
      variant: AppCardVariant.elevated,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: AppSpacing.paddingLg,
      backgroundColor: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5C4A).withOpacity(0.12),
                  borderRadius: AppRadius.borderMd,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF0F5C4A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حفظ الأحاديث النبوية',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTypography.uiFont,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasBookmarks
                          ? 'المحفوظ: ${_bookmarks.length} حديث  •  المتقن: $_memorizedCount ⭐'
                          : 'تعلّم وافر حفظ حديث شريف اليوم',
                      style: textTheme.bodySmall?.copyWith(
                        color: hasBookmarks
                            ? const Color(0xFFD4AF37)
                            : colors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openBookmarksHadithTab,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'عرض الكل',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content body
          if (hasBookmarks && latestHadith != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: AppRadius.borderMd,
                border: Border.all(
                  color: colors.divider.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '«${latestHadith.chapterName}»',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F5C4A),
                        ),
                      ),
                      const Spacer(),
                      if (latestHadith.isMemorized)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'تم الحفظ ⭐',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '«${latestHadith.text}»',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: AppTypography.hadithFont,
                      fontSize: 13.5,
                      height: 1.7,
                      color: colors.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.primary.withOpacity(0.4)),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderSm,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      Get.to(() => IslamicQuoteCardGeneratorView(
                            quoteText: latestHadith.text,
                            categoryTitle: 'حديث نبوي شريف',
                            source:
                                '${latestHadith.chapterName} • ${latestHadith.source}',
                            itemNumber: 'حديث رقم ${latestHadith.hadithNumber}',
                          ));
                    },
                    icon: const Icon(Icons.palette_outlined,
                        size: 16, color: Color(0xFF0F5C4A)),
                    label: const Text(
                      'مشاركة كصورة',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderSm,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => Get.toNamed(AppRoutes.sectionHadith),
                    icon: const Icon(Icons.library_books_rounded, size: 16),
                    label: const Text(
                      'تصفح الأحاديث',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: AppRadius.borderMd,
              ),
              child: Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '«نَضَّرَ اللَّهُ امْرَأً سَمِعَ مِنَّا حَدِيثًا فَحَفِظَهُ حَتَّى يُبَلِّغَهُ»',
                      style: TextStyle(
                        fontFamily: AppTypography.hadithFont,
                        fontSize: 13,
                        color: colors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderSm,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => Get.toNamed(AppRoutes.sectionHadith),
              icon: const Icon(Icons.star_rounded, size: 18),
              label: const Text(
                'ابدأ تصفح وحفظ الأحاديث النبوية',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
