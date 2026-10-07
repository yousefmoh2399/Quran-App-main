import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/data/services/guide_engine.dart';

class SaiController extends GetxController {
  final GuideEngine _guideEngine;

  SaiController({GuideEngine? guideEngine})
      : _guideEngine = guideEngine ?? GuideEngine();

  final RxInt currentLap = 0.obs;
  final RxBool isFinished = false.obs;
  final RxList<DuaModel> lapsDuas = <DuaModel>[].obs;
  final RxBool isGreenZoneAlertActive = false.obs;
  final RxString saiType = 'سعي العمرة'.obs;

  static const List<String> availableSaiTypes = [
    'سعي العمرة',
    'سعي الحج',
  ];

  void setSaiType(String type) {
    if (availableSaiTypes.contains(type)) {
      saiType.value = type;
      AppHaptics.selection();
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadSavedState();
  }

  Future<void> loadSavedState() async {
    try {
      final guide = await _guideEngine.loadGuide();
      final saiStep = guide.steps.firstWhereOrNull((s) => s.id == 'sai');
      if (saiStep != null) {
        lapsDuas.assignAll(saiStep.lapsDuas);
        currentLap.value = saiStep.currentLap.clamp(0, 7);
        isFinished.value = saiStep.isCompleted || currentLap.value >= 7;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('SaiController.loadSavedState error: $e\n$st');
      }
    }
  }

  /// Determines the starting point of the given lap (1-indexed)
  String getStartPoint(int lapNumber) {
    if (lapNumber <= 0) return 'الصفا';
    return (lapNumber % 2 != 0) ? 'الصفا' : 'المروة';
  }

  /// Determines the destination point of the given lap (1-indexed)
  String getDestinationPoint(int lapNumber) {
    if (lapNumber <= 0) return 'المروة';
    return (lapNumber % 2 != 0) ? 'المروة' : 'الصفا';
  }

  /// Current active lap number (1 to 7)
  int get activeLapNumber => (currentLap.value + 1).clamp(1, 7);

  String get currentFrom => getStartPoint(activeLapNumber);
  String get currentTo => getDestinationPoint(activeLapNumber);

  DuaModel? get currentLapDua {
    if (lapsDuas.isEmpty) return null;
    final index = (activeLapNumber - 1).clamp(0, lapsDuas.length - 1);
    return lapsDuas[index];
  }

  Future<void> completeLap() async {
    if (currentLap.value >= 7) return;

    currentLap.value++;
    isGreenZoneAlertActive.value = false;

    if (currentLap.value >= 7) {
      isFinished.value = true;
      AppHaptics.cycleCompleted();
    } else {
      AppHaptics.itemCompleted();
    }

    await _guideEngine.saveStepProgress(
      guideId: 'umrah',
      stepId: 'sai',
      isCompleted: isFinished.value,
      currentLap: currentLap.value,
    );
  }

  Future<void> undoLap() async {
    if (currentLap.value <= 0) return;

    currentLap.value--;
    isFinished.value = false;
    isGreenZoneAlertActive.value = false;
    AppHaptics.selection();

    await _guideEngine.saveStepProgress(
      guideId: 'umrah',
      stepId: 'sai',
      isCompleted: false,
      currentLap: currentLap.value,
    );
  }

  Future<void> resetSai() async {
    currentLap.value = 0;
    isFinished.value = false;
    isGreenZoneAlertActive.value = false;
    AppHaptics.cycleCompleted();

    await _guideEngine.saveStepProgress(
      guideId: 'umrah',
      stepId: 'sai',
      isCompleted: false,
      currentLap: 0,
    );
  }

  void toggleGreenZone() {
    isGreenZoneAlertActive.value = !isGreenZoneAlertActive.value;
    if (isGreenZoneAlertActive.value) {
      AppHaptics.itemCompleted();
    } else {
      AppHaptics.tap();
    }
  }
}
