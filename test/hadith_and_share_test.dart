import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/service/settings/SettingsServices.dart';
import 'package:quran_app_android/core/util/routes/routes.dart';
import 'package:quran_app_android/features/hadith/data/models/hadith_bookmark_model.dart';
import 'package:quran_app_android/features/hadith/data/repositories/hadith_bookmark_repository.dart';
import 'package:quran_app_android/features/share/presentation/views/app_share_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsServices();
    settings.sharedPref = prefs;
    Get.put<SettingsServices>(settings);
  });

  group('Hadith Bookmark Model & Repository Tests', () {
    test('HadithBookmarkModel serialization and deserialization preserves all fields', () {
      final model = HadithBookmarkModel(
        id: '2_5',
        chapterIndex: 2,
        itemIndex: 5,
        chapterName: 'باب الوضوء',
        hadithNumber: 34,
        text: 'إنما الأعمال بالنيات',
        source: 'موطأ الإمام مالك',
        savedAt: DateTime(2026, 10, 4, 12, 0),
      );

      final map = model.toMap();
      expect(map['id'], '2_5');
      expect(map['chapterIndex'], 2);
      expect(map['itemIndex'], 5);
      expect(map['chapterName'], 'باب الوضوء');
      expect(map['hadithNumber'], 34);

      final fromMap = HadithBookmarkModel.fromMap(map);
      expect(fromMap.id, model.id);
      expect(fromMap.chapterIndex, 2);
      expect(fromMap.itemIndex, 5);
      expect(fromMap.chapterName, 'باب الوضوء');
      expect(fromMap.hadithNumber, 34);
      expect(fromMap.text, model.text);
    });

    test('HadithBookmarkRepository saves, queries, and removes bookmarks', () async {
      final repo = HadithBookmarkRepository();
      expect(await repo.getAllBookmarks(), isEmpty);

      final b1 = HadithBookmarkModel(
        id: '0_1',
        chapterIndex: 0,
        itemIndex: 1,
        chapterName: 'وقوت الصلاة',
        hadithNumber: 2,
        text: 'صلاة الجماعة تفضل صلاة الفذ بخمس وعشرين درجة',
      );

      await repo.saveBookmark(b1);
      final list = await repo.getAllBookmarks();
      expect(list.length, 1);
      expect(list.first.id, '0_1');
      expect(await repo.isBookmarked('0_1'), isTrue);
      expect(await repo.isBookmarked('0_2'), isFalse);

      await repo.removeBookmark('0_1');
      expect(await repo.isBookmarked('0_1'), isFalse);
      expect(await repo.getAllBookmarks(), isEmpty);
    });
  });

  group('App Share View & Routes Tests', () {
    test('AppRoutes.appShare is registered with correct route string', () {
      expect(AppRoutes.appShare, '/appShare');
      final routeNames = AppRoutes.routes.map((p) => p.name).toList();
      expect(routeNames.contains(AppRoutes.appShare), isTrue);
    });

    test('AppShareView contains essential share messaging and direct store link', () {
      expect(AppShareView.appDownloadUrl.isNotEmpty, isTrue);
      expect(AppShareView.shareMessage.contains('مصحف'), isTrue);
      expect(AppShareView.shareMessage.contains('مواقيت الصلاة'), isTrue);
      expect(AppShareView.shareMessage.contains(AppShareView.appDownloadUrl), isTrue);
    });
  });
}
