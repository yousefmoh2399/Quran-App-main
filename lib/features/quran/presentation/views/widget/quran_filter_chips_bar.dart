import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';

/// Available quick filter options for the Quran index.
enum QuranIndexFilter {
  all('الكل', Icons.view_list_rounded),
  memorized('المحفوظ', Icons.check_circle_outline_rounded),
  marked('عليها علامات', Icons.bookmark_outline_rounded);

  final String label;
  final IconData icon;
  const QuranIndexFilter(this.label, this.icon);
}

/// Quick filter chips row: [الكل / المحفوظ / عليها علامات]
class QuranFilterChipsBar extends StatelessWidget {
  final QuranIndexFilter activeFilter;
  final ValueChanged<QuranIndexFilter> onFilterChanged;
  final int? memorizedCount;
  final int? markedCount;

  const QuranFilterChipsBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    this.memorizedCount,
    this.markedCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: QuranIndexFilter.values.map((filter) {
          final isSelected = activeFilter == filter;

          String label = filter.label;
          if (filter == QuranIndexFilter.memorized && memorizedCount != null && memorizedCount! > 0) {
            label = '$label ($memorizedCount)';
          } else if (filter == QuranIndexFilter.marked && markedCount != null && markedCount! > 0) {
            label = '$label ($markedCount)';
          }

          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                isSelected ? Icons.check_rounded : filter.icon,
                size: 15,
                color: isSelected ? Colors.white : colors.textMuted,
              ),
              label: Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : colors.text,
                ),
              ),
              selected: isSelected,
              color: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.primary;
                }
                return colors.surface;
              }),
              elevation: isSelected ? 3 : 0,
              shadowColor: colors.primary.withAlpha(100),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderFull,
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
