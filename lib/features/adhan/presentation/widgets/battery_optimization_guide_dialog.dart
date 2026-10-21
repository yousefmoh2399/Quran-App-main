import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_typography.dart';
import 'package:quran_app_android/features/adhan/presentation/services/adhan_battery_permission_service.dart';
import 'package:quran_app_android/features/adhan/presentation/services/device_brand_guide_service.dart';

class BatteryOptimizationGuideDialog extends StatefulWidget {
  final VoidCallback? onSettingsCompleted;

  const BatteryOptimizationGuideDialog({
    super.key,
    this.onSettingsCompleted,
  });

  /// Displays the interactive brand-specific battery guide bottom sheet
  static Future<void> show(BuildContext context, {VoidCallback? onSettingsCompleted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BatteryOptimizationGuideDialog(
        onSettingsCompleted: onSettingsCompleted,
      ),
    );
  }

  @override
  State<BatteryOptimizationGuideDialog> createState() => _BatteryOptimizationGuideDialogState();
}

class _BatteryOptimizationGuideDialogState extends State<BatteryOptimizationGuideDialog>
    with WidgetsBindingObserver {
  BrandGuideInfo? _brandInfo;
  bool _isLoading = true;
  bool _isRequestingDirect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBrandInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBrandInfo() async {
    final info = await DeviceBrandGuideService.getBrandInfo();
    if (mounted) {
      setState(() {
        _brandInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatusOnResume();
    }
  }

  Future<void> _checkStatusOnResume() async {
    final status = await AdhanBatteryPermissionService.checkStatus();
    if (status.isBatteryIgnored && mounted) {
      Navigator.of(context).pop();
      widget.onSettingsCompleted?.call();
      Fluttertoast.showToast(
        msg: 'تم تفعيل عمل الأذان في الخلفية بنجاح 🔔✅',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF0F5C4A),
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> _handleDirectRequest() async {
    setState(() => _isRequestingDirect = true);
    await DeviceBrandGuideService.requestDirectSystemExemption();
    await Future.delayed(const Duration(milliseconds: 500));
    final status = await AdhanBatteryPermissionService.checkStatus();
    if (mounted) {
      setState(() => _isRequestingDirect = false);
      if (status.isBatteryIgnored) {
        Navigator.of(context).pop();
        widget.onSettingsCompleted?.call();
        Fluttertoast.showToast(
          msg: 'تم تفعيل عمل الأذان في الخلفية بنجاح 🔔✅',
          backgroundColor: const Color(0xFF0F5C4A),
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'يرجى تطبيق الخطوتين بالأسفل في صفحة الإعدادات',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    }
  }

  Future<void> _handleOpenSettings() async {
    if (_brandInfo != null) {
      await DeviceBrandGuideService.openOptimalSettings(_brandInfo!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isLoading
            ? const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Drag Indicator
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.divider.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Device Brand Header Badge
                    Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: size.width - 48),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.primary.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'هاتفك: ${_brandInfo?.displayName ?? "Android"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dialog Title
                    Text(
                      'لضمان سماع الأذان دائماً في وقته 🔔',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: AppTypography.decorativeFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: colors.text,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'يقوم نظام هاتفك بتعليق التطبيقات لتوفير الشحن. اتبع هذه الخطوات البسيطة حتى ينطلق الأذان وشاشتك مقفلة:',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12.5,
                        color: colors.textMuted,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Steps Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: AppRadius.borderMd,
                        border: Border.all(color: colors.divider.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          for (final step in _brandInfo?.steps ?? []) ...[
                            _buildStepRow(step, colors),
                            if (step != _brandInfo?.steps.last)
                              Divider(color: colors.divider.withOpacity(0.3), height: 16),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Tip Callout
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 20,
                            color: Color(0xFFD4AF37),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _brandInfo?.summaryTip ?? 'اختر غير مقيد لاستخدام البطارية',
                              style: TextStyle(
                                fontFamily: AppTypography.uiFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Button 1: Open Settings Now (Primary)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.settings_suggest_rounded, size: 20),
                      label: const Text(
                        'فتح الإعدادات الآن وتطبيق الخطوات 🚀',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: _handleOpenSettings,
                    ),
                    const SizedBox(height: 10),

                    // Action Button 2: Direct System Prompt
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primary.withOpacity(0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                      ),
                      icon: _isRequestingDirect
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.flash_on_rounded, size: 18),
                      label: const Text(
                        'طلب الإذن المباشر من النظام ⚡ (سماح)',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: _isRequestingDirect ? null : _handleDirectRequest,
                    ),
                    const SizedBox(height: 6),

                    // Dismiss Later
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'لاحقاً',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepRow(GuideStep step, AppColorsExtension colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${step.number}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (step.badgeText != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        step.badgeText!,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                step.subtitle,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 11.5,
                  color: colors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
