import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';

enum _AppButtonVariant { primary, secondary, text }

/// Unified button component supporting primary, secondary, and text variants.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final _AppButtonVariant _variant;
  final double height;

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : _variant = _AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48.0,
  }) : _variant = _AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEnabled = onPressed != null && !isLoading;

    Widget childWidget;
    if (isLoading) {
      childWidget = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            _variant == _AppButtonVariant.primary ? Colors.white : colors.primary,
          ),
        ),
      );
    } else {
      final textWidget = Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getTextColor(colors, isEnabled),
            ),
      );

      if (icon != null) {
        childWidget = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon!,
            AppSpacing.horizontalSm,
            textWidget,
          ],
        );
      } else {
        childWidget = textWidget;
      }
    }

    Widget button;
    switch (_variant) {
      case _AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: colors.primary.withOpacity(0.38),
            elevation: 0,
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: childWidget,
        );
        break;

      case _AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(
              color: isEnabled ? colors.primary : colors.divider,
              width: 1.5,
            ),
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          ),
          child: childWidget,
        );
        break;

      case _AppButtonVariant.text:
        button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: colors.primary,
            minimumSize: Size(isFullWidth ? double.infinity : 64, height),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderMd,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          child: childWidget,
        );
        break;
    }

    return button;
  }

  Color _getTextColor(AppColorsExtension colors, bool isEnabled) {
    if (!isEnabled) return colors.textMuted;
    switch (_variant) {
      case _AppButtonVariant.primary:
        return Colors.white;
      case _AppButtonVariant.secondary:
      case _AppButtonVariant.text:
        return colors.primary;
    }
  }
}
