import 'package:flutter/material.dart';
import '../../../../core/data/models/surah_entity.dart';
import '../../../../core/data/repositories/mushaf_repository.dart';
import '../../../../core/data/repositories/quran_repository.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/components/empty_state.dart';
import '../utils/mushaf_utils.dart';

/// Modal dialog providing quick navigation across the 604-page Mushaf:
/// - By Page number (1..604).
/// - By Surah (1..114).
/// - By Juz (1..30).
class MushafJumpDialog extends StatefulWidget {
  final int initialPage;
  final void Function(int targetPage) onPageSelected;

  const MushafJumpDialog({
    super.key,
    required this.initialPage,
    required this.onPageSelected,
  });

  @override
  State<MushafJumpDialog> createState() => _MushafJumpDialogState();
}

class _MushafJumpDialogState extends State<MushafJumpDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _pageInputController;
  late double _sliderValue;

  final QuranRepository _quranRepo = QuranRepository();
  final MushafRepository _mushafRepo = MushafRepository();

  List<SurahEntity> _surahs = [];
  Map<int, int> _surahStartPages = {};
  List<Map<String, dynamic>> _ajza = [];
  bool _isLoading = true;
  String _searchSurahQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _sliderValue = widget.initialPage.toDouble().clamp(1.0, 604.0);
    _pageInputController = TextEditingController(text: widget.initialPage.toString());
    _loadNavigationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  Future<void> _loadNavigationData() async {
    try {
      final surahs = await _quranRepo.getSurahs();
      final ajzaList = await _mushafRepo.getAjza();

      // Preload surah start pages
      final Map<int, int> startPages = {};
      for (final s in surahs) {
        final p = await _mushafRepo.getSurahStart(s.id) ?? 1;
        startPages[s.id] = p;
      }

      final formattedAjza = ajzaList.map((j) {
        final startSurahEntity = surahs.firstWhere(
          (s) => s.id == j.startSurah,
          orElse: () => surahs.first,
        );
        return {
          'juzNumber': j.juzNumber,
          'nameAr': j.nameAr,
          'startPage': j.startPage,
          'startSurah': startSurahEntity.nameAr,
          'startAyah': j.startAyah,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _surahs = surahs;
          _surahStartPages = startPages;
          _ajza = formattedAjza;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _jumpTo(int page) {
    final clamped = page.clamp(1, 604);
    widget.onPageSelected(clamped);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          children: [
            // Title & Close
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 20.0, top: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_rounded, color: colors.primary, size: 24.0),
                      AppSpacing.horizontalSm,
                      Text(
                        'انتقال سريع في المصحف',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: colors.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: colors.divider),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: colors.primary,
                  borderRadius: AppRadius.borderMd,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: colors.textMuted,
                labelStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'بالصفحة'),
                  Tab(text: 'بالسورة'),
                  Tab(text: 'بالجزء'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildByPageTab(colors, textTheme),
                  _buildBySurahTab(colors, textTheme),
                  _buildByJuzTab(colors, textTheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab 1: By Page
  Widget _buildByPageTab(AppColorsExtension colors, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'الصفحة الحالية',
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          AppSpacing.verticalSm,
          Text(
            'ـ ${toArabicDigits(_sliderValue.round())} ـ',
            style: TextStyle(
              fontFamily: AppTypography.decorativeFont,
              fontSize: 36.0,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          AppSpacing.verticalMd,

          // Page Slider
          Slider(
            value: _sliderValue,
            min: 1.0,
            max: 604.0,
            activeColor: colors.primary,
            inactiveColor: colors.divider,
            onChanged: (val) {
              setState(() {
                _sliderValue = val;
                _pageInputController.text = val.round().toString();
              });
            },
          ),

          AppSpacing.verticalMd,

          // Number Input Box
          SizedBox(
            width: 140,
            child: TextField(
              controller: _pageInputController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '1 - 604',
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                border: OutlineInputBorder(borderRadius: AppRadius.borderMd),
              ),
              onChanged: (val) {
                final numVal = int.tryParse(val);
                if (numVal != null && numVal >= 1 && numVal <= 604) {
                  setState(() {
                    _sliderValue = numVal.toDouble();
                  });
                }
              },
            ),
          ),

          AppSpacing.verticalLg,

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
              onPressed: () {
                final target = int.tryParse(_pageInputController.text) ?? _sliderValue.round();
                _jumpTo(target);
              },
              child: const Text(
                'انتقال إلى الصفحة',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 2: By Surah
  Widget _buildBySurahTab(AppColorsExtension colors, TextTheme textTheme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    final filtered = _searchSurahQuery.trim().isEmpty
        ? _surahs
        : _surahs.where((s) {
            return s.nameAr.contains(_searchSurahQuery.trim()) ||
                s.id.toString().contains(_searchSurahQuery.trim());
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'ابحث عن سورة بالاسم أو الرقم...',
              prefixIcon: Icon(Icons.search_rounded, color: colors.primary, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
            ),
            onChanged: (val) => setState(() => _searchSurahQuery = val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  title: 'لا توجد نتائج',
                  message: 'تأكد من كتابة اسم السورة بشكل صحيح',
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1.0),
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    final startPage = _surahStartPages[surah.id] ?? 1;
                    final typeAr = surah.type == 'meccan' ? 'مكية' : 'مدنية';

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      leading: Container(
                        width: 34.0,
                        height: 34.0,
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${surah.id}',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'سورة ${surah.nameAr}',
                        style: TextStyle(
                          fontFamily: AppTypography.decorativeFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 17.0,
                          color: colors.text,
                        ),
                      ),
                      subtitle: Text(
                        '$typeAr • ${surah.totalVerses} آيات',
                        style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(color: colors.divider),
                        ),
                        child: Text(
                          'صـ ${toArabicDigits(startPage)}',
                          style: TextStyle(
                            fontFamily: AppTypography.decorativeFont,
                            fontWeight: FontWeight.bold,
                            color: colors.accent,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      onTap: () => _jumpTo(startPage),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Tab 3: By Juz
  Widget _buildByJuzTab(AppColorsExtension colors, TextTheme textTheme) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _ajza.length,
      separatorBuilder: (_, __) => const Divider(height: 1.0),
      itemBuilder: (context, index) {
        final juz = _ajza[index];
        final juzNum = juz['juzNumber'] as int;
        final startPage = juz['startPage'] as int;
        final startSurah = juz['startSurah'] as String;
        final startAyah = juz['startAyah'] as int;

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          leading: Container(
            width: 38.0,
            height: 38.0,
            decoration: BoxDecoration(
              color: colors.accent.withOpacity(0.12),
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.accent.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                toArabicDigits(juzNum),
                style: TextStyle(
                  color: colors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
          title: Text(
            'الجزء ${getJuzNameArabic(juzNum)}',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          subtitle: Text(
            'يبدأ من سورة $startSurah (آية ${toArabicDigits(startAyah)})',
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: colors.divider),
            ),
            child: Text(
              'صـ ${toArabicDigits(startPage)}',
              style: TextStyle(
                fontFamily: AppTypography.decorativeFont,
                fontWeight: FontWeight.bold,
                color: colors.primary,
                fontSize: 13.0,
              ),
            ),
          ),
          onTap: () => _jumpTo(startPage),
        );
      },
    );
  }
}
