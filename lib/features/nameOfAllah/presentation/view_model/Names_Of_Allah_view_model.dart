// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/data/data.dart';
import 'package:quran_app_android/features/nameOfAllah/data/models/Names_Of_Allah_model.dart';

class NamesOfAllahViewModel extends GetxController {
  final NamesRepository _namesRepository;

  NamesOfAllahViewModel({NamesRepository? namesRepository})
      : _namesRepository = namesRepository ?? NamesRepository() {
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

      final names = await _namesRepository.getNames();
      nameOfAllah = names
          .map((n) => NamesOfAllahModel(name: n.name, text: n.text))
          .toList();
      items = nameOfAllah;
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
