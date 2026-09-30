import 'package:get/get.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/features/azkar/data/models/azkar_model.dart';

class AzkarViewModel extends GetxController {
  final AzkarRepository _azkarRepository;

  AzkarViewModel({AzkarRepository? azkarRepository})
      : _azkarRepository = azkarRepository ?? AzkarRepository() {
    readJson();
  }

  List<dynamic> items = [];
  List<AzkarModel> azkarModel = [];

  Future<void> readJson() async {
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
    update();
  }

  double fontSize = 20;

  void increaseFont() {
    fontSize++;
    update();
  }

  void decreaseFont() {
    fontSize--;
    update();
  }

  int currentIndex = 0;

  void changeIndex(index) {
    currentIndex = index;
    update();
  }
}
