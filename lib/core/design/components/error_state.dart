import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import 'app_button.dart';

/// Unified ErrorState component with clear message and retry action.
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    this.title = 'حدث خطأ غير متوقع',
    required this.message,
    this.retryLabel = 'إعادة المحاولة',
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
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
                color: colors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: colors.error,
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
            if (onRetry != null) ...[
              AppSpacing.verticalXl,
              AppButton.primary(
                label: retryLabel,
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
