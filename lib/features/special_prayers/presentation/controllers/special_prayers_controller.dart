import 'package:get/get.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/special_prayer_model.dart';
import '../../data/repositories/special_prayers_repository.dart';

class SpecialPrayersController extends GetxController {
  final SpecialPrayersRepository _repository = SpecialPrayersRepository.instance;

  final Rx<SpecialPrayerCategory?> selectedCategory = Rx<SpecialPrayerCategory?>(null);
  final RxString searchQuery = ''.obs;
  final RxList<SpecialPrayer> allPrayers = <SpecialPrayer>[].obs;
  final RxSet<int> expandedPrayerIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    allPrayers.assignAll(_repository.getAllPrayers());
    if (allPrayers.isNotEmpty) {
      // Auto expand first prayer by default
      expandedPrayerIds.add(allPrayers.first.id);
    }
  }

  void setCategory(SpecialPrayerCategory? category) {
    AppHaptics.selection();
    selectedCategory.value = category;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void toggleExpanded(int id) {
    AppHaptics.selection();
    if (expandedPrayerIds.contains(id)) {
      expandedPrayerIds.remove(id);
    } else {
      expandedPrayerIds.add(id);
    }
  }

  List<SpecialPrayer> get filteredPrayers {
    var list = allPrayers.toList();
    if (selectedCategory.value != null) {
      list = list.where((p) => p.category == selectedCategory.value).toList();
    }
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.subtitle.toLowerCase().contains(q) ||
            p.definitionAndVirtue.toLowerCase().contains(q) ||
            p.steps.any((s) =>
                s.title.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q) ||
                (s.detailedDua != null && s.detailedDua!.toLowerCase().contains(q)));
      }).toList();
    }
    return list;
  }
}
