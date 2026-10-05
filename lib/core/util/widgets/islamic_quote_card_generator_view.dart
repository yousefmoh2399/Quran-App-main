import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/util/share_helper.dart';

enum IslamicQuoteThemePreset {
  emerald(
    title: 'زمردي مذهب',
    bgGradient: [Color(0xFF0F5C4A), Color(0xFF07372C)],
    textColor: Color(0xFFFAF7F0),
    accentColor: Color(0xFFD4AF37),
    borderColor: Color(0xFFD4AF37),
    badgeBg: Color(0x33D4AF37),
  ),
  midnight(
    title: 'ليلي كحلي',
    bgGradient: [Color(0xFF132238), Color(0xFF09121F)],
    textColor: Color(0xFFF1F5F9),
    accentColor: Color(0xFF60A5FA),
    borderColor: Color(0xFF3B82F6),
    badgeBg: Color(0x3360A5FA),
  ),
  parchment(
    title: 'ورق عتيق',
    bgGradient: [Color(0xFFF6EEDB), Color(0xFFE5D5B3)],
    textColor: Color(0xFF261E14),
    accentColor: Color(0xFF8C5E28),
    borderColor: Color(0xFF8C5E28),
    badgeBg: Color(0x228C5E28),
  ),
  charcoal(
    title: 'فحمي ملكي',
    bgGradient: [Color(0xFF202326), Color(0xFF121416)],
    textColor: Color(0xFFECEFF1),
    accentColor: Color(0xFFE5B869),
    borderColor: Color(0xFFE5B869),
    badgeBg: Color(0x33E5B869),
  );

  final String title;
  final List<Color> bgGradient;
  final Color textColor;
  final Color accentColor;
  final Color borderColor;
  final Color badgeBg;

  const IslamicQuoteThemePreset({
    required this.title,
    required this.bgGradient,
    required this.textColor,
    required this.accentColor,
    required this.borderColor,
    required this.badgeBg,
  });
}

class IslamicQuoteCardGeneratorView extends StatefulWidget {
  final String quoteText;
  final String categoryTitle;
  final String source;
  final String? itemNumber;

  const IslamicQuoteCardGeneratorView({
    super.key,
    required this.quoteText,
    required this.categoryTitle,
    required this.source,
    this.itemNumber,
  });

  @override
  State<IslamicQuoteCardGeneratorView> createState() =>
      _IslamicQuoteCardGeneratorViewState();
}

class _IslamicQuoteCardGeneratorViewState
    extends State<IslamicQuoteCardGeneratorView> {
  final GlobalKey _cardKey = GlobalKey();
  IslamicQuoteThemePreset _selectedPreset = IslamicQuoteThemePreset.emerald;
  bool _isExporting = false;
  double _fontSize = 17.0;

  Future<void> _captureAndShare() async {
    final shareOrigin = getSharePositionOrigin(context);
    setState(() => _isExporting = true);

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/taqarrab_card_$timestamp.png');
        await file.writeAsBytes(pngBytes);

        final xfile = XFile(file.path, mimeType: 'image/png');
        await Share.shareXFiles(
          [xfile],
          text: '«${widget.quoteText}»\n${widget.categoryTitle} • ${widget.source}\nتطبيق تقرّب 🌿',
          sharePositionOrigin: shareOrigin,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تصدير الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('مشاركة كبطاقة مصممة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Card with RepaintBoundary
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedPreset.bgGradient,
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedPreset.borderColor.withOpacity(0.55),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Inner Decorative Frame
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedPreset.borderColor.withOpacity(0.25),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header: Category Badge & Number
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _selectedPreset.badgeBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _selectedPreset.accentColor
                                        .withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 13,
                                      color: _selectedPreset.accentColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.categoryTitle,
                                      style: TextStyle(
                                        fontFamily: AppTypography.uiFont,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedPreset.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.itemNumber != null &&
                                  widget.itemNumber!.isNotEmpty)
                                Text(
                                  widget.itemNumber!,
                                  style: TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedPreset.textColor
                                        .withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Decorative Bismillah / Top Symbol
                          Text(
                            '﷽',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 22,
                              color: _selectedPreset.accentColor.withOpacity(0.9),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Quote Text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '«${widget.quoteText}»',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.hadithFont,
                                fontSize: _fontSize,
                                height: 1.9,
                                fontWeight: FontWeight.w600,
                                color: _selectedPreset.textColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Divider with diamond ornament
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: _selectedPreset.borderColor
                                      .withOpacity(0.3),
                                  thickness: 0.8,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: _selectedPreset.accentColor,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: _selectedPreset.borderColor
                                      .withOpacity(0.3),
                                  thickness: 0.8,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Source & Watermark Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.source,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: _selectedPreset.textColor
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'تطبيق تقرّب',
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedPreset.accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('🌿', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            AppSpacing.verticalLg,

            // Theme Presets Selector
            Text(
              'اختر تصميم البطاقة:',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: colors.text,
              ),
            ),
            AppSpacing.verticalSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IslamicQuoteThemePreset.values.map((preset) {
                final isSelected = _selectedPreset == preset;
                return ChoiceChip(
                  label: Text(preset.title),
                  selected: isSelected,
                  selectedColor: preset.bgGradient.first,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : colors.text,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedPreset = preset);
                  },
                );
              }).toList(),
            ),

            AppSpacing.verticalMd,

            // Font Size Adjuster
            Row(
              children: [
                Text(
                  'حجم الخط:',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.text,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 14.0,
                    max: 24.0,
                    divisions: 5,
                    label: '${_fontSize.toInt()}',
                    activeColor: colors.primary,
                    onChanged: (val) => setState(() => _fontSize = val),
                  ),
                ),
              ],
            ),

            AppSpacing.verticalLg,

            // Share Button
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _captureAndShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMd,
                ),
                elevation: 3,
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_rounded),
              label: Text(
                _isExporting ? 'جاري إنشاء البطاقة...' : 'مشاركة البطاقة كصورة الآن',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
