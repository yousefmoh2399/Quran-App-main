import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/data/arabic_normalizer.dart';
import '../../../../core/data/models/ayah_entity.dart';
import '../../../../core/data/models/surah_entity.dart';
import '../../../../core/data/repositories/quran_repository.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/empty_state.dart';
import '../../../mushaf/presentation/views/mushaf_view.dart';
import '../../../tafsser/presentation/views/tafseer_details_view.dart';

/// Fast, dedicated Quran search screen querying 6236 ayahs locally via FTS5/normalized text.
class QuranSearchView extends StatefulWidget {
  final int? initialSurahId;

  const QuranSearchView({super.key, this.initialSurahId});

  @override
  State<QuranSearchView> createState() => _QuranSearchViewState();
}

class _QuranSearchViewState extends State<QuranSearchView> {
  final QuranRepository _quranRepo = QuranRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  bool _isLoading = false;
  List<AyahEntity> _results = [];
  Map<int, SurahEntity> _surahsMap = {};
  List<SurahEntity> _allSurahs = [];
  int? _selectedSurahId;
  String _currentQuery = '';

  static const List<String> _quickSuggestions = [
    'إن الله مع الصابرين',
    'ألا بذكر الله',
    'الرحمن الرحيم',
    'رب إني لما أنزلت إلي',
    'لا إله إلا أنت سبحانك',
    'الحمد لله رب العالمين',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSurahId = widget.initialSurahId;
    _loadSurahs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    final list = await _quranRepo.getSurahs();
    if (!mounted) return;
    setState(() {
      _allSurahs = list;
      _surahsMap = {for (final s in list) s.id: s};
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _currentQuery = '';
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _currentQuery = trimmed;
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 250), () {
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    final res = await _quranRepo.searchAyahs(
      query,
      surahId: _selectedSurahId,
      limit: 150,
    );
    if (!mounted) return;
    setState(() {
      _results = res;
      _isLoading = false;
    });
  }

  void _applyQuickSuggestion(String suggestion) {
    _debounce?.cancel();
    _searchController.text = suggestion;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _currentQuery = suggestion;
      _isLoading = true;
    });
    _performSearch(suggestion);
  }

  void _openSurahFilterSheet(BuildContext context, AppColorsExtension colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تصفية نتائج البحث بحسب السورة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      if (_selectedSurahId != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _selectedSurahId = null);
                            if (_currentQuery.isNotEmpty) {
                              _performSearch(_currentQuery);
                            }
                          },
                          child: const Text('إلغاء التصفية'),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _allSurahs.length,
                    itemBuilder: (context, index) {
                      final surah = _allSurahs[index];
                      final isSelected = _selectedSurahId == surah.id;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isSelected
                              ? colors.primary
                              : colors.bg,
                          child: Text(
                            '${surah.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : colors.text,
                            ),
                          ),
                        ),
                        title: Text(
                          surah.nameAr,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: colors.text,
                          ),
                        ),
                        subtitle: Text(
                          '${surah.type == 'meccan' ? 'مكية' : 'مدنية'} • ${surah.totalVerses} آية',
                          style: TextStyle(fontSize: 12, color: colors.textMuted),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colors.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedSurahId = surah.id);
                          if (_currentQuery.isNotEmpty) {
                            _performSearch(_currentQuery);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToPage(int page, {int? surah, int? ayah}) {
    Get.to(
      () => const MushafView(),
      arguments: {
        'pageNumber': page,
        if (surah != null) 'surah': surah,
        if (ayah != null) 'ayah': ayah,
      },
      transition: Transition.cupertino,
    );
  }

  void _openTafsir(AyahEntity ayah, String surahName) {
    Get.to(
      () => const TafseerDetailsView(),
      arguments: {
        'surahId': ayah.surahId,
        'ayahNumber': ayah.ayahNumber,
        'surahName': surahName,
      },
    );
  }

  void _copyAyah(AyahEntity ayah, String surahName) {
    final text = '﴿ ${ayah.textAr} ﴾ [$surahName: ${ayah.ayahNumber}]';
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ الآية الكريمة إلى الحافظة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(AppSpacing.md),
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildHighlightedText(String fullText, String query, AppColorsExtension colors) {
    if (query.trim().isEmpty) {
      return Text(
        fullText,
        style: TextStyle(
          fontFamily: AppTypography.quranFont,
          fontSize: 19,
          height: 1.8,
          color: colors.text,
        ),
        textAlign: TextAlign.right,
      );
    }

    final normalizedQuery = ArabicNormalizer.normalize(query);
    final queryTokens = normalizedQuery
        .split(' ')
        .where((t) => t.trim().isNotEmpty)
        .toList();

    final words = fullText.split(' ');
    final spans = <TextSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final normWord = ArabicNormalizer.normalize(word);

      bool isMatch = false;
      if (normalizedQuery.isNotEmpty && normWord.contains(normalizedQuery)) {
        isMatch = true;
      } else {
        for (final token in queryTokens) {
          if (token.length >= 2 && normWord.contains(token)) {
            isMatch = true;
            break;
          }
        }
      }

      spans.add(
        TextSpan(
          text: word,
          style: TextStyle(
            color: isMatch ? colors.primary : colors.text,
            backgroundColor: isMatch ? colors.accent.withOpacity(0.28) : Colors.transparent,
            fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );

      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
        fontFamily: AppTypography.quranFont,
        fontSize: 19,
        height: 1.8,
        color: colors.text,
      ),
      textAlign: TextAlign.right,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selectedSurahName = _selectedSurahId != null
        ? _surahsMap[_selectedSurahId]?.nameAr
        : null;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          margin: const EdgeInsetsDirectional.only(end: AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: TextStyle(fontSize: 15, color: colors.text),
            decoration: InputDecoration(
              hintText: 'ابحث بالكلمة أو الآية في المصحف...',
              hintStyle: TextStyle(fontSize: 14, color: colors.textMuted),
              prefixIcon: Icon(Icons.search_rounded, color: colors.primary, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      color: colors.textMuted,
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            color: colors.surface,
            child: Row(
              children: [
                // Filter chip
                ActionChip(
                  avatar: Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: _selectedSurahId != null ? Colors.white : colors.primary,
                  ),
                  label: Text(
                    selectedSurahName != null
                        ? 'سورة $selectedSurahName'
                        : 'كل السور (114)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _selectedSurahId != null ? Colors.white : colors.text,
                    ),
                  ),
                  backgroundColor: _selectedSurahId != null
                      ? colors.primary
                      : colors.bg,
                  onPressed: () => _openSurahFilterSheet(context, colors),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (_selectedSurahId != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedSurahId = null);
                      if (_currentQuery.isNotEmpty) {
                        _performSearch(_currentQuery);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: colors.textMuted),
                    ),
                  ),
                const Spacer(),
                if (_currentQuery.isNotEmpty && !_isLoading)
                  Text(
                    '${_results.length} آية',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColorsExtension colors) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'جارٍ البحث في آيات القرآن الكريم...',
              style: TextStyle(color: colors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_currentQuery.isEmpty) {
      return _buildEmptyInitialState(colors);
    }

    if (_results.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                icon: Icons.search_off_rounded,
                title: 'لم يتم العثور على نتائج',
                message: 'لا توجد آيات مطابقة لـ "$_currentQuery"',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'نصيحة: تأكد من صحة الكلمة، أو ابحث بجزء أصغر منها (بدون ضمائر أو سوابق).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final ayah = _results[index];
        final surah = _surahsMap[ayah.surahId];
        final surahName = surah?.nameAr ?? 'سورة ${ayah.surahId}';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          color: colors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
            side: BorderSide(color: colors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Meta row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Text(
                            surahName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'آية ${ayah.ayahNumber}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    if (ayah.pageNumber != null)
                      InkWell(
                        onTap: () => _navigateToPage(ayah.pageNumber!, surah: ayah.surahId, ayah: ayah.ayahNumber),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.bg,
                            borderRadius: AppRadius.borderSm,
                            border: Border.all(color: colors.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu_book_rounded, size: 14, color: colors.accent),
                              const SizedBox(width: 4),
                              Text(
                                'صـ ${ayah.pageNumber}',
                                style: TextStyle(
                                  fontSize: 12,
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
                const SizedBox(height: AppSpacing.md),

                // Ayah Text
                _buildHighlightedText(ayah.textAr, _currentQuery, colors),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.xs),

                // Bottom Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copyAyah(ayah, surahName),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('نسخ', style: TextStyle(fontSize: 12.5)),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openTafsir(ayah, surahName),
                      icon: const Icon(Icons.menu_book_outlined, size: 16),
                      label: const Text('التفسير', style: TextStyle(fontSize: 12.5)),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textMuted,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (ayah.pageNumber != null)
                      ElevatedButton.icon(
                        onPressed: () => _navigateToPage(ayah.pageNumber!, surah: ayah.surahId, ayah: ayah.ayahNumber),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('عرض بالمصحف', style: TextStyle(fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderSm,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyInitialState(AppColorsExtension colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.manage_search_rounded,
              size: 56,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'البحث في القرآن الكريم',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'ابحث في نص 6236 آية كريمة بالكلمة أو العبارة بدون نت',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'كلمات شائعة للبحث:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: _quickSuggestions.map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: TextStyle(fontSize: 12.5, color: colors.text),
                ),
                backgroundColor: colors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  side: BorderSide(color: colors.divider),
                ),
                onPressed: () => _applyQuickSuggestion(suggestion),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
