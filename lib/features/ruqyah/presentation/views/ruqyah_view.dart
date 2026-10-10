import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/responsive.dart';
import '../../data/models/ruqyah_item_model.dart';
import '../controllers/ruqyah_controller.dart';

class RuqyahView extends StatefulWidget {
  const RuqyahView({super.key});

  @override
  State<RuqyahView> createState() => _RuqyahViewState();
}

class _RuqyahViewState extends State<RuqyahView> {
  late final RuqyahController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<RuqyahController>()
        ? Get.find<RuqyahController>()
        : Get.put(RuqyahController());
  }

  void _showIndexBottomSheet(BuildContext context) {
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: colors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'فهرس آيات وأدعية الرقية',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    Obx(() => Text(
                          '${_controller.completedItemIds.length} من ${_controller.items.length} مكتمل',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 12.5,
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    return ListView.separated(
                      itemCount: _controller.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = _controller.items[idx];
                        final isCompleted = _controller.completedItemIds.contains(item.id);
                        final isCurrent = _controller.currentIndex.value == idx;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isCompleted
                                ? Colors.green.withOpacity(0.15)
                                : (isCurrent ? colors.primary.withOpacity(0.15) : colors.bg),
                            child: isCompleted
                                ? const Icon(Icons.check_rounded, color: Colors.green, size: 18)
                                : Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent ? colors.primary : colors.textMuted,
                                    ),
                                  ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? colors.primary : colors.text,
                            ),
                          ),
                          subtitle: Text(
                            item.sourceReference,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.targetCount}x',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _controller.jumpToIndex(idx);
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0.5,
          title: Text(
            'الرقية الشرعية التفاعلية',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: colors.text,
            ),
          ),
          centerTitle: true,
          actions: [
            Obx(() => IconButton(
                  icon: Text(
                    _controller.textScale.value >= 1.4
                        ? 'أ كبار'
                        : (_controller.textScale.value >= 1.2 ? 'أ+' : 'أ'),
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.primary,
                    ),
                  ),
                  tooltip: 'تكبير حجم الخط',
                  onPressed: _controller.toggleTextScale,
                )),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted_rounded, size: 22),
              tooltip: 'فهرس الرقية',
              onPressed: () => _showIndexBottomSheet(context),
            ),
          ],
        ),
        body: MaxWidthContainer(
          child: Column(
            children: [
              // 1. Category Filter Chips
              _buildCategoryChips(colors),

              // 2. Linear Progress Indicator
              _buildProgressHeader(colors),

              // 3. Main Interactive Item Card
              Expanded(
                child: Obx(() {
                  final item = _controller.currentItem;
                  if (item == null) {
                    return const Center(child: Text('لا توجد آيات في هذا القسم'));
                  }

                  return _buildItemCard(context, colors, item);
                }),
              ),

              // 4. Bottom Controls Bar
              _buildBottomControls(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(AppColorsExtension colors) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          final selected = _controller.selectedCategory.value;

          return Row(
            children: [
              _buildChip(
                label: 'الرقية الشاملة',
                isSelected: selected == null,
                onTap: () => _controller.filterByCategory(null),
                colors: colors,
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'الشفاء والعلاج',
                isSelected: selected == RuqyahCategory.shifa,
                onTap: () => _controller.filterByCategory(RuqyahCategory.shifa),
                colors: colors,
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'التحصين والحفظ',
                isSelected: selected == RuqyahCategory.tahseen,
                onTap: () => _controller.filterByCategory(RuqyahCategory.tahseen),
                colors: colors,
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'العين والحسد',
                isSelected: selected == RuqyahCategory.ainHasad,
                onTap: () => _controller.filterByCategory(RuqyahCategory.ainHasad),
                colors: colors,
              ),
              const SizedBox(width: 8),
              _buildChip(
                label: 'إبطال السحر',
                isSelected: selected == RuqyahCategory.sihrMass,
                onTap: () => _controller.filterByCategory(RuqyahCategory.sihrMass),
                colors: colors,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: colors.bg,
      labelStyle: TextStyle(
        fontFamily: AppTypography.uiFont,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : colors.text,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildProgressHeader(AppColorsExtension colors) {
    return Obx(() {
      final progress = _controller.overallProgress;
      final completed = _controller.completedItemIds.length;
      final total = _controller.items.length;
      final currentPos = _controller.currentIndex.value + 1;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: colors.surface,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الموضع: $currentPos من $total',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                Text(
                  'الإنجاز: $completed / $total (${(progress * 100).toInt()}%)',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: colors.divider.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildItemCard(BuildContext context, AppColorsExtension colors, RuqyahItem item) {
    final scale = _controller.textScale.value;
    final isCompleted = _controller.completedItemIds.contains(item.id);
    final count = _controller.currentCount.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge & Reference
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.primary.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        item.source == RuqyahSource.quran ? 'آية قرآنية كريمة' : 'دعاء نبوي مأثور',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    Text(
                      item.sourceReference,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 14.5 * scale,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                if (item.virture != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.virture!,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11.5 * scale,
                      color: colors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Main Arabic Text Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: isCompleted ? Colors.green.shade400 : colors.divider,
                width: isCompleted ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  item.arabicText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: item.source == RuqyahSource.quran
                        ? AppTypography.quranFont
                        : AppTypography.uiFont,
                    fontSize: (item.source == RuqyahSource.quran ? 21.0 : 18.0) * scale,
                    fontWeight: FontWeight.w600,
                    height: item.source == RuqyahSource.quran ? 2.1 : 1.8,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 24),

                // Interactive Counter Button
                GestureDetector(
                  onTap: _controller.tapCurrent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [Colors.green.shade700, Colors.green.shade500]
                            : [colors.primary, colors.primary.withOpacity(0.85)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted ? Colors.green : colors.primary).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCompleted) ...[
                          const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                          const SizedBox(height: 2),
                          const Text(
                            'اكتملت',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          Text(
                            '$count / ${item.targetCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'المس للقراءة',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Instruction tip
          Text(
            'المس الدائرة بعد كل قراءة، سيهتز الجهاز برفق عند إتمام التكرار المطلوب للانتقال تلقائياً.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(AppColorsExtension colors) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            Obx(() => OutlinedButton.icon(
                  onPressed: _controller.currentIndex.value > 0 ? _controller.previousItem : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  label: const Text('السابق'),
                )),

            // Reset current count
            IconButton(
              tooltip: 'إعادة تكرار هذا الموضع',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: _controller.resetCurrentItem,
            ),

            // Next Button
            Obx(() {
              final isLast = _controller.currentIndex.value >= _controller.items.length - 1;

              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLast ? null : _controller.nextItem,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('التالي'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
