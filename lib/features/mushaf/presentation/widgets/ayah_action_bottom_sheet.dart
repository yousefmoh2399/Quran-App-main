import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/data/models/ayah_entity.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/service/settings/SettingsServices.dart';
import '../models/mushaf_theme_model.dart';
import '../utils/mushaf_utils.dart';

/// Interactive action sheet displayed when an Ayah is tapped in the Mushaf.
///
/// Provides:
/// - Verse reference and Arabic text.
/// - Tafseer Al-Muyassar.
/// - Copy verse to clipboard.
/// - Share verse.
/// - Bookmark verse.
class AyahActionBottomSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final AyahEntity? ayahEntity;
  final MushafThemeConfig theme;
  final VoidCallback onClose;

  const AyahActionBottomSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahEntity,
    required this.theme,
    required this.onClose,
  });

  @override
  State<AyahActionBottomSheet> createState() => _AyahActionBottomSheetState();
}

class _AyahActionBottomSheetState extends State<AyahActionBottomSheet> {
  bool _isBookmarked = false;
  final SettingsServices _settings = Get.find<SettingsServices>();

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  void _checkBookmark() {
    final prefs = _settings.sharedPref;
    final bSurah = prefs?.getInt('mushaf_bookmarked_surah');
    final bAyah = prefs?.getInt('mushaf_bookmarked_ayah');
    setState(() {
      _isBookmarked = bSurah == widget.surahNumber && bAyah == widget.ayahNumber;
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = _settings.sharedPref;
    if (prefs == null) return;

    if (_isBookmarked) {
      await prefs.remove('mushaf_bookmarked_surah');
      await prefs.remove('mushaf_bookmarked_ayah');
      setState(() => _isBookmarked = false);
      _showFeedback('تمت إزالة العلامة المرجعية');
    } else {
      await prefs.setInt('mushaf_bookmarked_surah', widget.surahNumber);
      await prefs.setInt('mushaf_bookmarked_ayah', widget.ayahNumber);
      await prefs.setString('mushaf_bookmarked_surah_name', widget.surahName);
      setState(() => _isBookmarked = true);
      _showFeedback('تم حفظ العلامة المرجعية عند الآية ${widget.ayahNumber}');
    }
  }

  void _copyAyah() {
    final text = widget.ayahEntity?.textAr ?? '';
    final copyContent = '﴿$text﴾ [سورة ${widget.surahName}: ${widget.ayahNumber}]';
    Clipboard.setData(ClipboardData(text: copyContent));
    _showFeedback('تم نسخ الآية الكريمة إلى الحافظة');
  }

  void _shareAyah() {
    final text = widget.ayahEntity?.textAr ?? '';
    final tafsir = widget.ayahEntity?.tafsirMuyassar;
    final shareContent = StringBuffer()
      ..writeln('﴿ $text ﴾')
      ..writeln('— سورة ${widget.surahName} (الآية ${toArabicDigits(widget.ayahNumber)})');

    if (tafsir != null && tafsir.isNotEmpty) {
      shareContent
        ..writeln()
        ..writeln('التفسير الميسر:')
        ..writeln(tafsir);
    }

    Share.share(shareContent.toString());
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: AppTypography.uiFont),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final tafsirText = widget.ayahEntity?.tafsirMuyassar;
    final arabicText = widget.ayahEntity?.textAr ?? '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10.0, bottom: 6.0),
              width: 40.0,
              height: 4.5,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(3.0),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(color: colors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'سورة ${widget.surahName}  •  آية ${toArabicDigits(widget.ayahNumber)}',
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22.0),
                  color: colors.textMuted,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          const Divider(height: 1.0),

          // Scrollable Content (Ayah text & Tafseer)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ayah Text
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: colors.divider),
                    ),
                    child: Text(
                      arabicText,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: AppTypography.decorativeFont,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                        height: 1.8,
                      ),
                    ),
                  ),

                  AppSpacing.verticalMd,

                  // Tafseer Section
                  Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 18.0, color: colors.accent),
                      AppSpacing.horizontalXs,
                      Text(
                        'التفسير الميسر',
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalSm,
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(color: colors.divider),
                    ),
                    child: Text(
                      tafsirText != null && tafsirText.isNotEmpty
                          ? tafsirText
                          : 'جارٍ تحميل التفسير الميسر...',
                      textDirection: TextDirection.rtl,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1.0),

          // Action Buttons Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                // Copy Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11.0),
                      side: BorderSide(color: colors.divider),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    icon: Icon(Icons.copy_rounded, size: 18.0, color: colors.text),
                    label: Text(
                      'نسخ',
                      style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _copyAyah,
                  ),
                ),
                AppSpacing.horizontalSm,

                // Share Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11.0),
                      side: BorderSide(color: colors.divider),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    icon: Icon(Icons.share_rounded, size: 18.0, color: colors.text),
                    label: Text(
                      'مشاركة',
                      style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _shareAyah,
                  ),
                ),
                AppSpacing.horizontalSm,

                // Bookmark Button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBookmarked ? colors.accent : colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11.0),
                      elevation: 0,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    icon: Icon(
                      _isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                      size: 18.0,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isBookmarked ? 'محفوظة' : 'حفظ علامة',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _toggleBookmark,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
