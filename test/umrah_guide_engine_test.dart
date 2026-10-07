import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/core/data/user_database.dart';
import 'package:quran_app_android/features/umrah/data/models/guide_models.dart';
import 'package:quran_app_android/features/umrah/data/services/guide_engine.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database testDb;
  late GuideEngine guideEngine;

  const mockGuideJson = '''
{
  "guide_id": "test_umrah",
  "title": "دليل مناسك العمرة التجريبي",
  "subtitle": "رفيق المعتمر",
  "version": 1,
  "disclaimer": "نص تجريبي - يحتاج مراجعة",
  "reviewedAt": "2026-10-01",
  "defaultSource": {
    "title": "نص تجريبي - يحتاج مراجعة",
    "author": "لجنة المراجعة",
    "reviewedAt": "2026-10-01",
    "status": "تجريبي"
  },
  "steps": [
    {
      "id": "ihram",
      "order": 1,
      "title": "الإحرام",
      "short_description": "النية من الميقات",
      "instruction": "نص تجريبي - يحتاج مراجعة: الاغتسال ولبس الإحرام",
      "source": {
        "title": "نص تجريبي - يحتاج مراجعة (الفقه الميسر)",
        "author": "لجنة من العلماء",
        "reviewedAt": "2026-10-01"
      },
      "duas": [
        {
          "id": "ihram_1",
          "title": "التلبية",
          "arabic_text": "لبيك اللهم لبيك",
          "source": "صحيح مسلم",
          "reviewedAt": "2026-10-01"
        }
      ]
    },
    {
      "id": "tawaf",
      "order": 2,
      "title": "طواف العمرة",
      "short_description": "سبعة أشواط",
      "instruction": "نص تجريبي - يحتاج مراجعة: الطواف حول الكعبة",
      "source": {
        "title": "نص تجريبي - يحتاج مراجعة",
        "reviewedAt": "2026-10-01"
      },
      "laps_duas": [
        {
          "lap": 1,
          "title": "الشوط الأول",
          "arabic_text": "ربنا آتنا في الدنيا حسنة",
          "source": "سنن أبي داود",
          "reviewedAt": "2026-10-01"
        }
      ]
    }
  ],
  "congestion_estimates": {
    "disclaimer": "تقدير تقريبي مبني على الأنماط المعتادة",
    "reviewedAt": "2026-10-01",
    "patterns": [
      {
        "id": "duha",
        "time_title": "وقت الضحى",
        "time_range": "08:00 - 11:00",
        "crowd_level": "منخفض",
        "level_code": "low",
        "level_percent": 0.3,
        "notes": "انسيابية عالية",
        "tip": "مناسب لكبار السن"
      }
    ]
  },
  "sources_review": [
    {
      "source_name": "كتيب المناسك",
      "publisher": "المجمع الفقهي",
      "edition": "الأولى",
      "status": "نص تجريبي - يحتاج مراجعة",
      "reviewed_at": "2026-10-01",
      "notes": "قيد المراجعة"
    }
  ]
}
''';

  setUpAll(() async {
    testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await UserDatabase.createTablesForTest(testDb);
    UserDatabase.customDatabaseForTesting = testDb;
    guideEngine = GuideEngine();
  });

  tearDownAll(() async {
    await testDb.close();
    UserDatabase.customDatabaseForTesting = null;
  });

  group('GuideEngine parsing and isolation tests', () {
    test('parseGuideJsonIsolate parses json accurately with reviewedAt and source', () {
      final guide = parseGuideJsonIsolate(mockGuideJson);
      expect(guide.id, equals('test_umrah'));
      expect(guide.steps.length, equals(2));
      expect(guide.steps.first.title, equals('الإحرام'));
      expect(guide.steps.first.source.reviewedAt, equals('2026-10-01'));
      expect(guide.steps.first.duas.length, equals(1));
      expect(guide.steps[1].lapsDuas.length, equals(1));
      expect(guide.congestion.patterns.length, equals(1));
      expect(guide.sourcesReview.first.reviewedAt, equals('2026-10-01'));
    });

    test('loadGuide with rawJsonString returns complete merged guide', () async {
      final guide = await guideEngine.loadGuide(rawJsonString: mockGuideJson);
      expect(guide.title, contains('دليل مناسك العمرة'));
      expect(guide.steps.first.isCompleted, isFalse);
    });

    test('hajj_guide.json asset file parses cleanly with 6 rites steps', () {
      final file = File('assets/content/hajj_guide.json');
      expect(file.existsSync(), isTrue);
      final jsonString = file.readAsStringSync();
      final guide = parseGuideJsonIsolate(jsonString);
      expect(guide.id, equals('hajj'));
      expect(guide.title, contains('الحج'));
      expect(guide.steps.length, equals(6));
      expect(guide.congestion.patterns, isNotEmpty);
      expect(guide.sourcesReview, isNotEmpty);
      for (final step in guide.steps) {
        expect(step.source.reviewedAt, isNotEmpty);
        expect(step.instruction, contains('نص تجريبي'));
      }
    });
  });

  group('GuideEngine progress persistence in UserDatabase', () {
    test('saveStepProgress and verify step is marked completed in loaded guide', () async {
      await guideEngine.saveStepProgress(
        guideId: 'test_umrah',
        stepId: 'ihram',
        isCompleted: true,
        currentLap: 1,
      );

      final guide = await guideEngine.loadGuide(rawJsonString: mockGuideJson);
      final ihramStep = guide.steps.firstWhere((s) => s.id == 'ihram');
      expect(ihramStep.isCompleted, isTrue);
      expect(ihramStep.currentLap, equals(1));

      final tawafStep = guide.steps.firstWhere((s) => s.id == 'tawaf');
      expect(tawafStep.isCompleted, isFalse);
    });

    test('resetGuideProgress clears all completion flags', () async {
      await guideEngine.resetGuideProgress('test_umrah');
      final guide = await guideEngine.loadGuide(rawJsonString: mockGuideJson);
      for (final step in guide.steps) {
        expect(step.isCompleted, isFalse);
      }
    });
  });

  group('TripDiary SQLite CRUD tests', () {
    test('add, search, update, and delete diary notes', () async {
      final entry = TripDiaryEntry(
        title: 'دعاء عند الكعبة',
        content: 'دعوت للأهل والوالدين عند الملتزم',
        category: 'مشاعر',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await guideEngine.addDiaryEntry(entry);
      expect(id, isPositive);

      final all = await guideEngine.getDiaryEntries();
      expect(all.length, equals(1));
      expect(all.first.title, equals('دعاء عند الكعبة'));

      // Search matching
      final searchHit = await guideEngine.getDiaryEntries(query: 'الملتزم');
      expect(searchHit.length, equals(1));

      final searchMiss = await guideEngine.getDiaryEntries(query: 'غير موجود');
      expect(searchMiss, isEmpty);

      // Update
      final updated = all.first.copyWith(title: 'دعاء مستجاب عند الكعبة');
      await guideEngine.updateDiaryEntry(updated);
      final rechecked = await guideEngine.getDiaryEntries();
      expect(rechecked.first.title, equals('دعاء مستجاب عند الكعبة'));

      // Delete
      await guideEngine.deleteDiaryEntry(id);
      final emptyList = await guideEngine.getDiaryEntries();
      expect(emptyList, isEmpty);
    });
  });
}
