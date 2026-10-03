import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/util/share_helper.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';

enum AyahCardThemePreset {
  emerald(
    title: 'زمردي مذهب',
    bgGradient: [Color(0xFF0F5C4A), Color(0xFF09362B)],
    textColor: Color(0xFFF9F7EE),
    accentColor: Color(0xFFD9B25A),
    borderColor: Color(0xFFD9B25A),
  ),
  midnight(
    title: 'ليلي كحلي',
    bgGradient: [Color(0xFF16253D), Color(0xFF0B1423)],
    textColor: Color(0xFFF0F4F8),
    accentColor: Color(0xFF64B5F6),
    borderColor: Color(0xFF64B5F6),
  ),
  parchment(
    title: 'ورق عتيق',
    bgGradient: [Color(0xFFF6EEDB), Color(0xFFEADBBE)],
    textColor: Color(0xFF2C2416),
    accentColor: Color(0xFF8C6226),
    borderColor: Color(0xFF8C6226),
  ),
  charcoal(
    title: 'فحمي ملكي',
    bgGradient: [Color(0xFF23272A), Color(0xFF141618)],
    textColor: Color(0xFFEDEAE5),
    accentColor: Color(0xFFC5A059),
    borderColor: Color(0xFFC5A059),
  );

  final String title;
  final List<Color> bgGradient;
  final Color textColor;
  final Color accentColor;
  final Color borderColor;

  const AyahCardThemePreset({
    required this.title,
    required this.bgGradient,
    required this.textColor,
    required this.accentColor,
    required this.borderColor,
  });
}

class AyahCardGeneratorView extends StatefulWidget {
  final String ayahText;
  final String surahName;
  final int ayahNumber;
  final String? tafsirText;

  const AyahCardGeneratorView({
    super.key,
    required this.ayahText,
    required this.surahName,
    required this.ayahNumber,
    this.tafsirText,
  });

  @override
  State<AyahCardGeneratorView> createState() => _AyahCardGeneratorViewState();
}

class _AyahCardGeneratorViewState extends State<AyahCardGeneratorView> {
  final GlobalKey _cardKey = GlobalKey();
  AyahCardThemePreset _selectedPreset = AyahCardThemePreset.emerald;
  bool _includeTafsir = false;
  bool _isExporting = false;

  Future<void> _captureAndShare() async {
    final shareOrigin = getSharePositionOrigin(context);
    setState(() => _isExporting = true);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/ayah_${widget.surahName}_${widget.ayahNumber}.png');
        await file.writeAsBytes(pngBytes);

        final xfile = XFile(file.path, mimeType: 'image/png');
        await Share.shareXFiles(
          [xfile],
          text: '﴿${widget.ayahText}﴾ [${widget.surahName}: ${widget.ayahNumber}]',
          sharePositionOrigin: shareOrigin,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إنشاء الصورة: $e')),
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
        title: const Text('مشاركة الآية كصورة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Card with RepaintBoundary
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _selectedPreset.bgGradient,
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _selectedPreset.borderColor.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Decorative Bismillah / Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 10, color: _selectedPreset.accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                          style: TextStyle(
                            fontFamily: AppTypography.decorativeFont,
                            fontSize: 14,
                            color: _selectedPreset.accentColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.star, size: 10, color: _selectedPreset.accentColor),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Ayah Text
                    Text(
                      '﴿ ${widget.ayahText} ﴾',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.9,
                        color: _selectedPreset.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Optional Tafsir
                    if (_includeTafsir && widget.tafsirText != null && widget.tafsirText!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.tafsirText!,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: _selectedPreset.textColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Footer Surah Reference & App Brand
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedPreset.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _selectedPreset.accentColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        '${widget.surahName} • آية ${widget.ayahNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedPreset.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تطبيق تقرّب • القرآن الكريم',
                      style: TextStyle(
                        fontSize: 10,
                        color: _selectedPreset.textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalLg,

            // Theme Presets Selector
            const Text(
              'اختر تصميم البطاقة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: AyahCardThemePreset.values.map((preset) {
                final isSelected = _selectedPreset == preset;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPreset = preset),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: preset.bgGradient),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      preset.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: preset.textColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            AppSpacing.verticalLg,

            // Include Tafsir Switch (if available)
            if (widget.tafsirText != null && widget.tafsirText!.isNotEmpty)
              SwitchListTile(
                title: const Text('تضمين التفسير في البطاقة'),
                value: _includeTafsir,
                onChanged: (val) => setState(() => _includeTafsir = val),
              ),
            AppSpacing.verticalLg,

            // Share Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                ),
                icon: const Icon(Icons.share_rounded),
                label: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('مشاركة الصورة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _isExporting ? null : _captureAndShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
