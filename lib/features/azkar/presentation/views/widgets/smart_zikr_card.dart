import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/features/azkar/data/smart_azkar_service.dart';
import 'package:quran_app_android/features/azkar/presentation/views/widgets/zikr_image_share_dialog.dart';

class SmartZikrCard extends StatefulWidget {
  const SmartZikrCard({super.key});

  @override
  State<SmartZikrCard> createState() => _SmartZikrCardState();
}

class _SmartZikrCardState extends State<SmartZikrCard> {
  final SmartAzkarService _service = SmartAzkarService.instance;
  late ContextualZikr _currentZikr;

  @override
  void initState() {
    super.initState();
    _currentZikr = _service.getZikrForCurrentTime();
  }

  void _switchContext(ZikrContextType type) {
    HapticFeedback.selectionClick();
    final list = _service.getAzkarForType(type);
    if (list.isNotEmpty) {
      setState(() => _currentZikr = list.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      variant: AppCardVariant.elevated,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with contextual badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_currentZikr.type.icon, color: colors.primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ذكر مقترح • ${_currentZikr.type.title}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: colors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: colors.textMuted,
                    tooltip: 'نسخ الذكر',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _currentZikr.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ الذكر إلى الحافظة')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    color: colors.textMuted,
                    tooltip: 'مشاركة الذكر كصورة أو نص',
                    onPressed: () {
                      ZikrShareHelper.showShareOptions(
                        context,
                        zikrText: _currentZikr.text,
                        virtue: _currentZikr.virture,
                        categoryTitle: 'ذكر مقترح • ${_currentZikr.type.title}',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Zikr Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: colors.divider.withOpacity(0.6)),
            ),
            child: Column(
              children: [
                Text(
                  _currentZikr.text,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppTypography.decorativeFont,
                    fontSize: 16,
                    height: 1.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentZikr.virture != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _currentZikr.virture!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          AppSpacing.verticalMd,

          // Quick Filter Chips (Horizontal)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ZikrContextType.values.map((type) {
                final isSelected = _currentZikr.type == type;
                return Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: FilterChip(
                    label: Text(
                      type.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colors.primary : colors.textMuted,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colors.primary.withOpacity(0.15),
                    checkmarkColor: colors.primary,
                    side: BorderSide(
                      color: isSelected ? colors.primary : colors.divider.withOpacity(0.6),
                    ),
                    backgroundColor: colors.surface,
                    onSelected: (_) => _switchContext(type),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
