import 'package:get/get.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/ruqyah_item_model.dart';
import '../../data/repositories/ruqyah_repository.dart';

class RuqyahController extends GetxController {
  final RuqyahRepository _repository = RuqyahRepository.instance;

  final RxList<RuqyahItem> items = <RuqyahItem>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxInt currentCount = 0.obs;
  final RxSet<int> completedItemIds = <int>{}.obs;
  final Rx<RuqyahCategory?> selectedCategory = Rx<RuqyahCategory?>(null);
  final RxDouble textScale = 1.0.obs;
  final RxBool isCompletedSession = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  void loadItems() {
    if (selectedCategory.value == null) {
      items.assignAll(_repository.getAllItems());
    } else {
      items.assignAll(_repository.getItemsByCategory(selectedCategory.value!));
    }
    currentIndex.value = 0;
    currentCount.value = 0;
    completedItemIds.clear();
    isCompletedSession.value = false;
  }

  void filterByCategory(RuqyahCategory? category) {
    AppHaptics.selection();
    selectedCategory.value = category;
    loadItems();
  }

  RuqyahItem? get currentItem {
    if (items.isEmpty || currentIndex.value >= items.length) return null;
    return items[currentIndex.value];
  }

  double get overallProgress {
    if (items.isEmpty) return 0.0;
    return (completedItemIds.length / items.length).clamp(0.0, 1.0);
  }

  void tapCurrent() {
    final item = currentItem;
    if (item == null) return;

    if (currentCount.value < item.targetCount) {
      currentCount.value++;
      AppHaptics.tap();

      if (currentCount.value >= item.targetCount) {
        // Item fully completed!
        completedItemIds.add(item.id);
        AppHaptics.itemCompleted();

        // Check if entire session is finished
        if (completedItemIds.length >= items.length) {
          isCompletedSession.value = true;
          AppHaptics.cycleCompleted();
        } else {
          // Auto advance to next after brief pause
          Future.delayed(const Duration(milliseconds: 320), () {
            if (currentIndex.value < items.length - 1) {
              nextItem();
            }
          });
        }
      }
    }
  }

  void nextItem() {
    if (currentIndex.value < items.length - 1) {
      AppHaptics.selection();
      currentIndex.value++;
      final next = items[currentIndex.value];
      currentCount.value = completedItemIds.contains(next.id) ? next.targetCount : 0;
    }
  }

  void previousItem() {
    if (currentIndex.value > 0) {
      AppHaptics.selection();
      currentIndex.value--;
      final prev = items[currentIndex.value];
      currentCount.value = completedItemIds.contains(prev.id) ? prev.targetCount : 0;
    }
  }

  void jumpToIndex(int index) {
    if (index >= 0 && index < items.length) {
      AppHaptics.selection();
      currentIndex.value = index;
      final target = items[index];
      currentCount.value = completedItemIds.contains(target.id) ? target.targetCount : 0;
    }
  }

  void resetCurrentItem() {
    AppHaptics.selection();
    final item = currentItem;
    if (item != null) {
      completedItemIds.remove(item.id);
      currentCount.value = 0;
      isCompletedSession.value = false;
    }
  }

  void resetSession() {
    AppHaptics.selection();
    currentIndex.value = 0;
    currentCount.value = 0;
    completedItemIds.clear();
    isCompletedSession.value = false;
  }

  void toggleTextScale() {
    AppHaptics.selection();
    if (textScale.value >= 1.4) {
      textScale.value = 1.0;
    } else if (textScale.value >= 1.2) {
      textScale.value = 1.4;
    } else {
      textScale.value = 1.2;
    }
  }
}
