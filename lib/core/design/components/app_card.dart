import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_shadows.dart';
import '../app_spacing.dart';

enum AppCardVariant {
  flat,
  elevated,
  outlined,
}

/// Unified AppCard component respecting design tokens and themes.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final AppCardVariant variant;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? customBorder;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.paddingMd,
    this.margin,
    this.variant = AppCardVariant.outlined,
    this.backgroundColor,
    this.borderRadius,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? AppRadius.borderMd;

    BoxDecoration decoration;
    switch (variant) {
      case AppCardVariant.elevated:
        decoration = BoxDecoration(
          color: backgroundColor ?? colors.surface,
          borderRadius: r,
          boxShadow: AppShadows.card(isDark),
          border: customBorder ?? Border.all(color: colors.divider.withOpacity(0.5)),
        );
        break;
      case AppCardVariant.outlined:
        decoration = BoxDecoration(
          color: backgroundColor ?? colors.surface,
          borderRadius: r,
          border: customBorder ?? Border.all(color: colors.divider, width: 1),
        );
        break;
      case AppCardVariant.flat:
        decoration = BoxDecoration(
          color: backgroundColor ?? colors.surface,
          borderRadius: r,
        );
        break;
    }

    Widget content = Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    return content;
  }
}
