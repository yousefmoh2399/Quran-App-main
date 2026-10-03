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
import '../views/ayah_card_generator_view.dart';
import '../../../tafsser/data/tafsir_repository.dart';

/// Interactive action sheet displayed when an Ayah is tapped in the Mushaf.
///
/// Provides:
/// - Verse reference and Arabic text.
/// - Tafseer Al-Muyassar.
/// - Memorization status tracking (بيحفظ / محفوظ / يحتاج مراجعة).
/// - Verse bookmarking with customizable color (ذهبي، زمردي، أزرق، ياقوتي، عنبري) and personal note.
/// - Copy verse to clipboard and share verse.
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

class _AyahActionBottomSheetState extends State<AyahActionBottomSheet> {
  final MushafController _controller = Get.find<MushafController>();
  late TextEditingController _noteController;

  bool _isBookmarked = false;
  BookmarkColor _selectedColor = BookmarkColor.gold;
  MemorizeStatus? _selectedStatus;
  bool _showNotesInput = false;

  TafsirSource _selectedTafsir = TafsirSource.muyassar;
  String? _loadedTafsirText;
  bool _isLoadingTafsir = false;

  @override
  void initState() {
    super.initState();
    final bookmark = _controller.getAyahBookmark(widget.surahNumber, widget.ayahNumber);
    final memorized = _controller.getAyahMemorized(widget.surahNumber, widget.ayahNumber);

    _isBookmarked = bookmark != null;
    _selectedColor = bookmark?.color ?? BookmarkColor.gold;
    _selectedStatus = memorized?.status;
    _noteController = TextEditingController(text: bookmark?.note ?? '');
    _showNotesInput = bookmark?.note != null && bookmark!.note!.isNotEmpty;
    _loadedTafsirText = widget.ayahEntity?.tafsirMuyassar;
  }

  Future<void> _changeTafsir(TafsirSource source) async {
    if (source == _selectedTafsir && _loadedTafsirText != null) return;
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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _toggleBookmark() async {
    final note = _noteController.text.trim();
    if (_isBookmarked) {
      await _controller.removeAyahBookmark(
        widget.surahNumber,
        widget.ayahNumber,
        widget.pageNumber,
      );
      setState(() => _isBookmarked = false);
      _showFeedback('تمت إزالة العلامة المرجعية للآية');
    } else {
      _controller.selectedAyahColor.value = _selectedColor;
      await _controller.setAyahBookmark(
        surah: widget.surahNumber,
        ayah: widget.ayahNumber,
        page: widget.pageNumber,
        color: _selectedColor,
        note: note.isNotEmpty ? note : null,
      );
      setState(() => _isBookmarked = true);
      _showFeedback('تم حفظ العلامة المرجعية للآية بنجاح');
    }
  }

  Future<void> _updateColor(BookmarkColor color) async {
    setState(() => _selectedColor = color);
    _controller.selectedAyahColor.value = color;
    if (_isBookmarked) {
      final note = _noteController.text.trim();
      await _controller.setAyahBookmark(
        surah: widget.surahNumber,
        ayah: widget.ayahNumber,
        page: widget.pageNumber,
        color: color,
        note: note.isNotEmpty ? note : null,
      );
    }
  }

  Future<void> _updateMemorizeStatus(MemorizeStatus? status) async {
    setState(() => _selectedStatus = status);
    await _controller.setAyahMemorizeStatus(
      surah: widget.surahNumber,
      ayah: widget.ayahNumber,
      page: widget.pageNumber,
      status: status,
    );
    final msg = status == null
        ? 'تم إلغاء حالة الحفظ للآية'
        : 'تم تحديد الآية: ${status.labelAr}';
    _showFeedback(msg);
  }

  Future<void> _saveNote() async {
    final note = _noteController.text.trim();
    if (_isBookmarked) {
      await _controller.setAyahBookmark(
        surah: widget.surahNumber,
        ayah: widget.ayahNumber,
        page: widget.pageNumber,
        color: _selectedColor,
        note: note.isNotEmpty ? note : null,
      );
      _showFeedback('تم حفظ الملاحظة');
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

    Share.share(
      shareContent.toString(),
      sharePositionOrigin: getSharePositionOrigin(context),
    );
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
    final arabicText = widget.ayahEntity?.textAr ?? '';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18.0,
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
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: AppRadius.borderSm,
                      border: Border.all(color: colors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      'سورة ${widget.surahName}  •  آية ${toArabicDigits(widget.ayahNumber)}  •  صـ ${toArabicDigits(widget.pageNumber)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined, size: 22.0),
                      color: colors.primary,
                      tooltip: 'مشاركة كصورة',
                      onPressed: () {
                        final ayahText = widget.ayahEntity?.textAr ?? 'آية ${widget.ayahNumber}';
                        final tafsirText = widget.ayahEntity?.tafsirMuyassar;
                        Get.to(() => AyahCardGeneratorView(
                          ayahText: ayahText,
                          surahName: 'سورة ${widget.surahName}',
                          ayahNumber: widget.ayahNumber,
                          tafsirText: tafsirText,
                        ));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22.0),
                      color: colors.textMuted,
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1.0),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
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

                  // Memorization Status Section
                  Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 18.0, color: colors.primary),
                      AppSpacing.horizontalXs,
                      Text(
                        'حالة الحفظ',
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalXs,
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('غير محدد'),
                          selected: _selectedStatus == null,
                          onSelected: (selected) {
                            if (selected) _updateMemorizeStatus(null);
                          },
                        ),
                        ...MemorizeStatus.values.map((status) {
                          final isSelected = _selectedStatus == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(
                                status.labelAr,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  color: isSelected ? Colors.white : colors.text,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: status.badgeColor,
                              backgroundColor: colors.bg,
                              avatar: CircleAvatar(
                                backgroundColor: status.badgeColor,
                                radius: 7.0,
                              ),
                              onSelected: (selected) {
                                if (selected) _updateMemorizeStatus(status);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  AppSpacing.verticalMd,

                  // Bookmark & Color Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_rounded, size: 18.0, color: colors.accent),
                            AppSpacing.horizontalXs,
                            Expanded(
                              child: Text(
                                'علامة مرجعية بلون مخصص',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleSmall?.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isBookmarked)
                            TextButton.icon(
                              onPressed: _toggleBookmark,
                              icon: Icon(Icons.bookmark_remove_rounded, size: 16.0, color: colors.error),
                              label: Text(
                                'حذف',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  color: colors.error,
                                  fontSize: 12.0,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              _showNotesInput ? Icons.note_rounded : Icons.note_add_outlined,
                              size: 20.0,
                              color: colors.accent,
                            ),
                            tooltip: 'ملاحظة',
                            onPressed: () {
                              setState(() => _showNotesInput = !_showNotesInput);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.verticalXs,
                  Wrap(
                    spacing: 8.0,
                    children: BookmarkColor.values.map((col) {
                      final isSelected = _isBookmarked && _selectedColor == col;
                      return GestureDetector(
                        onTap: () {
                          _updateColor(col);
                          if (!_isBookmarked) {
                            _toggleBookmark();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: col.color.withOpacity(isSelected ? 0.25 : 0.08),
                            borderRadius: AppRadius.borderSm,
                            border: Border.all(
                              color: isSelected ? col.color : col.color.withOpacity(0.3),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: col.color,
                                radius: 6.0,
                              ),
                              AppSpacing.horizontalXs,
                              Text(
                                col.labelAr,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 12.0,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: colors.text,
                                ),
                              ),
                              if (isSelected) ...[
                                AppSpacing.horizontalXs,
                                Icon(Icons.check_rounded, size: 14.0, color: col.color),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Note input
                  if (_showNotesInput || _isBookmarked) ...[
                    AppSpacing.verticalSm,
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: colors.text,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ملاحظة أو تدبر على هذه الآية...',
                        hintStyle: TextStyle(color: colors.textMuted, fontSize: 12.5),
                        filled: true,
                        fillColor: colors.bg,
                        contentPadding: const EdgeInsets.all(10.0),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderMd,
                          borderSide: BorderSide(color: colors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderMd,
                          borderSide: BorderSide(color: colors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderMd,
                          borderSide: BorderSide(color: colors.primary, width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.save_rounded, size: 18.0, color: colors.primary),
                          onPressed: _saveNote,
                        ),
                      ),
                    ),
                  ],

                  AppSpacing.verticalMd,

                  // Tafseer Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 18.0, color: colors.accent),
                          AppSpacing.horizontalXs,
                          Text(
                            'تفسير الآية',
                            style: textTheme.titleSmall?.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_isLoadingTafsir)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  AppSpacing.verticalXs,
                  // Tafsir Source Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TafsirSource.values.map((src) {
                        final isSel = _selectedTafsir == src;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: ChoiceChip(
                            label: Text(
                              src.title,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel ? Colors.white : colors.text,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: colors.primary,
                            backgroundColor: colors.surface,
                            onSelected: (_) => _changeTafsir(src),
                          ),
                        );
                      }).toList(),
                    ),
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
                      _loadedTafsirText != null && _loadedTafsirText!.isNotEmpty
                          ? _loadedTafsirText!
                          : 'جارٍ تحميل التفسير...',
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
