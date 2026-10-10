import 'package:get/get.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/seerah_event_model.dart';
import '../../data/repositories/seerah_repository.dart';

class SeerahController extends GetxController {
  final SeerahRepository _repository = SeerahRepository.instance;

  final RxInt selectedTab = 0.obs; // 0: Timeline, 1: Day in the Life
  final Rx<SeerahPeriod?> selectedPeriod = Rx<SeerahPeriod?>(null);
  final RxString searchQuery = ''.obs;

  final RxList<SeerahEvent> allEvents = <SeerahEvent>[].obs;
  final RxList<PropheticDayHabit> dayHabits = <PropheticDayHabit>[].obs;

  final RxSet<int> expandedEventIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    allEvents.assignAll(_repository.getAllEvents());
    dayHabits.assignAll(_repository.getDayInTheLifeHabits());
  }

  void setTab(int index) {
    if (selectedTab.value != index) {
      AppHaptics.selection();
      selectedTab.value = index;
    }
  }

  void filterByPeriod(SeerahPeriod? period) {
    AppHaptics.selection();
    selectedPeriod.value = period;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void toggleExpanded(int eventId) {
    AppHaptics.selection();
    if (expandedEventIds.contains(eventId)) {
      expandedEventIds.remove(eventId);
    } else {
      expandedEventIds.add(eventId);
    }
  }

  List<SeerahEvent> get filteredEvents {
    var list = allEvents.toList();
    if (selectedPeriod.value != null) {
      list = list.where((e) => e.period == selectedPeriod.value).toList();
    }
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.whatHappened.toLowerCase().contains(q) ||
            e.lifeLesson.toLowerCase().contains(q) ||
            e.keyFigures.any((f) => f.toLowerCase().contains(q)) ||
            e.yearLabel.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }
}
