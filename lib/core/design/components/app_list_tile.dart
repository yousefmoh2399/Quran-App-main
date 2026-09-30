import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';

/// Unified AppListTile component providing consistent padding, ripple feedback, and typography.
class AppListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final tileColor = selected
        ? colors.primary.withOpacity(0.08)
        : (backgroundColor ?? Colors.transparent);

    return Material(
      color: tileColor,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                AppSpacing.horizontalMd,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: selected ? colors.primary : colors.text,
                            fontWeight: FontWeight.w600,
                          ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: colors.textMuted,
                            ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                AppSpacing.horizontalSm,
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
