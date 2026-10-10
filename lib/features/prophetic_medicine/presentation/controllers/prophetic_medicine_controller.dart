import 'package:get/get.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/prophetic_food_model.dart';
import '../../data/repositories/prophetic_medicine_repository.dart';

class PropheticMedicineController extends GetxController {
  final PropheticMedicineRepository _repository = PropheticMedicineRepository.instance;

  final RxInt selectedTab = 0.obs; // 0: Encyclopedia, 1: Practical Recipes
  final Rx<PropheticFoodCategory?> selectedCategory = Rx<PropheticFoodCategory?>(null);
  final RxString searchQuery = ''.obs;

  final RxList<PropheticFood> allFoods = <PropheticFood>[].obs;
  final RxList<PropheticRecipe> allRecipes = <PropheticRecipe>[].obs;
  final RxSet<int> expandedFoodIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    allFoods.assignAll(_repository.getAllFoods());
    allRecipes.assignAll(_repository.getAllRecipes());
  }

  void setTab(int index) {
    if (selectedTab.value != index) {
      AppHaptics.selection();
      selectedTab.value = index;
    }
  }

  void setCategory(PropheticFoodCategory? category) {
    AppHaptics.selection();
    selectedCategory.value = category;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void toggleExpanded(int id) {
    AppHaptics.selection();
    if (expandedFoodIds.contains(id)) {
      expandedFoodIds.remove(id);
    } else {
      expandedFoodIds.add(id);
    }
  }

  List<PropheticFood> get filteredFoods {
    var list = allFoods.toList();
    if (selectedCategory.value != null) {
      list = list.where((f) => f.category == selectedCategory.value).toList();
    }
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((f) {
        return f.name.toLowerCase().contains(q) ||
            f.quranOrHadithText.toLowerCase().contains(q) ||
            f.propheticGuidance.toLowerCase().contains(q) ||
            f.scientificBenefits.any((b) => b.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }

  List<PropheticRecipe> get filteredRecipes {
    var list = allRecipes.toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.healthBenefit.toLowerCase().contains(q) ||
            r.ingredients.any((i) => i.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }
}
