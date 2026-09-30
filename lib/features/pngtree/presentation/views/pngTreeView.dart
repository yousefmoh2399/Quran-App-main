// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/pngtree/presentation/view_model/pngTree_view_model.dart';
import 'package:quran_app_android/features/pngtree/presentation/views/widget/modern_tasbeeh_ring.dart';

class PngTreeView extends StatelessWidget {
  const PngTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final controller = Get.isRegistered<PngTreeViewModel>()
        ? Get.find<PngTreeViewModel>()
        : Get.put(PngTreeViewModel());

    return AppScaffold(
      title: 'السبحة الإلكترونية',
      constrainContentWidth: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          color: colors.primary,
          tooltip: 'تصفير العداد',
          onPressed: () => _confirmReset(context, controller),
        ),
      ],
      body: GetBuilder<PngTreeViewModel>(
        init: controller,
        builder: (ctrl) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Zekr Selector Chips
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: PngTreeViewModel.zekrList.length,
                    separatorBuilder: (_, __) => AppSpacing.horizontalSm,
                    itemBuilder: (context, index) {
                      final isSelected = ctrl.selectedZekrIndex == index;
                      final text = PngTreeViewModel.zekrList[index];
                      return ChoiceChip(
                        label: Text(
                          text,
                          style: textTheme.labelMedium?.copyWith(
                            fontFamily: AppTypography.decorativeFont,
                            color: isSelected ? Colors.white : colors.text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: colors.primary,
                        backgroundColor: colors.surface,
                        side: BorderSide(
                          color: isSelected ? colors.primary : colors.divider,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderFull,
                        ),
                        onSelected: (_) => ctrl.setSelectedZekr(index),
                      );
                    },
                  ),
                ),
                AppSpacing.verticalMd,
                // 2. Target Selector Pills (33 / 100 / 1000)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final t in [33, 100, 1000])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        child: InkWell(
                          borderRadius: AppRadius.borderFull,
                          onTap: () => ctrl.setTarget(t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: ctrl.targetCount == t ? colors.accent : colors.surface,
                              borderRadius: AppRadius.borderFull,
                              border: Border.all(
                                color: ctrl.targetCount == t ? colors.accent : colors.divider,
                              ),
                            ),
                            child: Text(
                              t == 1000 ? 'مفتوح (١٠٠٠)' : '$t مرة',
                              style: textTheme.labelSmall?.copyWith(
                                color: ctrl.targetCount == t ? Colors.white : colors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.verticalLg,
                // 3. Central Modern Animated Ring
                ModernTasbeehRing(controller: ctrl),
                AppSpacing.verticalLg,
                // 4. Statistics Card
                AppCard(
                  variant: AppCardVariant.outlined,
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'الدورات المكتملة',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                            AppSpacing.verticalXs,
                            Text(
                              '${ctrl.counterTree}',
                              style: textTheme.headlineSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: colors.divider),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'إجمالي التسبيحات',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                            AppSpacing.verticalXs,
                            Text(
                              '${ctrl.totalTasbeeh}',
                              style: textTheme.headlineSmall?.copyWith(
                                color: colors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalLg,
                // 5. Bottom Controls (Decrement, Main Tap, Reset)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decrement button
                    IconButton.filledTonal(
                      onPressed: ctrl.counter > 0 ? () => ctrl.decreaseCounter() : null,
                      icon: const Icon(Icons.remove_rounded, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surface,
                        foregroundColor: colors.text,
                        side: BorderSide(color: colors.divider),
                        padding: AppSpacing.paddingMd,
                      ),
                      tooltip: 'إنقاص واحدة',
                    ),
                    // Large center tap button
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: ElevatedButton(
                        onPressed: () => ctrl.increaseCounter(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4,
                          shadowColor: colors.primary.withOpacity(0.4),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.fingerprint_rounded, size: 40),
                      ),
                    ),
                    // Reset button
                    IconButton.filledTonal(
                      onPressed: () => _confirmReset(context, ctrl),
                      icon: const Icon(Icons.restart_alt_rounded, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surface,
                        foregroundColor: colors.error,
                        side: BorderSide(color: colors.divider),
                        padding: AppSpacing.paddingMd,
                      ),
                      tooltip: 'تصفير العداد',
                    ),
                  ],
                ),
                AppSpacing.verticalLg,
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmReset(BuildContext context, PngTreeViewModel controller) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        title: const Text('تصفير عداد التسبيح'),
        content: const Text('هل ترغب في إعادة ضبط العداد والدورات المكتملة إلى الصفر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              controller.clearCounter();
              Navigator.pop(ctx);
            },
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
  }
}
