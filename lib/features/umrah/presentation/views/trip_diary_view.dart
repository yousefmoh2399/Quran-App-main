import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/trip_diary_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/widgets/umrah_filter_chip.dart';

class TripDiaryView extends StatefulWidget {
  const TripDiaryView({super.key});

  @override
  State<TripDiaryView> createState() => _TripDiaryViewState();
}

class _TripDiaryViewState extends State<TripDiaryView> {
  late final TripDiaryController _controller;
  late final UmrahPreferencesController _prefsController;
  final TextEditingController _searchFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(TripDiaryController());
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    Get.delete<TripDiaryController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Obx(() {
      final isElderly = _prefsController.isElderlyMode.value;
      final fontScale = _prefsController.fontMultiplier;
      final primaryColor = _prefsController.getPrimaryColor(colors.primary, isDark);
      final textColor = _prefsController.getTextColor(colors.text, isDark);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppScaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              'يوميات وخواطر الرحلة',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18 * fontScale,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 3,
            onPressed: () => _showAddOrEditDialog(context, null),
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(
              'تدوين خاطرة',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                fontWeight: FontWeight.bold,
                fontSize: 14 * fontScale,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: TextField(
                    controller: _searchFieldController,
                    onChanged: (val) => _controller.onSearchChanged(val),
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 14 * fontScale,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في خواطرك وملاحظاتك...',
                      hintStyle: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        color: colors.textMuted,
                        fontSize: 13 * fontScale,
                      ),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      suffixIcon: _searchFieldController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchFieldController.clear();
                                _controller.onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                    ),
                  ),
                ),

                // Category Filter Chips
                SizedBox(
                  height: isElderly ? 56 : 46,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: TripDiaryController.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final category = TripDiaryController.categories[index];
                      final isSelected = _controller.selectedCategory.value == category;

                      return UmrahFilterChip(
                        label: category,
                        isSelected: isSelected,
                        fontScale: fontScale,
                        isElderly: isElderly,
                        onTap: () => _controller.setCategory(category),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // Notes List or Empty State
                Expanded(
                  child: Builder(builder: (context) {
                    if (_controller.isLoading.value) {
                      return Center(child: CircularProgressIndicator(color: primaryColor));
                    }

                    if (_controller.entries.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                size: isElderly ? 70 : 54,
                                color: colors.textMuted.withAlpha(120),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _searchFieldController.text.isNotEmpty
                                    ? 'لا توجد نتائج مطابقة لبحثك'
                                    : 'سجّل مشاعرك وأدعيتك في رحاب البيت الحرام',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 16 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ملاحظاتك تحفظ محلياً على جهازك بالكامل ومشمولة في النسخ الاحتياطي.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 13 * fontScale,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _controller.entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final entry = _controller.entries[index];
                        return _buildEntryCard(
                          entry,
                          colors,
                          primaryColor,
                          textColor,
                          fontScale,
                          isElderly,
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEntryCard(
    TripDiaryEntry entry,
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    final dateStr = DateFormat('yyyy/MM/dd - hh:mm a').format(entry.createdAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  entry.category,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 11 * fontScale,
                  color: colors.textMuted,
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: colors.textMuted),
                onSelected: (val) {
                  if (val == 'copy') {
                    Clipboard.setData(
                      ClipboardData(text: '${entry.title}\n\n${entry.content}'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم نسخ الخاطرة إلى الحافظة'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else if (val == 'edit') {
                    _showAddOrEditDialog(context, entry);
                  } else if (val == 'delete' && entry.id != null) {
                    _confirmDelete(context, entry.id!);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'copy',
                    child: Text('نسخ النص'),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('تعديل الخاطرة'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.title,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: (isElderly ? 18 : 16) * fontScale,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.content,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 14 * fontScale,
              color: textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditDialog(BuildContext context, TripDiaryEntry? existing) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');
    String currentCategory = existing?.category ?? 'مشاعر وروحانيات';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final colors = ctx.appColors;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'تدوين خاطرة جديدة' : 'تعديل الخاطرة',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'عنوان الخاطرة أو الموقف',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: currentCategory,
                      decoration: InputDecoration(
                        labelText: 'التصنيف',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      items: TripDiaryController.categories
                          .where((c) => c != 'الكل')
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => currentCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'اكتب مشاعرك ودعاءك...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final content = contentController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى كتابة عنوان للخاطرة')),
                          );
                          return;
                        }
                        if (content.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى كتابة نص الخاطرة أو الملاحظة')),
                          );
                          return;
                        }

                        if (existing == null) {
                          _controller.addEntry(
                            title: title,
                            content: content,
                            category: currentCategory,
                          );
                        } else {
                          _controller.updateEntry(
                            existing.copyWith(
                              title: title,
                              content: content,
                              category: currentCategory,
                            ),
                          );
                        }
                        Navigator.of(ctx).pop();
                      },
                      child: Text(existing == null ? 'حفظ الخاطرة' : 'تحديث الخاطرة'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الخاطرة'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذه الخاطرة نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.deleteEntry(id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
