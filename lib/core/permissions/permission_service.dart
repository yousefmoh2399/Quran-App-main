import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_permission_status.dart';
import 'app_permission_type.dart';
import 'permission_platform_adapter.dart';

class PermissionService with WidgetsBindingObserver {
  static PermissionService? _instance;
  static PermissionService get instance =>
      _instance ??= PermissionService(adapter: LivePermissionPlatformAdapter());

  final PermissionPlatformAdapter adapter;
  SharedPreferences? _prefs;

  final ValueNotifier<Map<AppPermissionType, AppPermissionStatus>> statuses =
      ValueNotifier<Map<AppPermissionType, AppPermissionStatus>>({
    for (final type in AppPermissionType.values)
      type: AppPermissionStatus.denied,
  });

  final Set<AppPermissionType> _promptedThisSession = {};
  static const int cooldownDays = 7;
  static const String _laterPrefix = 'permission_later_timestamp_';

  PermissionService({
    required this.adapter,
    SharedPreferences? prefs,
    bool registerObserver = true,
  }) : _prefs = prefs {
    if (registerObserver) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  /// Factory or custom initializer for testing or early startup
  static void setInstance(PermissionService service) {
    _instance = service;
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await refreshAll();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    statuses.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshAll();
    }
  }

  AppPermissionStatus getStatus(AppPermissionType type) {
    return statuses.value[type] ?? AppPermissionStatus.denied;
  }

  bool isGranted(AppPermissionType type) {
    return getStatus(type).isGranted;
  }

  bool wasPromptedThisSession(AppPermissionType type) {
    return _promptedThisSession.contains(type);
  }

  void markPromptedThisSession(AppPermissionType type) {
    _promptedThisSession.add(type);
  }

  void resetSession() {
    _promptedThisSession.clear();
  }

  bool isInCooldown(AppPermissionType type) {
    if (_prefs == null) return false;
    final timestamp = _prefs!.getInt('$_laterPrefix${type.name}');
    if (timestamp == null) return false;

    final recordedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(recordedDate);
    return diff.inDays < cooldownDays;
  }

  Future<void> recordLater(AppPermissionType type) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(
      '$_laterPrefix${type.name}',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clearCooldown(AppPermissionType type) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove('$_laterPrefix${type.name}');
  }

  Future<Map<AppPermissionType, AppPermissionStatus>> refreshAll() async {
    final updated = Map<AppPermissionType, AppPermissionStatus>.from(statuses.value);
    for (final type in AppPermissionType.values) {
      updated[type] = await adapter.checkStatus(type);
    }
    statuses.value = updated;
    return updated;
  }

  Future<AppPermissionStatus> requestPermission(
    AppPermissionType type, {
    bool force = false,
  }) async {
    final status = await adapter.request(type);
    final updated = Map<AppPermissionType, AppPermissionStatus>.from(statuses.value);
    updated[type] = status;
    statuses.value = updated;

    if (status.isGranted) {
      await clearCooldown(type);
    }
    return status;
  }

  Future<bool> openSettings(AppPermissionType type) async {
    final success = await adapter.openSettings(type);
    return success;
  }

  Future<bool> openVendorAutoStart() async {
    return await adapter.openVendorAutoStart();
  }

  /// Contextual presentation rule:
  /// - Max once per session per permission
  /// - 7-day cooldown on "later"
  /// - Never prompts if already granted
  /// - Prompts with contextual explanation and system settings option if permanentlyDenied
  Future<bool> requestWithRationale(
    BuildContext context,
    AppPermissionType type, {
    bool force = false,
  }) async {
    final currentStatus = await adapter.checkStatus(type);
    if (currentStatus.isGranted) return true;

    if (!force) {
      if (wasPromptedThisSession(type)) return false;
      if (isInCooldown(type)) return false;
    }

    markPromptedThisSession(type);

    if (!context.mounted) return false;

    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionRationaleBottomSheet(
        type: type,
        status: currentStatus,
        onGrant: () async {
          Navigator.of(ctx).pop(true);
        },
        onLater: () async {
          await recordLater(type);
          if (ctx.mounted) {
            Navigator.of(ctx).pop(false);
          }
        },
        onOpenSettings: () async {
          Navigator.of(ctx).pop(false);
          await openSettings(type);
        },
      ),
    );

    if (result == true) {
      final newStatus = await requestPermission(type, force: true);
      return newStatus.isGranted;
    }

    return false;
  }
}

class _PermissionRationaleBottomSheet extends StatelessWidget {
  final AppPermissionType type;
  final AppPermissionStatus status;
  final VoidCallback onGrant;
  final VoidCallback onLater;
  final VoidCallback onOpenSettings;

  const _PermissionRationaleBottomSheet({
    required this.type,
    required this.status,
    required this.onGrant,
    required this.onLater,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPermanent = status.isPermanentlyDenied;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type.icon,
                    size: 28,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPermanent
                            ? 'الإذن معطّل من إعدادات النظام'
                            : 'يلزم تفعيل هذا الإذن للاستفادة الكاملة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isPermanent
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              type.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (isPermanent) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'لقد تم رفض الإذن سابقاً، يرجى الضغط على زر "فتح الإعدادات" لتفعيله يدوياً.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (isPermanent)
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('فتح الإعدادات'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: onGrant,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تفعيل الصلاحية'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onLater,
              child: const Text('لاحقاً'),
            ),
          ],
        ),
      ),
    );
  }
}
