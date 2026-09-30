import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import 'app_button.dart';

/// Unified EmptyState component for empty lists, search results, bookmarks, etc.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: colors.primary,
              ),
            ),
            AppSpacing.verticalLg,
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: AppTypography.decorativeFont,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
            ),
            AppSpacing.verticalSm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              AppSpacing.verticalXl,
              AppButton.secondary(
                label: actionLabel!,
                onPressed: onActionPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
