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
  RxBool isLoading = false.obs;

  Future<void> readJson() async {
    try {
      isLoading.value = true;
      final names = await _namesRepository.getNames();
      nameOfAllah = names
          .map((n) => NamesOfAllahModel(name: n.name, text: n.text))
          .toList();
      items = nameOfAllah;
      isLoading.value = false;
      update();
    } catch (e, st) {
      isLoading.value = false;
      if (kDebugMode) {
        debugPrint('NamesOfAllah error: $e\n$st');
      }
    }
  }
}
