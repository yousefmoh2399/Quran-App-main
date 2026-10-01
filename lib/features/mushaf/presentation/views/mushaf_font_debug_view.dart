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

/// Temporary debug screen to visually and programmatically verify genuine TrueType
/// font loading and rendering for Line 2 of pages 1, 77, and 586.
class MushafFontDebugView extends StatefulWidget {
  const MushafFontDebugView({super.key});

  @override
  State<MushafFontDebugView> createState() => _MushafFontDebugViewState();
}

class _MushafFontDebugViewState extends State<MushafFontDebugView> {
  final MushafRepository _mushafRepo = MushafRepository();
  final List<int> _testPages = [1, 77, 586];

  final Map<int, MushafLine?> _testLines = {};
  final Map<int, bool> _fontLoadSuccess = {};
  final Map<int, String> _fontDiagnostics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  Future<void> _loadDebugData() async {
    for (final pageNum in _testPages) {
      try {
        final stopwatch = Stopwatch()..start();
        await MushafFontManager.instance.ensurePageLoaded(pageNum);
        stopwatch.stop();

        final isLoaded = MushafFontManager.instance.isPageLoaded(pageNum);
        final page = await _mushafRepo.getPage(pageNum);

        // Get line 2 (or line 1 if page has fewer lines)
        final line = page.lines.length >= 2 ? page.lines[1] : page.lines.first;

        // Ensure word fonts if any word has different page
        for (final w in line.words) {
          if (w.pageNumber != pageNum) {
            await MushafFontManager.instance.ensurePageLoaded(w.pageNumber);
          }
        }

        _fontLoadSuccess[pageNum] = isLoaded;
        _testLines[pageNum] = line;
        _fontDiagnostics[pageNum] =
            '✅ Family: ${MushafFontManager.pageFontFamily(pageNum)} | Time: ${stopwatch.elapsedMilliseconds}ms | Words: ${line.words.length}';
        debugPrint('MushafFontDebug: Page $pageNum loaded successfully (${stopwatch.elapsedMilliseconds}ms)');
      } catch (e) {
        _fontLoadSuccess[pageNum] = false;
        _fontDiagnostics[pageNum] = '❌ Failed: $e';
        debugPrint('MushafFontDebug: Error on page $pageNum: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
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
      backgroundColor: theme.pageBg,
      appBar: AppBar(
        title: const Text('فحص واختبار خطوط المصحف TTF'),
        centerTitle: true,
        backgroundColor: colors.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: AppSpacing.screen,
              itemCount: _testPages.length,
              separatorBuilder: (_, __) => AppSpacing.verticalLg,
              itemBuilder: (context, index) {
                final pageNum = _testPages[index];
                final line = _testLines[pageNum];
                final diag = _fontDiagnostics[pageNum] ?? '';
                final success = _fontLoadSuccess[pageNum] ?? false;

                return Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: success ? colors.primary : colors.error,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الصفحة $pageNum (السطر 2)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: success ? colors.primary.withOpacity(0.1) : colors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              success ? 'TrueType محمل' : 'فشل التحميل',
                              style: TextStyle(
                                color: success ? colors.primary : colors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        diag,
                        style: TextStyle(fontSize: 12.0, color: colors.textMuted),
                      ),
                      const Divider(height: 16),

                      // Rendered line preview
                      if (line != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.pageBg,
                            borderRadius: AppRadius.borderSm,
                            border: Border.all(color: theme.frameBorderOuter.withOpacity(0.4)),
                          ),
                          child: MushafLineWidget(
                            line: line,
                            pageNumber: pageNum,
                            theme: theme,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
