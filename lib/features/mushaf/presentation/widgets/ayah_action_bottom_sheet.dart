import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/util/share_helper.dart';
import '../../../../core/data/models/ayah_entity.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../controllers/mushaf_controller.dart';
import '../models/mushaf_theme_model.dart';
import '../utils/mushaf_utils.dart';
import '../../../card_studio/presentation/views/card_studio_view.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../../tafsser/data/tafsir_repository.dart';
import '../../../../core/util/routes/routes.dart';
import '../../../gharib_quran/data/models/quran_vocabulary_word.dart';
import '../../../gharib_quran/data/repositories/gharib_quran_repository.dart';
import '../../../gharib_quran/presentation/widgets/page_vocabulary_bottom_sheet.dart';

/// Interactive, exquisitely organized action sheet displayed when an Ayah
/// is tapped or long-pressed in the Mushaf.
///
/// Features clean, modern 2-tab organization:
/// 1. 📖 التفسير والبيان (Tafsir & Meanings - with selectable sources)
/// 2. 🔖 الحفظ والعلامات (Bookmark & Memorization tracking)
/// With persistent Ayah header card, quick action toolbar, and zero clutter.
class AyahActionBottomSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final String surahName;
  final AyahEntity? ayahEntity;
  final MushafThemeConfig theme;
  final VoidCallback onClose;

  const AyahActionBottomSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.surahName,
    required this.ayahEntity,
    required this.theme,
    required this.onClose,
  });

  @override
  State<AyahActionBottomSheet> createState() => _AyahActionBottomSheetState();
}

class _AyahActionBottomSheetState extends State<AyahActionBottomSheet>
    with SingleTickerProviderStateMixin {
  final MushafController _controller = Get.find<MushafController>();
  late final TabController _tabController;
  late final TextEditingController _noteController;

  bool _isBookmarked = false;
  BookmarkColor _selectedColor = BookmarkColor.gold;
  MemorizeStatus? _selectedStatus;

  TafsirSource _selectedTafsir = TafsirSource.muyassar;
  String? _loadedTafsirText;
  bool _isLoadingTafsir = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    final bookmark = _controller.getAyahBookmark(widget.surahNumber, widget.ayahNumber);
    final memorized = _controller.getAyahMemorized(widget.surahNumber, widget.ayahNumber);

    _isBookmarked = bookmark != null;
    _selectedColor = bookmark?.color ?? BookmarkColor.gold;
    _selectedStatus = memorized?.status;
    _noteController = TextEditingController(text: bookmark?.note ?? '');
    _loadedTafsirText = widget.ayahEntity?.tafsirMuyassar;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _changeTafsir(TafsirSource source) async {
    if (source == _selectedTafsir && _loadedTafsirText != null) return;
    AppHaptics.selection();
    setState(() {
      _selectedTafsir = source;
      _isLoadingTafsir = true;
    });

    final text = await TafsirRepository.instance.getAyahTafsir(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayahNumber,
      source: source,
    );

    if (mounted) {
      setState(() {
        _loadedTafsirText = text;
        _isLoadingTafsir = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final note = _noteController.text.trim();
    if (_isBookmarked) {
      AppHaptics.selection();
      await _controller.removeAyahBookmark(
        widget.surahNumber,
        widget.ayahNumber,
        widget.pageNumber,
      );
      setState(() => _isBookmarked = false);
      _showFeedback('تمت إزالة العلامة المرجعية للآية');
    } else {
      AppHaptics.itemCompleted();
      _controller.selectedAyahColor.value = _selectedColor;
      await _controller.setAyahBookmark(
        surah: widget.surahNumber,
        ayah: widget.ayahNumber,
        page: widget.pageNumber,
        color: _selectedColor,
        note: note.isNotEmpty ? note : null,
      );
      setState(() => _isBookmarked = true);
      _showFeedback('تم حفظ العلامة المرجعية للآية');
    }
  }

  Future<void> _updateColor(BookmarkColor color) async {
    AppHaptics.selection();
    setState(() {
      _selectedColor = color;
      _isBookmarked = true;
    });
    _controller.selectedAyahColor.value = color;
    final note = _noteController.text.trim();
    await _controller.setAyahBookmark(
      surah: widget.surahNumber,
      ayah: widget.ayahNumber,
      page: widget.pageNumber,
      color: color,
      note: note.isNotEmpty ? note : null,
    );
    _showFeedback('تم تحديد اللون: ${color.labelAr}');
  }

  Future<void> _updateMemorizeStatus(MemorizeStatus? status) async {
    if (status == MemorizeStatus.memorized) {
      AppHaptics.cycleCompleted();
    } else {
      AppHaptics.selection();
    }
    setState(() => _selectedStatus = status);
    await _controller.setAyahMemorizeStatus(
      surah: widget.surahNumber,
      ayah: widget.ayahNumber,
      page: widget.pageNumber,
      status: status,
    );
    final msg = status == null
        ? 'تم إلغاء حالة الحفظ للآية'
        : 'تم تحديد حالة الحفظ: ${status.labelAr}';
    _showFeedback(msg);
  }

  Future<void> _saveNote() async {
    HapticFeedback.lightImpact();
    final note = _noteController.text.trim();
    setState(() => _isBookmarked = true);
    await _controller.setAyahBookmark(
      surah: widget.surahNumber,
      ayah: widget.ayahNumber,
      page: widget.pageNumber,
      color: _selectedColor,
      note: note.isNotEmpty ? note : null,
    );
    _showFeedback('تم حفظ الملاحظة بنجاح');
  }

  void _copyAyah() {
    AppHaptics.selection();
    final text = widget.ayahEntity?.textAr ?? '';
    final copyContent = '﴿$text﴾ [سورة ${widget.surahName}: ${widget.ayahNumber}]';
    Clipboard.setData(ClipboardData(text: copyContent));
    _showFeedback('تم نسخ الآية الكريمة إلى الحافظة');
  }

  void _shareAyah() {
    AppHaptics.selection();
    final text = widget.ayahEntity?.textAr ?? '';
    final tafsir = _loadedTafsirText ?? widget.ayahEntity?.tafsirMuyassar;
    final shareContent = StringBuffer()
      ..writeln('﴿ $text ﴾')
      ..writeln('— سورة ${widget.surahName} (الآية ${toArabicDigits(widget.ayahNumber)})');

    if (tafsir != null && tafsir.isNotEmpty) {
      shareContent
        ..writeln()
        ..writeln('تفسير الآية (${_selectedTafsir.title}):')
        ..writeln(tafsir);
    }

    Share.share(
      shareContent.toString(),
      sharePositionOrigin: getSharePositionOrigin(context),
    );
  }

  void _openImageCard() {
    AppHaptics.selection();
    final ayahText = widget.ayahEntity?.textAr ?? 'آية ${widget.ayahNumber}';
    final tafsirText = _loadedTafsirText ?? widget.ayahEntity?.tafsirMuyassar;
    Get.to(() => CardStudioView(
      initialText: ayahText,
      initialSurahName: 'سورة ${widget.surahName}',
      initialAyahNumber: widget.ayahNumber,
      initialTafsir: tafsirText,
    ));
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTypography.uiFont, fontSize: 13.5),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final arabicText = widget.ayahEntity?.textAr ?? '';
    final ayahWords = GharibQuranRepository.instance.getWordsForAyah(
      widget.surahNumber,
      widget.ayahNumber,
    );

    final hasActiveBookmarkOrMemorize = _isBookmarked || _selectedStatus != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 24.0,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle
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

          // 2. Header Bar: Ayah Reference Badge & Action Icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ayah Reference Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.09),
                    borderRadius: AppRadius.borderFull,
                    border: Border.all(color: colors.primary.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 15, color: colors.primary),
                      AppSpacing.horizontalXs,
                      Text(
                        'سورة ${widget.surahName}  •  آية ${toArabicDigits(widget.ayahNumber)}  •  صـ ${toArabicDigits(widget.pageNumber)}',
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),

                // Top right/left quick buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined, size: 21.0),
                      color: colors.primary,
                      tooltip: 'مشاركة كصورة',
                      onPressed: _openImageCard,
                    ),
                    IconButton(
                      icon: const Icon(Icons.psychology_alt_outlined, size: 21.0),
                      color: colors.primary,
                      tooltip: 'اختبر حفظك في السورة',
                      onPressed: () {
                        Navigator.of(context).pop();
                        Get.toNamed(
                          AppRoutes.hifzTester,
                          arguments: {'surahId': widget.ayahEntity?.surahId},
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22.0),
                      color: colors.textMuted,
                      tooltip: 'إغلاق',
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Compact Ayah Text Card (Centered, dignified Quranic script)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 135.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: colors.divider.withOpacity(0.8)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Text(
                      '﴿ $arabicText ﴾',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: AppTypography.decorativeFont,
                        fontSize: 18.5,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                        height: 1.8,
                      ),
                    ),
                    if (ayahWords.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.spellcheck_rounded, size: 14.0, color: colors.accent),
                              const SizedBox(width: 4.0),
                              Text(
                                'مفردات الآية:',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: colors.accent,
                                ),
                              ),
                            ],
                          ),
                          ...ayahWords.map((word) => InkWell(
                            onTap: () {
                              AppHaptics.selection();
                              _tabController.animateTo(1);
                            },
                            borderRadius: BorderRadius.circular(6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(color: colors.primary.withOpacity(0.35)),
                              ),
                              child: Text(
                                word.word,
                                style: TextStyle(
                                  fontFamily: 'uthman',
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 4. Modern Segmented Tab Switcher (التفسير vs المفردات vs الحفظ والعلامات)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Container(
              height: 44.0,
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: colors.divider.withOpacity(0.6)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.28),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: colors.textMuted,
                labelStyle: const TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                tabs: [
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_stories_rounded, size: 15.0),
                        SizedBox(width: 4),
                        Text('التفسير'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.spellcheck_rounded, size: 15.0),
                        const SizedBox(width: 4),
                        const Text('المفردات'),
                        if (ayahWords.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              '${ayahWords.length}',
                              style: const TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_added_rounded, size: 15.0),
                        const SizedBox(width: 4),
                        const Text('الحفظ'),
                        if (hasActiveBookmarkOrMemorize) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: _isBookmarked ? _selectedColor.color : colors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Scrollable Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildTafsirTab(colors, textTheme),
                _buildVocabularyTab(colors, textTheme, ayahWords),
                _buildBookmarkAndMemorizeTab(colors, textTheme),
              ],
            ),
          ),

          const Divider(height: 1.0),

          // 6. Fixed Bottom Action Toolbar (نسخ، مشاركة، صورة، علامة سريعة)
          _buildBottomActionToolbar(colors),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4.0),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: التفسير والبيان
  // -------------------------------------------------------------
  Widget _buildTafsirTab(AppColorsExtension colors, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tafsir Sources Selector (Horizontal Pills)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: TafsirSource.values.map((src) {
                final isSelected = _selectedTafsir == src;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: InkWell(
                    onTap: () => _changeTafsir(src),
                    borderRadius: BorderRadius.circular(10.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary.withOpacity(0.12)
                            : colors.bg,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isSelected
                              ? colors.primary
                              : colors.divider.withOpacity(0.6),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.check_circle_rounded, size: 14, color: colors.primary),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            src.title,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? colors.primary : colors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          AppSpacing.verticalSm,

          // Tafsir Content Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.divider.withOpacity(0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTafsir.description,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                    if (_isLoadingTafsir)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                  ],
                ),
                const Divider(height: 18.0),

                // Tafsir Body
                SelectableText(
                  _loadedTafsirText != null && _loadedTafsirText!.isNotEmpty
                      ? _loadedTafsirText!
                      : 'جارٍ جلب التفسير من قاعدة البيانات...',
                  textDirection: TextDirection.rtl,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: AppTypography.uiFont,
                    color: colors.text,
                    fontSize: 15.0,
                    height: 1.85,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: غريب المفردات
  // -------------------------------------------------------------
  Widget _buildVocabularyTab(
    AppColorsExtension colors,
    TextTheme textTheme,
    List<QuranVocabularyWord> ayahWords,
  ) {
    final pageWords = GharibQuranRepository.instance.getWordsForPage(widget.pageNumber);
    final nonAyahPageWords = pageWords.where((pw) => !ayahWords.any((aw) => aw.id == pw.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Words of this specific Ayah (if any)
          if (ayahWords.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: colors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars_rounded, color: colors.primary, size: 18.0),
                  const SizedBox(width: 8.0),
                  Text(
                    'مفردات هذه الآية الكريمة (${toArabicDigits(ayahWords.length)})',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            ...ayahWords.map((word) => _buildVocabularyWordItem(colors, textTheme, word, isDirectAyah: true)),
            const SizedBox(height: 12.0),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: colors.divider.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.accent, size: 20.0),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'ألفاظ هذه الآية جلية وميسرة. إليك مفردات الصفحة ${toArabicDigits(widget.pageNumber)} للتدبر والبيان:',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12.5,
                        color: colors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
          ],

          // Section 2: Page Words
          if (nonAyahPageWords.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مفردات الصفحة (صـ ${toArabicDigits(widget.pageNumber)})',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    PageVocabularyBottomSheet.show(
                      context,
                      pageNumber: widget.pageNumber,
                      surahName: widget.surahName,
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 14.0),
                  label: const Text('عرض معجم الصفحة', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            ...nonAyahPageWords.take(4).map(
                  (word) => _buildVocabularyWordItem(colors, textTheme, word, isDirectAyah: false),
                ),
          ],
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildVocabularyWordItem(
    AppColorsExtension colors,
    TextTheme textTheme,
    QuranVocabularyWord word, {
    required bool isDirectAyah,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(13.0),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDirectAyah
              ? colors.primary.withOpacity(0.35)
              : colors.divider.withOpacity(0.7),
          width: isDirectAyah ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '﴿ ${word.word} ﴾',
                style: TextStyle(
                  fontFamily: 'uthman',
                  fontSize: 19.0,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  'جذر: ${word.root}',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: colors.accent,
                  ),
                ),
              ),
              if (!isDirectAyah) ...[
                const SizedBox(width: 5.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    'آية ${toArabicDigits(word.ayahNumber)}',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.arrow_right_rounded, color: colors.accent, size: 19.0),
              const SizedBox(width: 4.0),
              Expanded(
                child: SelectableText(
                  word.meaning,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (word.linguisticBenefit != null) ...[
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: colors.accent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 15.0, color: colors.accent),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      word.linguisticBenefit!,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8.0),
          // Action Buttons: Copy Meaning & Share to Card Studio
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  AppHaptics.selection();
                  Clipboard.setData(ClipboardData(
                    text: '﴿${word.word}﴾: ${word.meaning} [سورة ${word.surahName}: ${word.ayahNumber}]',
                  ));
                  _showFeedback('تم نسخ معنى كلمة ${word.word}');
                },
                borderRadius: BorderRadius.circular(6.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 14.0, color: colors.textMuted),
                      const SizedBox(width: 4.0),
                      Text(
                        'نسخ المعنى',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.0,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              InkWell(
                onTap: () {
                  AppHaptics.selection();
                  Get.to(() => CardStudioView(
                    initialText: word.ayahSnippet,
                    initialSurahName: 'سورة ${word.surahName}',
                    initialAyahNumber: word.ayahNumber,
                    initialTafsir: '${word.word}: ${word.meaning}',
                    initialSource: 'معجم غريب القرآن',
                  ));
                },
                borderRadius: BorderRadius.circular(6.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.palette_outlined, size: 14.0, color: colors.accent),
                      const SizedBox(width: 4.0),
                      Text(
                        'تصميم بطاقة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: الحفظ والعلامات
  // -------------------------------------------------------------
  Widget _buildBookmarkAndMemorizeTab(AppColorsExtension colors, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SECTION: العلامة المرجعية (Color Pearls + Note)
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.borderMd,
              border: Border.all(
                color: _isBookmarked
                    ? _selectedColor.color.withOpacity(0.4)
                    : colors.divider.withOpacity(0.7),
                width: _isBookmarked ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                          size: 19.0,
                          color: _isBookmarked ? _selectedColor.color : colors.accent,
                        ),
                        AppSpacing.horizontalXs,
                        Text(
                          'العلامة المرجعية',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                      ],
                    ),
                    if (_isBookmarked)
                      InkWell(
                        onTap: _toggleBookmark,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 15, color: colors.error),
                              const SizedBox(width: 4),
                              Text(
                                'حذف العلامة',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  color: colors.error,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        'اضغط لاختيار لون وحفظ العلامة',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12.0),

                // 5 Luxury Color Pearls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: BookmarkColor.values.map((col) {
                    final isSelected = _isBookmarked && _selectedColor == col;
                    return GestureDetector(
                      onTap: () => _updateColor(col),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: col.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: isSelected ? 2.5 : 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: col.color.withOpacity(isSelected ? 0.6 : 0.25),
                                  blurRadius: isSelected ? 10.0 : 4.0,
                                  spreadRadius: isSelected ? 2.0 : 0.0,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check_rounded, size: 19.0, color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            col.labelAr,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 11.0,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? col.color : colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12.0),

                // Note Input Field
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    color: colors.text,
                    fontSize: 13.0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أضف تدبراً أو ملاحظة خاصة بهذه الآية...',
                    hintStyle: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      color: colors.textMuted.withOpacity(0.7),
                      fontSize: 12.0,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(color: colors.divider.withOpacity(0.6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(color: colors.divider.withOpacity(0.6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderSm,
                      borderSide: BorderSide(color: colors.primary, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.check_circle_outline_rounded, size: 20.0, color: colors.primary),
                      tooltip: 'حفظ الملاحظة',
                      onPressed: _saveNote,
                    ),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.verticalMd,

          // 2. SECTION: متابعة الحفظ (4 Status Options)
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.borderMd,
              border: Border.all(
                color: _selectedStatus != null
                    ? _selectedStatus!.badgeColor.withOpacity(0.4)
                    : colors.divider.withOpacity(0.7),
                width: _selectedStatus != null ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 19.0,
                      color: _selectedStatus != null ? _selectedStatus!.badgeColor : colors.primary,
                    ),
                    AppSpacing.horizontalXs,
                    Text(
                      'مستوى حفظ الآية',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                // Grid of 4 options
                Row(
                  children: [
                    // None (لم يُحدد)
                    Expanded(
                      child: _buildMemorizeOption(
                        label: 'لم يُحدد',
                        isSelected: _selectedStatus == null,
                        color: colors.textMuted,
                        icon: Icons.radio_button_unchecked_rounded,
                        onTap: () => _updateMemorizeStatus(null),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Learning (بيحفظ)
                    Expanded(
                      child: _buildMemorizeOption(
                        label: MemorizeStatus.learning.labelAr,
                        isSelected: _selectedStatus == MemorizeStatus.learning,
                        color: MemorizeStatus.learning.badgeColor,
                        icon: Icons.hourglass_top_rounded,
                        onTap: () => _updateMemorizeStatus(MemorizeStatus.learning),
                        colors: colors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Needs Review (يحتاج مراجعة)
                    Expanded(
                      child: _buildMemorizeOption(
                        label: MemorizeStatus.needsReview.labelAr,
                        isSelected: _selectedStatus == MemorizeStatus.needsReview,
                        color: MemorizeStatus.needsReview.badgeColor,
                        icon: Icons.replay_rounded,
                        onTap: () => _updateMemorizeStatus(MemorizeStatus.needsReview),
                        colors: colors,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Memorized (محفوظ)
                    Expanded(
                      child: _buildMemorizeOption(
                        label: MemorizeStatus.memorized.labelAr,
                        isSelected: _selectedStatus == MemorizeStatus.memorized,
                        color: MemorizeStatus.memorized.badgeColor,
                        icon: Icons.check_circle_rounded,
                        onTap: () => _updateMemorizeStatus(MemorizeStatus.memorized),
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildMemorizeOption({
    required String label,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 9.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.14) : colors.surface,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? color : colors.divider.withOpacity(0.6),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15.0, color: isSelected ? color : colors.textMuted),
            const SizedBox(width: 6.0),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : colors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. Fixed Bottom Action Toolbar (4 Equal Buttons)
  // -------------------------------------------------------------
  Widget _buildBottomActionToolbar(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          // 1. Copy
          Expanded(
            child: _buildToolbarButton(
              icon: Icons.copy_rounded,
              label: 'نسخ',
              onTap: _copyAyah,
              colors: colors,
            ),
          ),
          const SizedBox(width: 8.0),

          // 2. Share Text
          Expanded(
            child: _buildToolbarButton(
              icon: Icons.share_rounded,
              label: 'مشاركة',
              onTap: _shareAyah,
              colors: colors,
            ),
          ),
          const SizedBox(width: 8.0),

          // 3. Image Card
          Expanded(
            child: _buildToolbarButton(
              icon: Icons.photo_library_outlined,
              label: 'صورة',
              onTap: _openImageCard,
              colors: colors,
            ),
          ),
          const SizedBox(width: 8.0),

          // 4. Quick Bookmark Toggle (Primary accent)
          Expanded(
            child: InkWell(
              onTap: _toggleBookmark,
              borderRadius: AppRadius.borderMd,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: _isBookmarked ? _selectedColor.color : colors.primary,
                  borderRadius: AppRadius.borderMd,
                  boxShadow: [
                    BoxShadow(
                      color: (_isBookmarked ? _selectedColor.color : colors.primary).withOpacity(0.3),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                      size: 16.0,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      _isBookmarked ? 'محفوظة' : 'علامة',
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: colors.divider.withOpacity(0.7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.0, color: colors.text),
            const SizedBox(width: 5.0),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
