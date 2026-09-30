import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/util/app_url.dart';
import 'package:quran_app_android/features/azkar/data/models/azkar_model.dart';

class AzkarViewModel extends GetxController {
  AzkarViewModel() {
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
      final String response = await rootBundle.loadString(AppUrl.adhkarUrl);
      final data = await json.decode(response);
      items = data;
      azkarModel.clear();
      for (int i = 0; i < items.length; i++) {
        azkarModel.add(AzkarModel.fromJson(items[i]));
      }
    } catch (e) {
      // Error handling
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
