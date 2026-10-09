import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/components/app_scaffold.dart';
import '../controllers/hifz_tester_controller.dart';
import '../widgets/hifz_setup_view.dart';
import '../widgets/hifz_testing_view.dart';
import '../widgets/hifz_result_view.dart';
import '../widgets/mutashabihat_browser_view.dart';
import '../../data/models/hifz_test_models.dart';

class HifzTesterView extends StatefulWidget {
  final int? initialSurahId;
  final HifzTestMode? initialMode;
  final HifzScopeType? initialScope;

  const HifzTesterView({
    super.key,
    this.initialSurahId,
    this.initialMode,
    this.initialScope,
  });

  @override
  State<HifzTesterView> createState() => _HifzTesterViewState();
}

class _HifzTesterViewState extends State<HifzTesterView> {
  late final HifzTesterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HifzTesterController());

    // Process route arguments or widget arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final sId = widget.initialSurahId ?? (args?['surahId'] as int?);
    final mode = widget.initialMode ?? (args?['mode'] as HifzTestMode?);
    final scope = widget.initialScope ?? (args?['scope'] as HifzScopeType?);

    _controller.initWithArguments(
      surahId: sId,
      mode: mode,
      scope: scope,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Obx(() {
      final state = _controller.viewState.value;

      String title;
      switch (state) {
        case HifzViewState.setup:
          title = 'اختبار وتثبيت الحفظ';
          break;
        case HifzViewState.testing:
          title = 'جلسة الاختبار القرآني';
          break;
        case HifzViewState.results:
          title = 'نتيجة الاختبار والإتقان';
          break;
        case HifzViewState.mutashabihatGuide:
          title = 'دليل المتشابهات وضوابطها';
          break;
      }

      return PopScope(
        canPop: state == HifzViewState.setup,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (state == HifzViewState.testing) {
            _showExitDialog(context);
          } else {
            _controller.returnToSetup();
          }
        },
        child: AppScaffold(
          title: title,
          actions: [
            if (state == HifzViewState.setup)
              IconButton(
                icon: Icon(Icons.auto_stories_rounded, color: colors.accent),
                tooltip: 'دليل المتشابهات',
                onPressed: _controller.openMutashabihatGuide,
              ),
            if (state == HifzViewState.mutashabihatGuide || state == HifzViewState.results)
              IconButton(
                icon: Icon(Icons.home_rounded, color: colors.primary),
                tooltip: 'الرئيسية',
                onPressed: _controller.returnToSetup,
              ),
          ],
          body: _buildBody(state),
        ),
      );
    });
  }

  Widget _buildBody(HifzViewState state) {
    switch (state) {
      case HifzViewState.setup:
        return HifzSetupView(controller: _controller);
      case HifzViewState.testing:
        return HifzTestingView(controller: _controller);
      case HifzViewState.results:
        return HifzResultView(controller: _controller);
      case HifzViewState.mutashabihatGuide:
        return MutashabihatBrowserView(controller: _controller);
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الاختبار؟'),
        content: const Text('هل تريد الخروج من جلسة الاختبار والعودة للإعدادات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('استمرار'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.returnToSetup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
