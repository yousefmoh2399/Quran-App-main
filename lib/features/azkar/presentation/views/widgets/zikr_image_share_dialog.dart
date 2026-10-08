import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_app_android/core/util/share_helper.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_typography.dart';

enum ZikrCardPreset {
  emerald(
    title: 'زمردي مذهب',
    bgGradient: [Color(0xFF0D3B2E), Color(0xFF061E17)],
    textColor: Color(0xFFFFFFFF),
    virtueColor: Color(0xFF9ECEBA),
    accentColor: Color(0xFFD4AF37),
    borderColor: Color(0xFFD4AF37),
  ),
  royalNavy(
    title: 'كحلي إسلامي',
    bgGradient: [Color(0xFF14243B), Color(0xFF0A1320)],
    textColor: Color(0xFFFFFFFF),
    virtueColor: Color(0xFF90B4CE),
    accentColor: Color(0xFF56CCF2),
    borderColor: Color(0xFF4FA3D1),
  ),
  parchment(
    title: 'مخطوطة عتيقة',
    bgGradient: [Color(0xFFF9F5EC), Color(0xFFEFE6D2)],
    textColor: Color(0xFF2C2416),
    virtueColor: Color(0xFF6B583E),
    accentColor: Color(0xFF966D20),
    borderColor: Color(0xFFB8892B),
  );

  final String title;
  final List<Color> bgGradient;
  final Color textColor;
  final Color virtueColor;
  final Color accentColor;
  final Color borderColor;

  const ZikrCardPreset({
    required this.title,
    required this.bgGradient,
    required this.textColor,
    required this.virtueColor,
    required this.accentColor,
    required this.borderColor,
  });
}

class ZikrShareHelper {
  static void showShareOptions(
    BuildContext context, {
    required String zikrText,
    String? virtue,
    String? categoryTitle,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (bottomSheetContext) {
        final colors = bottomSheetContext.appColors;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'مشاركة الذكر المبارك',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.image_rounded, color: colors.primary),
                  ),
                  title: const Text(
                    'مشاركة كبطاقة مصممة (صورة عالية الدقة)',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'بطاقة إسلامية أنيقة بخط النسخ وهوية تقرّب',
                    style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    showDialog(
                      context: context,
                      builder: (_) => ZikrImageShareDialog(
                        zikrText: zikrText,
                        virtue: virtue,
                        categoryTitle: categoryTitle ?? 'ذكر وتدبر',
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.text_fields_rounded, color: colors.accent),
                  ),
                  title: const Text(
                    'مشاركة كنص',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'إرسال نص الذكر والفضل عبر واتساب والتطبيقات',
                    style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    final shareText = StringBuffer(zikrText);
                    if (virtue != null && virtue.trim().isNotEmpty) {
                      shareText.write('\n\n$virtue');
                    }
                    shareText.write('\n\n— من تطبيق تقرّب');
                    Share.share(
                      shareText.toString(),
                      sharePositionOrigin: getSharePositionOrigin(bottomSheetContext),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ZikrImageShareDialog extends StatefulWidget {
  final String zikrText;
  final String? virtue;
  final String categoryTitle;

  const ZikrImageShareDialog({
    super.key,
    required this.zikrText,
    this.virtue,
    required this.categoryTitle,
  });

  @override
  State<ZikrImageShareDialog> createState() => _ZikrImageShareDialogState();
}

class _ZikrImageShareDialogState extends State<ZikrImageShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  ZikrCardPreset _selectedPreset = ZikrCardPreset.emerald;
  bool _isSharing = false;

  Future<void> _captureAndShare() async {
    final shareOrigin = getSharePositionOrigin(context);
    setState(() => _isSharing = true);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/taqarrab_zikr_$timestamp.png');
        await file.writeAsBytes(pngBytes);

        final xfile = XFile(file.path, mimeType: 'image/png');
        await Share.shareXFiles(
          [xfile],
          text: '${widget.zikrText}\n— تطبيق تقرّب',
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
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'تصميم بطاقة الذكر',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // The Renderable Card
              RepaintBoundary(
                key: _cardKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedPreset.bgGradient,
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedPreset.borderColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Ornament / Category
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 1,
                            color: _selectedPreset.accentColor.withOpacity(0.5),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                widget.categoryTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedPreset.accentColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 1,
                            color: _selectedPreset.accentColor.withOpacity(0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Dhikr Text in Calligraphy / Arabic font
                      Text(
                        widget.zikrText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: AppTypography.decorativeFont,
                          fontSize: 20,
                          height: 1.8,
                          fontWeight: FontWeight.bold,
                          color: _selectedPreset.textColor,
                        ),
                      ),

                      // Virtue / Source
                      if (widget.virtue != null && widget.virtue!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedPreset.accentColor.withOpacity(0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.virtue!,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 12,
                              color: _selectedPreset.virtueColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // App Branding Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 14,
                            color: _selectedPreset.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'تطبيق تَقَرَّبْ • قرآن وأذكار',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _selectedPreset.accentColor.withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Theme Selector Chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: ZikrCardPreset.values.map((preset) {
                  final isSelected = _selectedPreset == preset;
                  return ChoiceChip(
                    label: Text(
                      preset.title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colors.primary.withOpacity(0.15),
                    onSelected: (_) => setState(() => _selectedPreset = preset),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Share Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                  ),
                  onPressed: _isSharing ? null : _captureAndShare,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: Text(
                    _isSharing ? 'جاري إنشاء الصورة...' : 'مشاركة البطاقة كصورة',
                    style: const TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
