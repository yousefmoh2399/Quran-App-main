import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/features/azkar/data/models/azkar_model.dart';
import 'package:quran_app_android/features/azkar/presentation/view_model/azkar_view_model.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widget/azkar_circular_counter.dart';
import 'package:share_plus/share_plus.dart';

class AzkarItemCard extends StatefulWidget {
  final ArrayAzkarModel model;
  final AzkarViewModel controller;
  final int itemIndex;
  final int totalItems;

  const AzkarItemCard({
    super.key,
    required this.model,
    required this.controller,
    required this.itemIndex,
    required this.totalItems,
  });

  @override
  State<AzkarItemCard> createState() => _AzkarItemCardState();
}

class _AzkarItemCardState extends State<AzkarItemCard> {
  late int _remaining;
  late final int _target;

  @override
  void initState() {
    super.initState();
    _target = widget.model.count ?? 1;
    _remaining = _target;
  }

  void _decrement() {
    if (_remaining > 0) {
      setState(() {
        _remaining--;
      });
    }
  }

  void _reset() {
    setState(() {
      _remaining = _target;
    });
  }

  String _cleanText(String text) {
    return text.replaceAll('(', '').replaceAll(')', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final cleanedText = _cleanText(widget.model.text ?? '');

    return AppCard(
      variant: AppCardVariant.elevated,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar: Progress indicator (e.g. 1 / 5) and font size adjusters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  '${widget.itemIndex + 1} من ${widget.totalItems}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.text_increase_rounded, size: 20),
                    color: colors.textMuted,
                    tooltip: 'تكبير الخط',
                    onPressed: () => widget.controller.increaseFont(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_decrease_rounded, size: 20),
                    color: colors.textMuted,
                    tooltip: 'تصغير الخط',
                    onPressed: () => widget.controller.decreaseFont(),
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.verticalMd,
          // Scrollable zekr text area
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    cleanedText,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: AppTypography.decorativeFont,
                      fontSize: widget.controller.fontSize,
                      height: 1.8,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AppSpacing.verticalMd,
          // Circular counter with smooth animation
          Center(
            child: AzkarCircularCounter(
              targetCount: _target,
              remainingCount: _remaining,
              onTap: _decrement,
              onReset: _reset,
            ),
          ),
          AppSpacing.verticalMd,
          Divider(color: colors.divider, height: 1),
          AppSpacing.verticalSm,
          // Bottom action buttons: share & copy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cleanedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'تم نسخ الذكر بنجاح',
                        style: TextStyle(fontFamily: AppTypography.uiFont),
                      ),
                      backgroundColor: colors.primary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderMd,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.copy_rounded, size: 18, color: colors.primary),
                label: Text(
                  'نسخ',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: colors.divider),
              TextButton.icon(
                onPressed: () async {
                  await Share.share(
                    cleanedText,
                    sharePositionOrigin: Rect.fromPoints(
                      const Offset(2, 2),
                      const Offset(3, 3),
                    ),
                  );
                },
                icon: Icon(Icons.share_rounded, size: 18, color: colors.primary),
                label: Text(
                  'مشاركة',
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
