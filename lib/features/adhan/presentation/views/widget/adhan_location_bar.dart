import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/core/design/components/app_button.dart';
import 'package:quran_app_android/core/design/components/app_card.dart';

class AdhanLocationBar extends StatelessWidget {
  final bool isDefaultLocation;
  final bool isLoading;
  final VoidCallback onRefreshLocation;

  const AdhanLocationBar({
    super.key,
    required this.isDefaultLocation,
    required this.isLoading,
    required this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: AppSpacing.paddingMd,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDefaultLocation
                      ? colors.accent.withOpacity(0.15)
                      : colors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDefaultLocation
                      ? Icons.location_city_rounded
                      : Icons.my_location_rounded,
                  size: 20,
                  color: isDefaultLocation ? colors.accent : colors.primary,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isDefaultLocation ? 'القاهرة، مصر' : 'الموقع الجغرافي المحدد',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        if (isDefaultLocation) ...[
                          AppSpacing.horizontalXs,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'موقع تقريبي',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'الهيئة المصرية للمساحة • المذهب الشافعي',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                )
              else
                IconButton(
                  onPressed: onRefreshLocation,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: colors.primary,
                  ),
                  tooltip: 'تحديث الموقع عبر GPS',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (isDefaultLocation) ...[
            AppSpacing.verticalSm,
            Divider(height: 1, color: colors.divider),
            AppSpacing.verticalSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'لتحديد المواقيت بدقة حسب إحداثياتك الحالية:',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                AppSpacing.horizontalSm,
                AppButton.secondary(
                  label: 'تحديث بالـ GPS',
                  icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                  isLoading: isLoading,
                  onPressed: onRefreshLocation,
                  height: 36,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
