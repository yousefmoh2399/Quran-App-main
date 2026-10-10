import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../data/models/seerah_event_model.dart';
import '../controllers/seerah_controller.dart';

class SeerahView extends StatefulWidget {
  const SeerahView({super.key});

  @override
  State<SeerahView> createState() => _SeerahViewState();
}

class _SeerahViewState extends State<SeerahView> {
  late final SeerahController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<SeerahController>()
        ? Get.find<SeerahController>()
        : Get.put(SeerahController());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'السيرة النبوية العطرة',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildTabSelector(colors),
            Expanded(
              child: Obx(() {
                return _controller.selectedTab.value == 0
                    ? _buildTimelineTab(colors)
                    : _buildDayInLifeTab(colors);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(dynamic colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider.withOpacity(0.4)),
      ),
      child: Obx(() {
        final currentTab = _controller.selectedTab.value;
        return Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'خط السيرة الزمني',
                icon: Icons.timeline_rounded,
                isSelected: currentTab == 0,
                onTap: () => _controller.setTab(0),
                colors: colors,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildTabButton(
                title: 'يوم في حياته ﷺ',
                icon: Icons.wb_sunny_outlined,
                isSelected: currentTab == 1,
                onTap: () => _controller.setTab(1),
                colors: colors,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab(dynamic colors) {
    return Column(
      children: [
        _buildSearchBar(colors),
        _buildPeriodFilters(colors),
        Expanded(
          child: Obx(() {
            final events = _controller.filteredEvents;
            if (events.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'لا توجد أحداث مطابقة للبحث أو التصنيف المحدد',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _buildTimelineCard(event, index, events.length, colors);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchBar(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: colors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.divider.withOpacity(0.3)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _controller.setSearchQuery,
          style: TextStyle(
            fontFamily: AppTypography.uiFont,
            fontSize: 13,
            color: colors.text,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن حدث، صحابي، أو درس...',
            hintStyle: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.5,
              color: colors.textSecondary.withOpacity(0.8),
            ),
            prefixIcon: Icon(Icons.search_rounded, size: 19, color: colors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      _controller.setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilters(dynamic colors) {
    final periods = [
      null,
      SeerahPeriod.preProphethood,
      SeerahPeriod.makkan,
      SeerahPeriod.madinan,
      SeerahPeriod.majorBattles,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Obx(() {
        final selected = _controller.selectedPeriod.value;
        return Row(
          children: periods.map((p) {
            final isSelected = selected == p;
            final label = p == null ? 'كافة المحطات' : p.displayName;

            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: InkWell(
                onTap: () => _controller.filterByPeriod(p),
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary.withOpacity(0.15) : colors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.divider.withOpacity(0.3),
                      width: isSelected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildTimelineCard(
    SeerahEvent event,
    int index,
    int totalCount,
    dynamic colors,
  ) {
    return Obx(() {
      final isExpanded = _controller.expandedEventIds.contains(event.id);

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Node & Vertical Line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withOpacity(0.12),
                  border: Border.all(color: colors.primary, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${event.id}',
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              if (index < totalCount - 1)
                Container(
                  width: 2,
                  height: isExpanded ? 240 : 130,
                  color: colors.primary.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // Event Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.divider.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _controller.toggleExpanded(event.id),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Year & Period Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                event.yearLabel,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.divider.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                event.period.displayName,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          event.title,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // What Happened Summary
                        Text(
                          event.whatHappened,
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 13,
                            color: colors.textSecondary,
                            height: 1.55,
                          ),
                        ),

                        // Key Figures Chips
                        if (event.keyFigures.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: event.keyFigures.map((fig) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                  border: Border.all(color: colors.divider.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_outline_rounded, size: 12, color: colors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      fig,
                                      style: TextStyle(
                                        fontFamily: AppTypography.uiFont,
                                        fontSize: 11,
                                        color: colors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // Expanded Life Lesson & References
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.09),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline_rounded,
                                        size: 15, color: Color(0xFFD4AF37)),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'الدرس المستفاد لحياتنا اليوم:',
                                      style: TextStyle(
                                        fontFamily: AppTypography.uiFont,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD4AF37),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  event.lifeLesson,
                                  style: TextStyle(
                                    fontFamily: AppTypography.uiFont,
                                    fontSize: 12.5,
                                    color: colors.text,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (event.quranOrHadithReference != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.bookmark_outline_rounded, size: 13, color: colors.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    event.quranOrHadithReference!,
                                    style: TextStyle(
                                      fontFamily: AppTypography.uiFont,
                                      fontSize: 11,
                                      color: colors.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],

                        // Toggle hint icon
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: colors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDayInLifeTab(dynamic colors) {
    final habits = _controller.dayHabits;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.divider.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Time of Day Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: colors.primary),
                          const SizedBox(width: 4),
                          Text(
                            habit.timeOfDay,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  habit.title,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  habit.description,
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 10),

                // Practical application card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 15, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'كيف نقتدي به اليوم؟ ',
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                              TextSpan(
                                text: habit.practicalApplication,
                                style: TextStyle(
                                  fontFamily: AppTypography.uiFont,
                                  fontSize: 12,
                                  color: colors.text,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Hadith Reference
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 13, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        habit.hadithReference,
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          fontSize: 11,
                          color: colors.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
