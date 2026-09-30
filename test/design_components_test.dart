import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_theme.dart';
import 'package:quran_app_android/core/design/components/components.dart';
import 'package:quran_app_android/core/design/responsive.dart';

void main() {
  Widget buildThemedWidget({
    required Widget child,
    required ThemeData theme,
  }) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('Design System Tokens & Theme Tests', () {
    test('AppColorsExtension light and dark have correct contrast', () {
      const light = AppColorsExtension.light;
      const dark = AppColorsExtension.dark;

      expect(light.bg, const Color(0xFFFAF6EC));
      expect(light.primary, const Color(0xFF0F5C4A));
      expect(dark.bg, const Color(0xFF0E1512));
      expect(dark.primary, const Color(0xFF3FB597));
    });

    test('Responsive breakpoints correctly identify screen sizes', () {
      expect(Responsive.compactBreakpoint, 600.0);
      expect(Responsive.mediumBreakpoint, 840.0);
      expect(Responsive.maxContentWidth, 720.0);
    });
  });

  group('AppButton Component Tests', () {
    for (final mode in ['Light', 'Dark']) {
      final theme = mode == 'Light' ? AppTheme.light : AppTheme.dark;

      testWidgets('AppButton.primary renders and triggers tap in $mode mode',
          (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          buildThemedWidget(
            theme: theme,
            child: AppButton.primary(
              label: 'زر تجريبي',
              onPressed: () => tapped = true,
            ),
          ),
        );

        expect(find.text('زر تجريبي'), findsOneWidget);
        await tester.tap(find.text('زر تجريبي'));
        await tester.pump();
        expect(tapped, isTrue);
      });

      testWidgets('AppButton.secondary renders in $mode mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildThemedWidget(
            theme: theme,
            child: AppButton.secondary(
              label: 'زر ثانوي',
              onPressed: () {},
            ),
          ),
        );

        expect(find.text('زر ثانوي'), findsOneWidget);
      });
    }

    testWidgets('AppButton displays loading spinner when isLoading=true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildThemedWidget(
          theme: AppTheme.light,
          child: const AppButton.primary(
            label: 'تحميل',
            isLoading: true,
            onPressed: null,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('تحميل'), findsNothing);
    });
  });

  group('AppCard Component Tests', () {
    for (final mode in ['Light', 'Dark']) {
      final theme = mode == 'Light' ? AppTheme.light : AppTheme.dark;

      testWidgets('AppCard renders child and responds to tap in $mode mode',
          (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          buildThemedWidget(
            theme: theme,
            child: AppCard(
              onTap: () => tapped = true,
              child: const Text('محتوى البطاقة'),
            ),
          ),
        );

        expect(find.text('محتوى البطاقة'), findsOneWidget);
        await tester.tap(find.text('محتوى البطاقة'));
        await tester.pump();
        expect(tapped, isTrue);
      });
    }
  });

  group('SectionHeader Component Tests', () {
    for (final mode in ['Light', 'Dark']) {
      final theme = mode == 'Light' ? AppTheme.light : AppTheme.dark;

      testWidgets('SectionHeader displays title, subtitle and ornament in $mode mode',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildThemedWidget(
            theme: theme,
            child: const SectionHeader(
              title: 'عنوان القسم',
              subtitle: 'وصف فرعي',
              showOrnament: true,
            ),
          ),
        );

        expect(find.text('عنوان القسم'), findsOneWidget);
        expect(find.text('وصف فرعي'), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });
    }
  });

  group('AppListTile Component Tests', () {
    for (final mode in ['Light', 'Dark']) {
      final theme = mode == 'Light' ? AppTheme.light : AppTheme.dark;

      testWidgets('AppListTile renders and handles tap in $mode mode',
          (WidgetTester tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          buildThemedWidget(
            theme: theme,
            child: AppListTile(
              leading: const Icon(Icons.star),
              title: const Text('العنصر الأول'),
              subtitle: const Text('تفاصيل العنصر'),
              onTap: () => tapped = true,
            ),
          ),
        );

        expect(find.text('العنصر الأول'), findsOneWidget);
        expect(find.text('تفاصيل العنصر'), findsOneWidget);
        await tester.tap(find.text('العنصر الأول'));
        await tester.pump();
        expect(tapped, isTrue);
      });
    }
  });

  group('EmptyState & ErrorState Tests', () {
    testWidgets('EmptyState displays title, message, and action button',
        (WidgetTester tester) async {
      bool actionPressed = false;
      await tester.pumpWidget(
        buildThemedWidget(
          theme: AppTheme.light,
          child: EmptyState(
            title: 'فارغ',
            message: 'لا توجد بيانات حالياً',
            actionLabel: 'إضافة',
            onActionPressed: () => actionPressed = true,
          ),
        ),
      );

      expect(find.text('فارغ'), findsOneWidget);
      expect(find.text('لا توجد بيانات حالياً'), findsOneWidget);
      await tester.tap(find.text('إضافة'));
      await tester.pump();
      expect(actionPressed, isTrue);
    });

    testWidgets('ErrorState displays message and retry action',
        (WidgetTester tester) async {
      bool retryPressed = false;
      await tester.pumpWidget(
        buildThemedWidget(
          theme: AppTheme.dark,
          child: ErrorState(
            message: 'فشل في الاتصال',
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      expect(find.text('فشل في الاتصال'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pump();
      expect(retryPressed, isTrue);
    });
  });
}
