import 'package:flutter/material.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/app_typography.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String? imageAsset;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    this.imageAsset,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final effectiveIconColor = iconColor ?? colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: imageAsset == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            effectiveIconColor.withOpacity(colors.isDark ? 0.28 : 0.18),
                            effectiveIconColor.withOpacity(colors.isDark ? 0.10 : 0.06),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            effectiveIconColor.withOpacity(colors.isDark ? 0.16 : 0.10),
                            effectiveIconColor.withOpacity(colors.isDark ? 0.08 : 0.04),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: effectiveIconColor.withOpacity(colors.isDark ? 0.35 : 0.22),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveIconColor.withOpacity(colors.isDark ? 0.20 : 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                    if (!colors.isDark)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.7),
                        blurRadius: 3,
                        offset: const Offset(-1, -1),
                      ),
                  ],
                ),
                child: imageAsset != null
                    ? Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          imageAsset!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            icon,
                            size: 22,
                            color: effectiveIconColor,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          icon,
                          size: 22,
                          color: effectiveIconColor,
                        ),
                      ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                AppSpacing.horizontalSm,
                trailing!,
              ] else if (onTap != null) ...[
                AppSpacing.horizontalSm,
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
