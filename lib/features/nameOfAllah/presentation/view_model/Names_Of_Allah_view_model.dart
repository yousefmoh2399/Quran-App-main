// ignore_for_file: file_names
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/util/app_url.dart';
import 'package:quran_app_android/features/nameOfAllah/data/models/Names_Of_Allah_model.dart';

class NamesOfAllahViewModel extends GetxController {
  NamesOfAllahViewModel() {
    readJson();
  }

  List<dynamic> items = [];
  List<NamesOfAllahModel> nameOfAllah = [];
  bool isLoading = true;
  String searchQuery = '';

  List<NamesOfAllahModel> get filteredNames {
    if (searchQuery.trim().isEmpty) {
      return nameOfAllah;
    }
    final query = searchQuery.trim().toLowerCase();
    return nameOfAllah.where((item) {
      final name = item.name?.toLowerCase() ?? '';
      final text = item.text?.toLowerCase() ?? '';
      return name.contains(query) || text.contains(query);
    }).toList();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    update();
  }

  Future<void> readJson() async {
    try {
      isLoading = true;
      update();
      final String response = await rootBundle.loadString(AppUrl.nameOfAllahUrl);
      final data = await json.decode(response);
      items = data;
      nameOfAllah.clear();
      for (int i = 0; i < items.length; i++) {
        nameOfAllah.add(NamesOfAllahModel.fromJson(items[i]));
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('NamesOfAllah error: $e\n$st');
      }
    } finally {
      isLoading = false;
      update();
    }
  }
}
