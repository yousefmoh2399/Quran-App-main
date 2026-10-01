import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';
import 'package:quran_app_android/features/azkar/data/smart_azkar_service.dart';

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
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with contextual badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _currentZikr.type.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_currentZikr.type.icon, color: _currentZikr.type.color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ذكر مقترح • ${_currentZikr.type.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _currentZikr.type.color,
                    ),
                  ),
                ],
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
                    tooltip: 'مشاركة',
                    onPressed: () {
                      Share.share('${_currentZikr.text}\n\n— من أذكار تطبيق تقرّب');
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
                    label: Text(type.title, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : colors.text)),
                    selected: isSelected,
                    selectedColor: type.color,
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
