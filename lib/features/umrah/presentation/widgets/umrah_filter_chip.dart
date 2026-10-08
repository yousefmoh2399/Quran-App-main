import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';

/// Highly visible, distinct filter and selection chip for Umrah & Hajj views.
/// Provides prominent visual feedback (contrast, checkmark, glow) when selected.
class UmrahFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final double fontScale;
  final bool isElderly;

  const UmrahFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.fontScale = 1.0,
    this.isElderly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primaryColor = colors.primary;

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: (isElderly ? 16.0 : 12.0),
              vertical: (isElderly ? 10.0 : 7.0),
            ),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: isSelected ? primaryColor : colors.divider,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                ] else if (icon != null) ...[
                  Icon(
                    icon,
                    size: 15,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: (isElderly ? 15 : 12.5) * fontScale,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : colors.text,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
