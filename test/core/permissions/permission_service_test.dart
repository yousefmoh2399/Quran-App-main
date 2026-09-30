import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/permissions/app_permission_status.dart';
import 'package:quran_app_android/core/permissions/app_permission_type.dart';
import 'package:quran_app_android/core/permissions/permission_platform_adapter.dart';
import 'package:quran_app_android/core/permissions/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPermissionPlatformAdapter implements PermissionPlatformAdapter {
  final Map<AppPermissionType, AppPermissionStatus> mockStatuses = {
    for (final t in AppPermissionType.values) t: AppPermissionStatus.denied,
  };

  final List<AppPermissionType> requestedTypes = [];
  final List<AppPermissionType> openedSettings = [];
  int checkStatusCallCount = 0;

  @override
  bool isApplicable(AppPermissionType type) => true;

  @override
  Future<AppPermissionStatus> checkStatus(AppPermissionType type) async {
    checkStatusCallCount++;
    return mockStatuses[type] ?? AppPermissionStatus.denied;
  }

  @override
  Future<AppPermissionStatus> request(AppPermissionType type) async {
    requestedTypes.add(type);
    return mockStatuses[type] ?? AppPermissionStatus.denied;
  }

  @override
  Future<bool> openSettings(AppPermissionType type) async {
    openedSettings.add(type);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPermissionPlatformAdapter mockAdapter;
  late SharedPreferences prefs;
  late PermissionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockAdapter = MockPermissionPlatformAdapter();
    service = PermissionService(
      adapter: mockAdapter,
      prefs: prefs,
      registerObserver: false,
    );
  });

  group('PermissionService Unit Tests', () {
    test('Initial statuses default to denied and refreshAll updates them', () async {
      expect(service.getStatus(AppPermissionType.location), AppPermissionStatus.denied);
      expect(service.isGranted(AppPermissionType.location), isFalse);

      mockAdapter.mockStatuses[AppPermissionType.location] = AppPermissionStatus.granted;
      mockAdapter.mockStatuses[AppPermissionType.notification] = AppPermissionStatus.granted;

      final updated = await service.refreshAll();
      expect(updated[AppPermissionType.location], AppPermissionStatus.granted);
      expect(updated[AppPermissionType.notification], AppPermissionStatus.granted);
      expect(service.isGranted(AppPermissionType.location), isTrue);
      expect(service.isGranted(AppPermissionType.notification), isTrue);
    });

    test('7-Day Cooldown works correctly', () async {
      const type = AppPermissionType.location;
      expect(service.isInCooldown(type), isFalse);

      await service.recordLater(type);
      expect(service.isInCooldown(type), isTrue);

      // Simulate 8 days later
      final eightDaysAgo = DateTime.now().subtract(const Duration(days: 8));
      await prefs.setInt(
        'permission_later_timestamp_${type.name}',
        eightDaysAgo.millisecondsSinceEpoch,
      );
      expect(service.isInCooldown(type), isFalse);

      // Simulate 6 days later
      final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));
      await prefs.setInt(
        'permission_later_timestamp_${type.name}',
        sixDaysAgo.millisecondsSinceEpoch,
      );
      expect(service.isInCooldown(type), isTrue);

      await service.clearCooldown(type);
      expect(service.isInCooldown(type), isFalse);
    });

    test('Per-session prompt limits avoid repeated dialogs in same session', () {
      const type = AppPermissionType.exactAlarm;
      expect(service.wasPromptedThisSession(type), isFalse);

      service.markPromptedThisSession(type);
      expect(service.wasPromptedThisSession(type), isTrue);

      service.resetSession();
      expect(service.wasPromptedThisSession(type), isFalse);
    });

    test('Lifecycle resumed triggers refreshAll', () async {
      final initialCount = mockAdapter.checkStatusCallCount;
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockAdapter.checkStatusCallCount, greaterThan(initialCount));
    });

    test('Granting permission automatically clears cooldown', () async {
      const type = AppPermissionType.notification;
      await service.recordLater(type);
      expect(service.isInCooldown(type), isTrue);

      mockAdapter.mockStatuses[type] = AppPermissionStatus.granted;
      final result = await service.requestPermission(type);

      expect(result, AppPermissionStatus.granted);
      expect(service.isGranted(type), isTrue);
      expect(service.isInCooldown(type), isFalse);
    });

    test('OpenSettings forwards call to adapter', () async {
      const type = AppPermissionType.batteryOptimization;
      final result = await service.openSettings(type);
      expect(result, isTrue);
      expect(mockAdapter.openedSettings.contains(type), isTrue);
    });
  });

  group('PermissionService Contextual UI & Rationale Widget Tests', () {
    testWidgets('requestWithRationale returns true immediately if already granted', (tester) async {
      mockAdapter.mockStatuses[AppPermissionType.location] = AppPermissionStatus.granted;
      await service.refreshAll();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final granted = await service.requestWithRationale(
                  context,
                  AppPermissionType.location,
                );
                expect(granted, isTrue);
              },
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('الموقع الجغرافي'), findsNothing);
    });

    testWidgets('requestWithRationale returns false if in 7-day cooldown', (tester) async {
      const type = AppPermissionType.notification;
      mockAdapter.mockStatuses[type] = AppPermissionStatus.denied;
      await service.recordLater(type);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await service.requestWithRationale(context, type);
                expect(result, isFalse);
              },
              child: const Text('Test'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('الإشعارات والتنبيهات'), findsNothing);
    });

    testWidgets('requestWithRationale shows bottom sheet and handles "لاحقاً" (later)', (tester) async {
      const type = AppPermissionType.exactAlarm;
      mockAdapter.mockStatuses[type] = AppPermissionStatus.denied;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await service.requestWithRationale(context, type);
                },
                child: const Text('Prompt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Prompt'));
      await tester.pumpAndSettle();

      expect(find.text('المنبهات الدقيقة (Exact Alarms)'), findsOneWidget);
      expect(find.text('لاحقاً'), findsOneWidget);

      await tester.tap(find.text('لاحقاً'));
      await tester.pumpAndSettle();

      // Verify bottom sheet closed and 7-day cooldown recorded
      expect(find.text('المنبهات الدقيقة (Exact Alarms)'), findsNothing);
      expect(service.isInCooldown(type), isTrue);
    });
  });
}
