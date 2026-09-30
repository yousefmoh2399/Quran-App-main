import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/user_models.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../controllers/mushaf_controller.dart';
import '../utils/mushaf_utils.dart';

/// Modal bottom sheet for configuring bookmark, memorization status, and notes for a Mushaf page.
class PageBookmarkBottomSheet extends StatefulWidget {
  final int pageNumber;
  final String surahName;

  const PageBookmarkBottomSheet({
    super.key,
    required this.pageNumber,
    required this.surahName,
  });

  static Future<void> show(BuildContext context, int pageNumber, String surahName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PageBookmarkBottomSheet(
        pageNumber: pageNumber,
        surahName: surahName,
      ),
    );
  }

  @override
  State<PageBookmarkBottomSheet> createState() => _PageBookmarkBottomSheetState();
}

class _PageBookmarkBottomSheetState extends State<PageBookmarkBottomSheet> {
  final MushafController _controller = Get.find<MushafController>();
  late TextEditingController _noteController;

  BookmarkColor? _selectedColor;
  MemorizeStatus? _selectedStatus;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    final currentBookmark = _controller.getPageBookmark(widget.pageNumber);
    final currentMemorized = _controller.getPageMemorized(widget.pageNumber);

    _isBookmarked = currentBookmark != null;
    _selectedColor = currentBookmark?.color ?? BookmarkColor.gold;
    _selectedStatus = currentMemorized?.status;
    _noteController = TextEditingController(text: currentBookmark?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final note = _noteController.text.trim();

    if (_isBookmarked && _selectedColor != null) {
      await _controller.setPageBookmark(
        pageNumber: widget.pageNumber,
        color: _selectedColor!,
        note: note.isNotEmpty ? note : null,
      );
    } else {
      await _controller.removePageBookmark(widget.pageNumber);
    }

    await _controller.setPageMemorizeStatus(widget.pageNumber, _selectedStatus);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث بيانات الصفحة ${toArabicDigits(widget.pageNumber)} بنجاح',
            style: const TextStyle(fontFamily: AppTypography.uiFont),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeAll() async {
    await _controller.removePageBookmark(widget.pageNumber);
    await _controller.setPageMemorizeStatus(widget.pageNumber, null);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تمت إزالة علامة وحالة الصفحة ${toArabicDigits(widget.pageNumber)}',
            style: const TextStyle(fontFamily: AppTypography.uiFont),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 14.0,
        bottom: bottomInset + 16.0,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40.0,
                height: 4.5,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
            ),
            AppSpacing.verticalSm,

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark_rounded, color: colors.accent, size: 22.0),
                    AppSpacing.horizontalXs,
                    Text(
                      'صفحة ${toArabicDigits(widget.pageNumber)}  •  سورة ${widget.surahName}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22.0),
                  color: colors.textMuted,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 18.0),

            // Bookmark Toggle & Ribbon Color
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'علامة مرجعية (شريط)',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                Switch.adaptive(
                  value: _isBookmarked,
                  activeColor: colors.primary,
                  onChanged: (val) {
                    setState(() {
                      _isBookmarked = val;
                      if (val && _selectedColor == null) {
                        _selectedColor = BookmarkColor.gold;
                      }
                    });
                  },
                ),
              ],
            ),

            if (_isBookmarked) ...[
              AppSpacing.verticalXs,
              Text(
                'اختر لون الشريط المرجعي:',
                style: textTheme.labelMedium?.copyWith(color: colors.textMuted),
              ),
              AppSpacing.verticalXs,
              Wrap(
                spacing: 10.0,
                children: BookmarkColor.values.map((colorEnum) {
                  final isSelected = _selectedColor == colorEnum;
                  return ChoiceChip(
                    label: Text(
                      colorEnum.labelAr,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: isSelected ? Colors.white : colors.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colorEnum.color,
                    backgroundColor: colors.bg,
                    avatar: CircleAvatar(
                      backgroundColor: colorEnum.color,
                      radius: 8.0,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedColor = colorEnum);
                      }
                    },
                  );
                }).toList(),
              ),
            ],

            AppSpacing.verticalMd,

            // Memorization Status
            Text(
              'حالة حفظ الصفحة',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            AppSpacing.verticalXs,
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ChoiceChip(
                  label: const Text('غير محدد'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatus = null);
                  },
                ),
                ...MemorizeStatus.values.map((st) {
                  final isSelected = _selectedStatus == st;
                  return ChoiceChip(
                    label: Text(
                      st.labelAr,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: isSelected ? Colors.white : colors.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: st.badgeColor,
                    backgroundColor: colors.bg,
                    avatar: CircleAvatar(
                      backgroundColor: st.badgeColor,
                      radius: 8.0,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = st);
                      }
                    },
                  );
                }),
              ],
            ),

            AppSpacing.verticalMd,

            // Note input
            Text(
              'ملاحظة / تدبر على الصفحة',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            AppSpacing.verticalXs,
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                color: colors.text,
                fontSize: 14.0,
              ),
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظة أو فائدة...',
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 13.0),
                filled: true,
                fillColor: colors.bg,
                contentPadding: const EdgeInsets.all(12.0),
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
              ),
            ),

            AppSpacing.verticalLg,

            // Action Buttons
            Row(
              children: [
                if (_isBookmarked || _selectedStatus != null)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        side: BorderSide(color: colors.error.withOpacity(0.5)),
                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      ),
                      onPressed: _removeAll,
                      child: Text(
                        'إزالة',
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTypography.uiFont,
                        ),
                      ),
                    ),
                  ),
                if (_isBookmarked || _selectedStatus != null) AppSpacing.horizontalSm,
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13.0),
                      elevation: 0,
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    ),
                    onPressed: _saveChanges,
                    child: const Text(
                      'حفظ التغييرات',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTypography.uiFont,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
