import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app_android/features/ruqyah/data/models/ruqyah_item_model.dart';
import 'package:quran_app_android/features/ruqyah/data/repositories/ruqyah_repository.dart';
import 'package:quran_app_android/features/ruqyah/presentation/controllers/ruqyah_controller.dart';
import 'package:quran_app_android/features/seerah/data/models/seerah_event_model.dart';
import 'package:quran_app_android/features/seerah/data/repositories/seerah_repository.dart';
import 'package:quran_app_android/features/seerah/presentation/controllers/seerah_controller.dart';
import 'package:quran_app_android/features/spiritual_milestones/data/models/spiritual_milestone_model.dart';
import 'package:quran_app_android/features/spiritual_milestones/data/services/spiritual_milestones_service.dart';
import 'package:quran_app_android/features/spiritual_milestones/presentation/controllers/spiritual_milestones_controller.dart';
import 'package:quran_app_android/features/prophetic_medicine/data/models/prophetic_food_model.dart';
import 'package:quran_app_android/features/prophetic_medicine/data/repositories/prophetic_medicine_repository.dart';
import 'package:quran_app_android/features/prophetic_medicine/presentation/controllers/prophetic_medicine_controller.dart';
import 'package:quran_app_android/features/special_prayers/data/models/special_prayer_model.dart';
import 'package:quran_app_android/features/special_prayers/data/repositories/special_prayers_repository.dart';
import 'package:quran_app_android/features/special_prayers/presentation/controllers/special_prayers_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. الرقية الشرعية التفاعلية (Interactive Ruqyah)', () {
    test('Ruqyah repository returns non-empty authentic items', () {
      final repo = RuqyahRepository.instance;
      final items = repo.getAllItems();
      expect(items.isNotEmpty, isTrue);
      expect(items.length, greaterThanOrEqualTo(10));

      final tahseenItems = repo.getItemsByCategory(RuqyahCategory.tahseen);
      final shifaItems = repo.getItemsByCategory(RuqyahCategory.shifa);
      expect(tahseenItems.isNotEmpty, isTrue);
      expect(shifaItems.isNotEmpty, isTrue);
    });

    test('RuqyahController tracks progress and increments correctly', () {
      final controller = RuqyahController();
      controller.loadItems();

      expect(controller.items.isNotEmpty, isTrue);
      expect(controller.currentCount.value, equals(0));
      expect(controller.overallProgress, equals(0.0));

      final firstTarget = controller.currentItem!.targetCount;
      for (int i = 0; i < firstTarget; i++) {
        controller.tapCurrent();
      }

      expect(controller.completedItemIds.contains(controller.currentItem!.id), isTrue);
    });
  });

  group('2. السيرة النبوية العطرة (Seerah Timeline)', () {
    test('SeerahRepository returns events and prophetic day habits', () {
      final repo = SeerahRepository.instance;
      final events = repo.getAllEvents();
      expect(events.length, greaterThanOrEqualTo(15));

      final habits = repo.getDayInTheLifeHabits();
      expect(habits.length, greaterThanOrEqualTo(5));

      for (final event in events) {
        expect(event.title.isNotEmpty, isTrue);
        expect(event.whatHappened.isNotEmpty, isTrue);
        expect(event.lifeLesson.isNotEmpty, isTrue);
        expect(event.keyFigures.isNotEmpty, isTrue);
      }
    });

    test('SeerahController filters correctly by period and search', () {
      final controller = SeerahController();
      controller.onInit();

      expect(controller.filteredEvents.isNotEmpty, isTrue);

      controller.filterByPeriod(SeerahPeriod.makkan);
      for (final e in controller.filteredEvents) {
        expect(e.period, equals(SeerahPeriod.makkan));
      }

      controller.filterByPeriod(null);
      controller.setSearchQuery('بدر');
      expect(controller.filteredEvents.any((e) => e.title.contains('بدر') || e.whatHappened.contains('بدر')), isTrue);
    });
  });

  group('3. ميزان الحسنات وغِراس الجنة (Spiritual Milestones)', () {
    test('Service calculates trees and lifetime zikr counts accurately', () async {
      final service = SpiritualMilestonesService.instance;
      await service.resetAll();

      expect(service.getTotalCount(), equals(0));
      expect(service.getTreesPlanted(), equals(0));

      // Add 2,500 Tasbeeh
      await service.addCount(ZikrType.tasbeeh, 2500);
      expect(service.getCount(ZikrType.tasbeeh), equals(2500));
      expect(service.getTotalCount(), equals(2500));
      expect(service.getTreesPlanted(), equals(2)); // 2500 ~/ 1000 = 2 trees
      expect(service.getNextTreeProgress(), equals(500)); // 2500 % 1000 = 500

      // Add 1,000 Salawat
      await service.addCount(ZikrType.salawat, 1000);
      expect(service.getTotalCount(), equals(3500));
      expect(service.getTreesPlanted(), equals(3));
    });

    test('Badges unlock when count requirements are met', () async {
      final service = SpiritualMilestonesService.instance;
      await service.resetAll();

      final controller = SpiritualMilestonesController();
      await controller.loadData();

      // First tree badge (1000 count) should initially be locked
      final tree1Badge = controller.badges.firstWhere((b) => b.id == 'tree_1');
      expect(controller.isBadgeUnlocked(tree1Badge), isFalse);

      // Increment by 1000
      await controller.incrementZikr(ZikrType.tasbeeh, amount: 1000);
      expect(controller.isBadgeUnlocked(tree1Badge), isTrue);
    });
  });

  group('4. الطب النبوي والأغذية القرآنية (Prophetic Nutrition)', () {
    test('Repository contains all 10 authentic prophetic foods and recipes', () {
      final repo = PropheticMedicineRepository.instance;
      final foods = repo.getAllFoods();
      expect(foods.length, equals(10));

      final talbinah = foods.firstWhere((f) => f.name.contains('التلبينة'));
      expect(talbinah.recipes.isNotEmpty, isTrue);
      expect(talbinah.scientificBenefits.isNotEmpty, isTrue);

      final honey = foods.firstWhere((f) => f.name.contains('عسل'));
      expect(honey.recipes.isNotEmpty, isTrue);

      final allRecipes = repo.getAllRecipes();
      expect(allRecipes.length, greaterThanOrEqualTo(4));
    });

    test('PropheticMedicineController handles category and text searches', () {
      final controller = PropheticMedicineController();
      controller.onInit();

      expect(controller.filteredFoods.length, equals(10));
      controller.setCategory(PropheticFoodCategory.quranic);
      for (final f in controller.filteredFoods) {
        expect(f.category, equals(PropheticFoodCategory.quranic));
      }

      controller.setCategory(null);
      controller.setSearchQuery('الشعير');
      expect(controller.filteredFoods.any((f) => f.name.contains('التلبينة')), isTrue);
    });
  });

  group('5. دليل الصلوات الخاصة (Special Prayers)', () {
    test('Special prayers repository contains 6 comprehensive prayers', () {
      final repo = SpecialPrayersRepository.instance;
      final prayers = repo.getAllPrayers();
      expect(prayers.length, equals(6));

      // Janazah has 4 takbeerat
      final janazah = prayers.firstWhere((p) => p.title.contains('الجنازة'));
      expect(janazah.steps.length, equals(4));
      expect(janazah.steps[0].title, contains('التكبيرة الأولى'));
      expect(janazah.steps[1].title, contains('التكبيرة الثانية'));
      expect(janazah.steps[2].title, contains('التكبيرة الثالثة'));
      expect(janazah.steps[3].title, contains('التكبيرة الرابعة'));

      // Istikhara has full authentic dua
      final istikhara = prayers.firstWhere((p) => p.title.contains('الاستخارة'));
      final istikharaStep = istikhara.steps.firstWhere((s) => s.detailedDua != null);
      expect(istikharaStep.detailedDua, contains('اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ'));

      // Sujood covers Sahw, Tilawah, Shukr
      final sujood = prayers.firstWhere((p) => p.title.contains('السجدات'));
      expect(sujood.steps.length, equals(3));
    });

    test('SpecialPrayersController filters and searches prayers', () {
      final controller = SpecialPrayersController();
      controller.onInit();

      expect(controller.filteredPrayers.length, equals(6));

      controller.setCategory(SpecialPrayerCategory.occasional);
      for (final p in controller.filteredPrayers) {
        expect(p.category, equals(SpecialPrayerCategory.occasional));
      }

      controller.setCategory(null);
      controller.setSearchQuery('استخارة');
      expect(controller.filteredPrayers.length, equals(1));
    });
  });

  group('6. Quality & Vocabulary Standards Check', () {
    test('No unpolished "أوفلاين" or "بدون إنترنت" in repository content', () {
      final ruqyahItems = RuqyahRepository.instance.getAllItems();
      for (final item in ruqyahItems) {
        expect(item.arabicText.contains('أوفلاين'), isFalse);
        expect(item.arabicText.contains('بدون إنترنت'), isFalse);
      }

      final seerahEvents = SeerahRepository.instance.getAllEvents();
      for (final event in seerahEvents) {
        expect(event.whatHappened.contains('أوفلاين'), isFalse);
        expect(event.lifeLesson.contains('أوفلاين'), isFalse);
      }

      final prayers = SpecialPrayersRepository.instance.getAllPrayers();
      for (final prayer in prayers) {
        expect(prayer.definitionAndVirtue.contains('أوفلاين'), isFalse);
        for (final step in prayer.steps) {
          expect(step.description.contains('أوفلاين'), isFalse);
        }
      }
    });
  });
}
