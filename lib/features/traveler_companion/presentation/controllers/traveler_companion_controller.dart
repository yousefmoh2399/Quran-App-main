import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/travel_dua_model.dart';
import '../../data/models/travel_rule_model.dart';
import '../../data/models/wiping_timer_model.dart';
import '../../data/repositories/traveler_repository.dart';

class TravelerCompanionController extends GetxController {
  final TravelerRepository _repository = TravelerRepository.instance;

  final RxInt selectedTabIndex = 0.obs;

  // 1. Wiping Timer State
  final Rx<WipingTimerState?> timerState = Rx<WipingTimerState?>(null);
  final Rx<DateTime> currentTime = DateTime.now().obs;
  Timer? _ticker;

  // 2. Fiqh Guide State
  final Rx<TravelRuleCategory?> selectedRuleCategory = Rx<TravelRuleCategory?>(null);

  // 3. Travel Duas State
  final Rx<TravelDuaCategory?> selectedDuaCategory = Rx<TravelDuaCategory?>(null);
  final RxMap<String, int> duaCounters = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadTimer();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Wiping Timer Actions
  // ---------------------------------------------------------------------------

  Future<void> loadTimer() async {
    final state = await _repository.getTimerState();
    timerState.value = state;
    if (state != null && state.isActive) {
      _startTicker();
    }
  }

  Future<void> startTimer({required bool isTraveler}) async {
    AppHaptics.itemCompleted();
    final newState = WipingTimerState.start(isTraveler: isTraveler);
    timerState.value = newState;
    await _repository.saveTimerState(newState);
    _startTicker();
  }

  Future<void> stopTimer() async {
    AppHaptics.selection();
    _ticker?.cancel();
    _ticker = null;
    timerState.value = null;
    await _repository.clearTimerState();
  }

  Future<void> resetTimer() async {
    final current = timerState.value;
    if (current == null) return;
    AppHaptics.cycleCompleted();
    final newState = WipingTimerState.start(
      isTraveler: current.isTraveler,
      startTime: DateTime.now(),
    );
    timerState.value = newState;
    await _repository.saveTimerState(newState);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    currentTime.value = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      currentTime.value = DateTime.now();
    });
  }

  // ---------------------------------------------------------------------------
  // Fiqh Rules Filtering
  // ---------------------------------------------------------------------------

  void setRuleCategory(TravelRuleCategory? category) {
    AppHaptics.selection();
    selectedRuleCategory.value = category;
  }

  List<TravelRuleModel> get filteredRules {
    return _repository.getRulesByCategory(selectedRuleCategory.value);
  }

  // ---------------------------------------------------------------------------
  // Travel Duas Filtering & Counter
  // ---------------------------------------------------------------------------

  void setDuaCategory(TravelDuaCategory? category) {
    AppHaptics.selection();
    selectedDuaCategory.value = category;
  }

  List<TravelDuaModel> get filteredDuas {
    return _repository.getDuasByCategory(selectedDuaCategory.value);
  }

  int getDuaCount(String duaId) {
    return duaCounters[duaId] ?? 0;
  }

  void incrementDua(String duaId, int target) {
    final current = getDuaCount(duaId);
    if (current >= target) {
      // Completed, loop or vibrate
      AppHaptics.cycleCompleted();
      duaCounters[duaId] = 1;
    } else {
      final next = current + 1;
      duaCounters[duaId] = next;
      if (next >= target) {
        AppHaptics.itemCompleted();
      } else {
        AppHaptics.selection();
      }
    }
  }

  void resetDua(String duaId) {
    HapticFeedback.lightImpact();
    duaCounters[duaId] = 0;
  }
}
