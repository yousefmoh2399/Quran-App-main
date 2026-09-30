import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/data/models/mushaf_models.dart';
import '../../../../core/data/repositories/mushaf_repository.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/mushaf/mushaf_font_manager.dart';
import '../models/mushaf_theme_model.dart';
import '../widgets/mushaf_line_widget.dart';

/// Screen comparing QPC V1 and QPC V2 fonts side-by-side / stacked
/// for Line 2 of pages 1, 77, and 586 (and arbitrary pages).
class MushafV1V2CompareView extends StatefulWidget {
  const MushafV1V2CompareView({super.key});

  @override
  State<MushafV1V2CompareView> createState() => _MushafV1V2CompareViewState();
}

class _MushafV1V2CompareViewState extends State<MushafV1V2CompareView> {
  final MushafRepository _mushafRepo = MushafRepository();
  final List<int> _defaultPages = [1, 77, 586];

  int _selectedPage = 1;
  int _selectedLineIndex = 1; // 0-indexed, so 1 is Line 2

  bool _isLoading = true;
  String? _errorMessage;

  MushafPage? _pageData;
  int _v1LoadTimeMs = 0;
  int _v2LoadTimeMs = 0;
  bool _v1Success = false;
  bool _v2Success = false;

  double _fontSizeScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPageComparison(_selectedPage);
  }

  Future<void> _loadPageComparison(int pageNum) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedPage = pageNum;
    });

    try {
      // 1. Load V1 Font
      final sw1 = Stopwatch()..start();
      await MushafFontManager.instance.ensurePageLoadedV1(pageNum);
      sw1.stop();
      _v1LoadTimeMs = sw1.elapsedMilliseconds;
      _v1Success = MushafFontManager.instance.isPageLoadedV1(pageNum);

      // 2. Load V2 Font
      final sw2 = Stopwatch()..start();
      await MushafFontManager.instance.ensurePageLoaded(pageNum);
      sw2.stop();
      _v2LoadTimeMs = sw2.elapsedMilliseconds;
      _v2Success = MushafFontManager.instance.isPageLoaded(pageNum);

      // 3. Fetch Page Data from DB
      final page = await _mushafRepo.getPage(pageNum);

      if (mounted) {
        setState(() {
          _pageData = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug screen disabled in release mode.')),
      );
    }

    final colors = context.appColors;
    final theme = MushafThemeConfig.light;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),
      appBar: AppBar(
        title: const Text('مقارنة خطوط QPC V1 مقابل V2'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة تحميل',
            onPressed: () => _loadPageComparison(_selectedPage),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick page selector buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: colors.surface,
            child: Row(
              children: [
                const Text('الصفحة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._defaultPages.map((p) {
                  final isSelected = p == _selectedPage;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text('صفحة $p'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected && p != _selectedPage) {
                          _loadPageComparison(p);
                        }
                      },
                    ),
                  );
                }),
                const Spacer(),
                // Zoom Slider
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 20),
                  onPressed: () {
                    if (_fontSizeScale > 0.8) {
                      setState(() => _fontSizeScale -= 0.1);
                    }
                  },
                ),
                Text('${(_fontSizeScale * 100).toInt()}%'),
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: () {
                    if (_fontSizeScale < 1.6) {
                      setState(() => _fontSizeScale += 0.1);
                    }
                  },
                ),
              ],
            ),
          ),

          // Main Comparison Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text('خطأ: $_errorMessage', style: TextStyle(color: colors.error)))
                    : _buildComparisonContent(colors, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonContent(AppColorsExtension colors, MushafThemeConfig theme) {
    if (_pageData == null || _pageData!.lines.isEmpty) {
      return const Center(child: Text('لا توجد بيانات لهذه الصفحة'));
    }

    // Default to line 2 (index 1), fallback to line 1 if only 1 line
    final lineIdx = (_selectedLineIndex < _pageData!.lines.length) ? _selectedLineIndex : 0;
    final line = _pageData!.lines[lineIdx];

    return SingleChildScrollView(
      padding: AppSpacing.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page Info Card
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderMd,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoBadge('الصفحة', '$_selectedPage'),
                _buildInfoBadge('السورة', _pageData!.surahNameAr),
                _buildInfoBadge('الجزء', '${_pageData!.juzNumber}'),
                _buildInfoBadge('السطر المعروض', '${line.lineNumber} من ${_pageData!.lines.length}'),
                _buildInfoBadge('عدد الكلمات', '${line.words.length}'),
              ],
            ),
          ),
          AppSpacing.verticalMd,

          // Line Selector Dropdown / Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderSm,
            ),
            child: Row(
              children: [
                const Text('اختر السطر: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_pageData!.lines.length, (idx) {
                        final lNum = _pageData!.lines[idx].lineNumber;
                        final isSel = idx == lineIdx;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ChoiceChip(
                            label: Text('س$lNum', style: const TextStyle(fontSize: 12)),
                            selected: isSel,
                            visualDensity: VisualDensity.compact,
                            onSelected: (val) {
                              if (val) setState(() => _selectedLineIndex = idx);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalLg,

          // 1. QPC V2 Card
          _buildFontCard(
            title: 'QPC V2 (حفص الإصدار الثاني - الخط الحالي)',
            fontFamily: MushafFontManager.pageFontFamily(_selectedPage),
            isSuccess: _v2Success,
            loadTimeMs: _v2LoadTimeMs,
            badgeColor: Colors.blue.shade700,
            badgeText: 'V2 الأصلي',
            line: line,
            useV1Glyphs: false,
            colors: colors,
            theme: theme,
          ),
          AppSpacing.verticalLg,

          // 2. QPC V1 Card
          _buildFontCard(
            title: 'QPC V1 (حفص الإصدار الأول - الجديد المقترح)',
            fontFamily: MushafFontManager.pageFontFamilyV1(_selectedPage),
            isSuccess: _v1Success,
            loadTimeMs: _v1LoadTimeMs,
            badgeColor: Colors.teal.shade700,
            badgeText: 'V1 الأخف حجماً',
            line: line,
            useV1Glyphs: true,
            colors: colors,
            theme: theme,
          ),
          AppSpacing.verticalLg,

          // 3. Technical Comparison Summary Card
          _buildTechnicalComparisonCard(colors),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFontCard({
    required String title,
    required String fontFamily,
    required bool isSuccess,
    required int loadTimeMs,
    required Color badgeColor,
    required String badgeText,
    required MushafLine line,
    required bool useV1Glyphs,
    required AppColorsExtension colors,
    required MushafThemeConfig theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSuccess ? '✅ محمل (${loadTimeMs}ms)' : '❌ فشل',
                    style: TextStyle(
                      color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rendered Line Preview
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.pageBg,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: theme.frameBorderOuter.withOpacity(0.35)),
            ),
            child: _buildCustomRenderedLine(
              line: line,
              fontFamily: fontFamily,
              useV1Glyphs: useV1Glyphs,
              theme: theme,
            ),
          ),

          // Words / Glyphs Inspect Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // RTL flow
              child: Row(
                children: line.words.map((w) {
                  final glyph = useV1Glyphs ? (w.glyphCodeV1 ?? w.glyphCode) : w.glyphCode;
                  final cpList = glyph.runes.map((r) => 'U+${r.toRadixString(16).toUpperCase()}').join(' ');
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          w.textUthmani,
                          style: const TextStyle(fontSize: 10, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          glyph,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 16,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cpList,
                          style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRenderedLine({
    required MushafLine line,
    required String fontFamily,
    required bool useV1Glyphs,
    required MushafThemeConfig theme,
  }) {
    if (line.lineType == MushafLineType.surahHeader) {
      return MushafLineWidget(
        line: line,
        pageNumber: _selectedPage,
        theme: theme,
      );
    }

    if (line.words.isEmpty) {
      final rawText = useV1Glyphs ? (line.qpcV1 ?? line.text ?? '') : (line.qpcV2 ?? line.text ?? '');
      return FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        child: Text(
          rawText,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 22.0 * _fontSizeScale,
            color: theme.textColor,
            height: 1.1,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.center,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: line.words.map((word) {
            final glyph = useV1Glyphs ? (word.glyphCodeV1 ?? word.glyphCode) : word.glyphCode;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.0),
              child: Text(
                glyph,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 22.0 * _fontSizeScale,
                  color: theme.textColor,
                  height: 1.1,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTechnicalComparisonCard(AppColorsExtension colors) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '📊 المقارنة الفنية الشاملة بين النسختين',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const Divider(height: 16),
          _buildComparisonRow(
            'معيار المقارنة',
            'QPC V2 (الحالي)',
            'QPC V1 (المقترح)',
            isHeader: true,
          ),
          const Divider(height: 12),
          _buildComparisonRow(
            'حجم خط الصفحة الواحدة',
            '~140 - 240 KB',
            '~26 - 170 KB (متوسط 148 KB)',
          ),
          _buildComparisonRow(
            'حجم الخطوط الـ604 الإجمالي',
            '119 MB',
            '~89.8 MB (مقلّص بـ subset)',
          ),
          _buildComparisonRow(
            'عدد الحروف في الخط',
            'موسّع للرسم العثماني V2',
            'مركّز على علامات ضبط V1',
          ),
          _buildComparisonRow(
            'تنسيق الملفات',
            'TrueType (TTF) أصلي',
            'TrueType (TTF) أصلي',
          ),
          _buildComparisonRow(
            'توافق الأجهزة الضعيفة (2GB)',
            'تحميل ديناميكي صفحة بصفحة',
            'تحميل ديناميكي صفحة بصفحة',
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String v2Val, String v1Val, {bool isHeader = false}) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      color: isHeader ? Colors.black : Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: style)),
          Expanded(flex: 3, child: Text(v2Val, style: style, textAlign: TextAlign.center)),
          Expanded(flex: 3, child: Text(v1Val, style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
