import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/data/services/guide_engine.dart';

class UmrahGuideController extends GetxController {
  final GuideEngine _guideEngine;

  UmrahGuideController({GuideEngine? guideEngine})
      : _guideEngine = guideEngine ?? GuideEngine();

  final RxBool isLoading = true.obs;
  final Rxn<GuideModel> guide = Rxn<GuideModel>();
  final RxInt currentStepIndex = 0.obs;
  final RxSet<String> completedStepIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadGuide();
  }

  Future<void> loadGuide() async {
    isLoading.value = true;
    try {
      final loadedGuide = await _guideEngine.loadGuide();
      guide.value = loadedGuide;

      final completed = <String>{};
      for (final step in loadedGuide.steps) {
        if (step.isCompleted) {
          completed.add(step.id);
        }
      }
      completedStepIds.assignAll(completed);

      // Restore first non-completed step if available
      final firstIncompleteIndex = loadedGuide.steps.indexWhere((s) => !s.isCompleted);
      if (firstIncompleteIndex != -1) {
        currentStepIndex.value = firstIncompleteIndex;
      } else {
        currentStepIndex.value = 0;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('UmrahGuideController.loadGuide error: $e\n$st');
      }
    } finally {
      isLoading.value = false;
    }
  }

  GuideStepModel? get currentStep {
    final g = guide.value;
    if (g == null || g.steps.isEmpty) return null;
    final idx = currentStepIndex.value.clamp(0, g.steps.length - 1);
    return g.steps[idx];
  }

  double get overallProgress {
    final g = guide.value;
    if (g == null || g.steps.isEmpty) return 0.0;
    return completedStepIds.length / g.steps.length;
  }

  bool isStepCompleted(String stepId) => completedStepIds.contains(stepId);

  Future<void> toggleStepCompletion(String stepId) async {
    final g = guide.value;
    if (g == null) return;

    final isCurrentlyDone = completedStepIds.contains(stepId);
    final newStatus = !isCurrentlyDone;

    if (newStatus) {
      completedStepIds.add(stepId);
      AppHaptics.itemCompleted();
    } else {
      completedStepIds.remove(stepId);
      AppHaptics.tap();
    }

    // Persist to SQLite
    await _guideEngine.saveStepProgress(
      guideId: g.id,
      stepId: stepId,
      isCompleted: newStatus,
    );

    // If all completed, celebratory haptics
    if (completedStepIds.length == g.steps.length) {
      AppHaptics.cycleCompleted();
    }
  }

  void nextStep() {
    final g = guide.value;
    if (g == null) return;
    if (currentStepIndex.value < g.steps.length - 1) {
      currentStepIndex.value++;
      AppHaptics.selection();
    }
  }

  void previousStep() {
    if (currentStepIndex.value > 0) {
      currentStepIndex.value--;
      AppHaptics.selection();
    }
  }

  void goToStep(int index) {
    final g = guide.value;
    if (g == null) return;
    if (index >= 0 && index < g.steps.length) {
      currentStepIndex.value = index;
      AppHaptics.selection();
    }
  }

  Future<void> resetProgress() async {
    final g = guide.value;
    if (g == null) return;

    await _guideEngine.resetGuideProgress(g.id);
    completedStepIds.clear();
    currentStepIndex.value = 0;
    AppHaptics.cycleCompleted();
  }
}
