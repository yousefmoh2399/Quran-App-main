// ignore_for_file: file_names
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PngTreeViewModel extends GetxController {
  int counter = 0;
  int counterTree = 0; // Completed cycles
  int targetCount = 33;
  int selectedZekrIndex = 0;

  static const List<String> zekrList = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'أَسْتَغْفِرُ اللَّهَ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'اللَّهُمَّ صَلِّ عَلَى نَبِيِّنَا مُحَمَّدٍ',
  ];

  String get currentZekr => zekrList[selectedZekrIndex];

  int get totalTasbeeh => (counterTree * targetCount) + counter;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    counter = prefs.getInt('counter') ?? 0;
    counterTree = prefs.getInt('counterTree') ?? 0;
    targetCount = prefs.getInt('targetCount') ?? 33;
    selectedZekrIndex = prefs.getInt('selectedZekrIndex') ?? 0;
    if (selectedZekrIndex >= zekrList.length) selectedZekrIndex = 0;
    update();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', counter);
    await prefs.setInt('counterTree', counterTree);
    await prefs.setInt('targetCount', targetCount);
    await prefs.setInt('selectedZekrIndex', selectedZekrIndex);
  }

  void setSelectedZekr(int index) {
    if (index >= 0 && index < zekrList.length) {
      selectedZekrIndex = index;
      counter = 0;
      saveData();
      update();
    }
  }

  void setTarget(int target) {
    targetCount = target;
    counter = 0;
    saveData();
    update();
  }

  void increaseCounter() async {
    counter++;
    HapticFeedback.lightImpact();

    if (counter >= targetCount) {
      counterTree += 1;
      counter = 0;
      HapticFeedback.heavyImpact();
      HapticFeedback.vibrate();
    }
    await saveData();
    update();
  }

  void decreaseCounter() async {
    if (counter > 0) {
      counter--;
      HapticFeedback.selectionClick();
      await saveData();
      update();
    }
  }

  void clearCounter() async {
    counter = 0;
    counterTree = 0;
    HapticFeedback.vibrate();
    await saveData();
    update();
  }

  // Backwards compatibility alias for legacy widgets
  void clearConter() => clearCounter();
}
