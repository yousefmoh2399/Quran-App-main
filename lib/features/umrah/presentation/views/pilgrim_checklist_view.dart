import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/data/services/guide_engine.dart';
import 'package:quran_app_android/features/umrah/presentation/controllers/umrah_preferences_controller.dart';
import 'package:quran_app_android/features/umrah/presentation/widgets/umrah_filter_chip.dart';

class PilgrimChecklistView extends StatefulWidget {
  const PilgrimChecklistView({super.key});

  @override
  State<PilgrimChecklistView> createState() => _PilgrimChecklistViewState();
}

class _PilgrimChecklistViewState extends State<PilgrimChecklistView> {
  final GuideEngine _guideEngine = GuideEngine();
  late final UmrahPreferencesController _prefsController;

  final RxList<PilgrimChecklistItem> _items = <PilgrimChecklistItem>[].obs;
  final RxString _selectedCategory = 'الكل'.obs;
  final RxBool _isLoading = true.obs;

  static const List<String> categories = [
    'الكل',
    'ملابس الإحرام',
    'المستندات',
    'الحقيبة الطبية',
    'الأغراض الشخصية',
    'سنن قبل الإحرام',
  ];

  @override
  void initState() {
    super.initState();
    _prefsController = Get.isRegistered<UmrahPreferencesController>()
        ? Get.find<UmrahPreferencesController>()
        : Get.put(UmrahPreferencesController());
    _loadItems();
  }

  Future<void> _loadItems() async {
    _isLoading.value = true;
    try {
      final data = await _guideEngine.getChecklistItems();
      _items.assignAll(data);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _toggleItem(PilgrimChecklistItem item) async {
    final newChecked = !item.isChecked;
    if (newChecked) {
      AppHaptics.itemCompleted();
    } else {
      AppHaptics.selection();
    }

    final updated = item.copyWith(isChecked: newChecked);
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _items[idx] = updated;
    }

    await _guideEngine.toggleChecklistItem(item.id, newChecked);

    // If all are completed
    if (_items.every((i) => i.isChecked)) {
      AppHaptics.cycleCompleted();
    }
  }

  Future<void> _showAddItemDialog() async {
    final titleCtrl = TextEditingController();
    String selectedCat = 'ملابس الإحرام';

    await showModalBottomSheet(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'إضافة غرض جديد للحقيبة',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'اسم الغرض أو التجهيز...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration: InputDecoration(
                      labelText: 'التصنيف',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    items: categories
                        .where((c) => c != 'الكل')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => selectedCat = val);
                      }
                    },
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
                    onPressed: () async {
                      final text = titleCtrl.text.trim();
                      if (text.isEmpty) return;

                      final newItem = PilgrimChecklistItem(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        title: text,
                        category: selectedCat,
                        isCustom: true,
                        createdAt: DateTime.now(),
                      );

                      await _guideEngine.addChecklistItem(newItem);
                      _items.add(newItem);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('إضافة إلى الحقيبة', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إعادة تعيين القائمة'),
          content: const Text('هل ترغب في إلغاء تحديد كافة الأغراض للبدء من جديد؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إعادة تعيين', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _guideEngine.resetChecklist();
      await _loadItems();
    }
  }

  List<PilgrimChecklistItem> get _filteredItems {
    final cat = _selectedCategory.value;
    if (cat == 'الكل') return _items;
    return _items.where((i) => i.category == cat).toList();
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

      final total = _items.length;
      final checked = _items.where((i) => i.isChecked).length;
      final percent = total > 0 ? (checked / total) : 0.0;

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AppScaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            title: Text(
              'حقيبة وتجهيزات الحاج والمعتمر',
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
            actions: [
              IconButton(
                tooltip: 'إعادة تعيين',
                icon: Icon(Icons.restart_alt_rounded, color: textColor),
                onPressed: _confirmReset,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة غرض', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Progress Summary Card
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: colors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نسبة جاهزية الحقيبة والسنن',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * fontScale,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '$checked من $total (${(percent * 100).toInt()}%)',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * fontScale,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          backgroundColor: colors.divider.withAlpha(80),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            percent >= 1.0 ? Colors.green : primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Chips
                SizedBox(
                  height: isElderly ? 58 : 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategory.value == cat;

                      return UmrahFilterChip(
                        label: cat,
                        isSelected: isSelected,
                        fontScale: fontScale,
                        isElderly: isElderly,
                        onTap: () => _selectedCategory.value = cat,
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // Items List
                Expanded(
                  child: Builder(builder: (context) {
                    if (_isLoading.value) {
                      return Center(child: CircularProgressIndicator(color: primaryColor));
                    }

                    final list = _filteredItems;
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'لا توجد عناصر في هذا التصنيف',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            color: colors.textMuted,
                            fontSize: 15 * fontScale,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        top: AppSpacing.sm,
                        bottom: 80, // spacing for FAB
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return _buildItemTile(
                          item,
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

  Widget _buildItemTile(
    PilgrimChecklistItem item,
    AppColorsExtension colors,
    Color primaryColor,
    Color textColor,
    double fontScale,
    bool isElderly,
  ) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => _toggleItem(item),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: (isElderly ? 14 : 10),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: item.isChecked ? primaryColor.withAlpha(120) : colors.divider,
            ),
          ),
          child: Row(
            children: [
              // Custom Animated Checkbox Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isElderly ? 28 : 24,
                height: isElderly ? 28 : 24,
                decoration: BoxDecoration(
                  color: item.isChecked ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: item.isChecked ? primaryColor : colors.textMuted,
                    width: 2,
                  ),
                ),
                child: item.isChecked
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: (isElderly ? 16 : 14) * fontScale,
                        fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w600,
                        color: item.isChecked ? colors.textMuted : textColor,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      item.category,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11 * fontScale,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isCustom)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () async {
                    await _guideEngine.deleteChecklistItem(item.id);
                    _items.removeWhere((i) => i.id == item.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
