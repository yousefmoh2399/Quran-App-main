import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/data/services/guide_engine.dart';

class TripDiaryController extends GetxController {
  final GuideEngine _guideEngine;

  TripDiaryController({GuideEngine? guideEngine})
      : _guideEngine = guideEngine ?? GuideEngine();

  final RxList<TripDiaryEntry> entries = <TripDiaryEntry>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'الكل'.obs;

  static const List<String> categories = [
    'الكل',
    'مشاعر وروحانيات',
    'دعاء مستجاب',
    'ذكريات الحرم',
    'عام',
  ];

  @override
  void onInit() {
    super.onInit();
    loadEntries();
  }

  Future<void> loadEntries() async {
    isLoading.value = true;
    try {
      final query = searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim();
      final all = await _guideEngine.getDiaryEntries(query: query);

      if (selectedCategory.value == 'الكل') {
        entries.assignAll(all);
      } else {
        entries.assignAll(all.where((e) => e.category == selectedCategory.value));
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('TripDiaryController.loadEntries error: $e\n$st');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String val) {
    searchQuery.value = val;
    loadEntries();
  }

  void setCategory(String category) {
    selectedCategory.value = category;
    loadEntries();
    AppHaptics.selection();
  }

  Future<void> addEntry({
    required String title,
    required String content,
    String category = 'عام',
  }) async {
    final entry = TripDiaryEntry(
      title: title.trim(),
      content: content.trim(),
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _guideEngine.addDiaryEntry(entry);
    AppHaptics.itemCompleted();
    await loadEntries();
  }

  Future<void> updateEntry(TripDiaryEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _guideEngine.updateDiaryEntry(updated);
    AppHaptics.selection();
    await loadEntries();
  }

  Future<void> deleteEntry(int id) async {
    await _guideEngine.deleteDiaryEntry(id);
    AppHaptics.selection();
    await loadEntries();
  }
}
