import 'package:shared_preferences/shared_preferences.dart';
import '../models/hadith_bookmark_model.dart';

class HadithBookmarkRepository {
  static const String _keyHadithBookmarks = 'pref_hadith_bookmarks_list';

  Future<List<HadithBookmarkModel>> getAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_keyHadithBookmarks) ?? [];
    return rawList
        .map((str) {
          try {
            return HadithBookmarkModel.fromJson(str);
          } catch (_) {
            return null;
          }
        })
        .whereType<HadithBookmarkModel>()
        .toList();
  }

  Future<void> saveBookmark(HadithBookmarkModel model) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllBookmarks();
    final index = list.indexWhere((item) => item.id == model.id);
    if (index >= 0) {
      list[index] = model;
    } else {
      list.insert(0, model);
    }
    final encoded = list.map((e) => e.toJson()).toList();
    await prefs.setStringList(_keyHadithBookmarks, encoded);
  }

  Future<void> removeBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllBookmarks();
    list.removeWhere((item) => item.id == id);
    final encoded = list.map((e) => e.toJson()).toList();
    await prefs.setStringList(_keyHadithBookmarks, encoded);
  }

  Future<void> toggleMemorized(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAllBookmarks();
    final index = list.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final current = list[index];
      list[index] = current.copyWith(isMemorized: !current.isMemorized);
      final encoded = list.map((e) => e.toJson()).toList();
      await prefs.setStringList(_keyHadithBookmarks, encoded);
    }
  }

  Future<bool> isBookmarked(String id) async {
    final list = await getAllBookmarks();
    return list.any((item) => item.id == id);
  }

  Future<bool> isMemorized(String id) async {
    final list = await getAllBookmarks();
    return list.any((item) => item.id == id && item.isMemorized);
  }

  Future<int> getMemorizedCount() async {
    final list = await getAllBookmarks();
    return list.where((item) => item.isMemorized).length;
  }
}
