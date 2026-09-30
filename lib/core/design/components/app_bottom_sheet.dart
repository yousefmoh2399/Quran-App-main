import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../responsive.dart';

/// Unified AppBottomSheet component with drag handle, title, and responsive max width.
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
  });

  /// Static helper to display a consistent modal bottom sheet across the app.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MaxWidthContainer(
        child: AppBottomSheet(
          title: title,
          actions: actions,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: AppRadius.radiusXl),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: AppRadius.borderFull,
                ),
              ),
            ),
            // Header with optional title
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
              Divider(color: colors.divider, height: 1),
            ],
            // Sheet body content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
