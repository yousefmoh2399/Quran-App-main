import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/features/azkar/data/models/azkar_model.dart';

class AzkarViewModel extends GetxController {
  final AzkarRepository _azkarRepository;

  AzkarViewModel({AzkarRepository? azkarRepository})
      : _azkarRepository = azkarRepository ?? AzkarRepository() {
    readJson();
  }

  bool isLoading = true;
  List<dynamic> items = [];
  List<AzkarModel> azkarModel = [];
  String searchQuery = '';

  double fontSize = 20.0;
  int currentIndex = 0;

  List<AzkarModel> get filteredAzkar {
    if (searchQuery.trim().isEmpty) {
      return azkarModel;
    }
    final q = searchQuery.trim().toLowerCase();
    return azkarModel.where((cat) {
      final name = cat.category?.toLowerCase() ?? '';
      return name.contains(q);
    }).toList();
  }

  Future<void> readJson() async {
    try {
      isLoading = true;
      update();
      final categoriesWithItems =
          await _azkarRepository.getAllCategoriesWithItems();
      azkarModel = categoriesWithItems.map((catWithItems) {
        return AzkarModel(
          id: catWithItems.category.id,
          category: catWithItems.category.name,
          array: catWithItems.items.map((item) {
            return ArrayAzkarModel(
              id: item.itemId ?? item.id,
              count: item.count,
              text: item.textAr,
            );
          }).toList(),
        );
      }).toList();
      items = azkarModel;
    } catch (e) {
      debugPrint('Error loading azkar from repository: $e');
    } finally {
      isLoading = false;
      update();
    }
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    update();
  }

  void increaseFont() {
    if (fontSize < 34) {
      fontSize += 2;
      update();
    }
  }

  void decreaseFont() {
    if (fontSize > 16) {
      fontSize -= 2;
      update();
    }
  }

  void resetFont() {
    fontSize = 20.0;
    update();
  }

  void changeIndex(int index) {
    currentIndex = index;
    update();
  }
}
