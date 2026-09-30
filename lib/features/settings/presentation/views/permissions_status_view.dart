import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/permissions/app_permission_status.dart';
import '../../../../core/permissions/app_permission_type.dart';
import '../../../../core/permissions/permission_service.dart';

class PermissionsStatusView extends StatefulWidget {
  const PermissionsStatusView({super.key});

  @override
  State<PermissionsStatusView> createState() => _PermissionsStatusViewState();
}

class _PermissionsStatusViewState extends State<PermissionsStatusView> {
  final PermissionService _service = PermissionService.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _service.refreshAll();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('حالة الصلاحيات'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'إعادة الفحص',
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refresh,
          ),
        ],
      ),
      body: ValueListenableBuilder<Map<AppPermissionType, AppPermissionStatus>>(
        valueListenable: _service.statuses,
        builder: (context, statuses, _) {
          final totalApplicable = AppPermissionType.values
              .where((t) => statuses[t] != AppPermissionStatus.notApplicable)
              .length;
          final totalGranted = AppPermissionType.values
              .where((t) => statuses[t]?.isGranted == true)
              .length;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (totalGranted == totalApplicable)
                            ? Colors.green.withOpacity(0.12)
                            : colors.accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (totalGranted == totalApplicable)
                            ? Icons.verified_user
                            : Icons.security,
                        color: (totalGranted == totalApplicable)
                            ? Colors.green
                            : colors.accent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalGranted == totalApplicable
                                ? 'جميع الصلاحيات مكتملة'
                                : 'صلاحيات بحاجة لتفعيل ($totalGranted/$totalApplicable)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalGranted == totalApplicable
                                ? 'التطبيق جاهز لتشغيل الأذان والمواقيت بدقة عالية.'
                                : 'فعّل الصلاحيات غير المكتملة لضمان دقة الأذان في موعده.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'قائمة الصلاحيات',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              for (final type in AppPermissionType.values)
                _PermissionCard(
                  type: type,
                  status: statuses[type] ?? AppPermissionStatus.denied,
                  onAction: () async {
                    final current = statuses[type];
                    if (current?.isPermanentlyDenied == true) {
                      await _service.openSettings(type);
                    } else {
                      await _service.requestPermission(type, force: true);
                    }
                    await _refresh();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final AppPermissionType type;
  final AppPermissionStatus status;
  final VoidCallback onAction;

  const _PermissionCard({
    required this.type,
    required this.status,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    if (status == AppPermissionStatus.notApplicable) {
      return const SizedBox.shrink();
    }

    final isGranted = status.isGranted;
    final isPermanent = status.isPermanentlyDenied;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGranted
                      ? Colors.green.withOpacity(0.12)
                      : colors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  type.icon,
                  size: 22,
                  color: isGranted ? Colors.green : colors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  type.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
              ),
              _buildStatusBadge(context),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(right: 38.0),
            child: Text(
              type.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  isPermanent ? Icons.settings : Icons.check,
                  size: 16,
                ),
                label: Text(isPermanent ? 'فتح الإعدادات' : 'تفعيل الإذن'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final colors = context.appColors;

    if (status.isGranted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'مُفعّلة',
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (status.isPermanentlyDenied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'مرفوضة من الإعدادات',
          style: TextStyle(
            color: colors.error,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'غير مُفعّلة',
        style: TextStyle(
          color: colors.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
