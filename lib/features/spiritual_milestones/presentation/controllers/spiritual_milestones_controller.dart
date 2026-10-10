import 'package:get/get.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/spiritual_milestone_model.dart';
import '../../data/services/spiritual_milestones_service.dart';

class SpiritualMilestonesController extends GetxController {
  final SpiritualMilestonesService _service = SpiritualMilestonesService.instance;

  final RxBool isLoading = true.obs;
  final RxInt selectedTab = 0.obs; // 0: Garden & Live Counter, 1: Lifetime Stats, 2: Badges

  final RxInt totalLifetimeCount = 0.obs;
  final RxInt treesCount = 0.obs;
  final RxInt nextTreeProgress = 0.obs;
  final RxMap<ZikrType, int> counts = <ZikrType, int>{}.obs;

  final RxBool justPlantedTree = false.obs;
  final Rx<ZikrType> activeZikr = ZikrType.tasbeeh.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    await _service.init();
    _refreshState();
    isLoading.value = false;
  }

  void _refreshState() {
    totalLifetimeCount.value = _service.getTotalCount();
    treesCount.value = _service.getTreesPlanted();
    nextTreeProgress.value = _service.getNextTreeProgress();

    final Map<ZikrType, int> updated = {};
    for (final type in ZikrType.values) {
      updated[type] = _service.getCount(type);
    }
    counts.assignAll(updated);
  }

  void setTab(int index) {
    if (selectedTab.value != index) {
      AppHaptics.selection();
      selectedTab.value = index;
    }
  }

  void setActiveZikr(ZikrType type) {
    AppHaptics.selection();
    activeZikr.value = type;
  }

  Future<void> incrementZikr(ZikrType type, {int amount = 1}) async {
    final prevTrees = treesCount.value;
    await _service.addCount(type, amount);
    _refreshState();

    if (treesCount.value > prevTrees) {
      // A new tree planted in Jannah!
      AppHaptics.cycleCompleted();
      justPlantedTree.value = true;
      Future.delayed(const Duration(seconds: 4), () {
        justPlantedTree.value = false;
      });
    } else {
      AppHaptics.tap();
    }
  }

  List<SpiritualBadge> get badges => _service.getAllBadges();

  int getBadgeProgress(SpiritualBadge badge) {
    if (badge.specificType != null) {
      return counts[badge.specificType!] ?? 0;
    }
    return totalLifetimeCount.value;
  }

  bool isBadgeUnlocked(SpiritualBadge badge) {
    return badge.isUnlocked(getBadgeProgress(badge));
  }

  int get unlockedBadgesCount {
    return badges.where(isBadgeUnlocked).length;
  }
}
