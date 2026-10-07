import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/data/services/guide_engine.dart';
import 'package:quran_app_android/features/umrah/data/services/tawaf_heading_accumulator.dart';

class TawafController extends GetxController {
  final GuideEngine _guideEngine;

  final RxInt currentLap = 0.obs;
  final RxBool isFinished = false.obs;
  final RxList<DuaModel> lapsDuas = <DuaModel>[].obs;
  final RxBool isSensorTrackingEnabled = false.obs;
  final RxBool showSensorPrompt = false.obs;
  final RxDouble compassHeading = 0.0.obs;

  late final TawafHeadingAccumulator accumulator;
  StreamSubscription<CompassEvent>? _compassSubscription;

  TawafController({GuideEngine? guideEngine})
      : _guideEngine = guideEngine ?? GuideEngine() {
    accumulator = TawafHeadingAccumulator(
      onRotationCandidate: () {
        if (currentLap.value < 7) {
          showSensorPrompt.value = true;
          AppHaptics.itemCompleted();
        }
      },
    );
  }

  @override
  void onInit() {
    super.onInit();
    loadSavedState();
  }

  @override
  void onClose() {
    _stopSensor();
    super.onClose();
  }

  Future<void> loadSavedState() async {
    try {
      final guide = await _guideEngine.loadGuide();
      final tawafStep = guide.steps.firstWhereOrNull((s) => s.id == 'tawaf');
      if (tawafStep != null) {
        lapsDuas.assignAll(tawafStep.lapsDuas);
        currentLap.value = tawafStep.currentLap.clamp(0, 7);
        isFinished.value = tawafStep.isCompleted || currentLap.value >= 7;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('TawafController.loadSavedState error: $e\n$st');
      }
    }
  }

  final RxString tawafType = 'طواف العمرة'.obs;

  static const List<String> availableTawafTypes = [
    'طواف العمرة',
    'طواف القدوم',
    'طواف الإفاضة',
    'طواف الوداع',
    'طواف التطوع',
  ];

  void setTawafType(String type) {
    if (availableTawafTypes.contains(type)) {
      tawafType.value = type;
      AppHaptics.selection();
    }
  }

  /// Current active lap number being performed (1 to 7)
  int get activeLapNumber => (currentLap.value + 1).clamp(1, 7);

  DuaModel? get currentLapDua {
    if (lapsDuas.isEmpty) return null;
    final activeIndex = isFinished.value
        ? (lapsDuas.length - 1)
        : (activeLapNumber - 1).clamp(0, lapsDuas.length - 1);
    return lapsDuas[activeIndex];
  }

  void stopSensor() => _stopSensor();

  Future<void> completeLap() async {
    if (currentLap.value >= 7) return;

    currentLap.value++;
    accumulator.reset();
    showSensorPrompt.value = false;

    if (currentLap.value >= 7) {
      isFinished.value = true;
      AppHaptics.cycleCompleted();
    } else {
      AppHaptics.itemCompleted();
    }

    // Persist
    await _guideEngine.saveStepProgress(
      guideId: 'umrah',
      stepId: 'tawaf',
      isCompleted: isFinished.value,
      currentLap: currentLap.value,
    );
  }

  Future<void> undoLap() async {
    if (currentLap.value <= 0) return;

    currentLap.value--;
    isFinished.value = false;
    accumulator.reset();
    showSensorPrompt.value = false;
    AppHaptics.selection();

    await _guideEngine.saveStepProgress(
      guideId: 'umrah',
      stepId: 'tawaf',
      isCompleted: false,
      currentLap: currentLap.value,
    );
  }

  Future<void> resetTawaf() async {
    currentLap.value = 0;
    isFinished.value = false;
    accumulator.reset();
    showSensorPrompt.value = false;
    AppHaptics.cycleCompleted();

    await _guideEngine.saveStepProgress(
      guideId: 'umrah',
      stepId: 'tawaf',
      isCompleted: false,
      currentLap: 0,
    );
  }

  void toggleSensorTracking() {
    isSensorTrackingEnabled.value = !isSensorTrackingEnabled.value;
    if (isSensorTrackingEnabled.value) {
      _startSensor();
      AppHaptics.selection();
    } else {
      _stopSensor();
      AppHaptics.tap();
    }
  }

  void _startSensor() {
    try {
      accumulator.reset();
      _compassSubscription?.cancel();
      _compassSubscription = FlutterCompass.events?.listen(
        (event) {
          final heading = event.heading;
          if (heading != null) {
            compassHeading.value = heading;
            accumulator.addHeading(heading);
          }
        },
        onError: (err) {
          if (kDebugMode) debugPrint('FlutterCompass error: $err');
          isSensorTrackingEnabled.value = false;
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Cannot start compass: $e');
      isSensorTrackingEnabled.value = false;
    }
  }

  void _stopSensor() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    showSensorPrompt.value = false;
    accumulator.reset();
  }

  void dismissSensorPrompt() {
    showSensorPrompt.value = false;
    accumulator.acknowledgeCandidate();
  }

  void confirmSensorLap() {
    completeLap();
    accumulator.acknowledgeCandidate();
  }
}
