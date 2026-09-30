import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
import 'package:quran_app_android/core/design/app_radius.dart';
import 'package:quran_app_android/core/design/app_spacing.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/core/design/components/empty_state.dart';
import 'package:quran_app_android/core/design/components/loading_skeleton.dart';
import 'package:quran_app_android/features/nameOfAllah/presentation/view_model/Names_Of_Allah_view_model.dart';
import 'package:quran_app_android/features/nameOfAllah/presentation/views/widgets/name_of_allah_card.dart';

class NameOfAllahView extends StatelessWidget {
  const NameOfAllahView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final controller = Get.isRegistered<NamesOfAllahViewModel>()
        ? Get.find<NamesOfAllahViewModel>()
        : Get.put(NamesOfAllahViewModel());

    return AppScaffold(
      title: 'أسماء الله الحسنى',
      constrainContentWidth: true,
      body: GetBuilder<NamesOfAllahViewModel>(
        init: controller,
        builder: (ctrl) {
          if (ctrl.isLoading) {
            return GridView.builder(
              padding: AppSpacing.screen,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.15,
              ),
              itemCount: 10,
              itemBuilder: (_, __) => const LoadingSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: AppRadius.borderMd,
              ),
            );
          }

          final list = ctrl.filteredNames;

          return Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  onChanged: (val) => ctrl.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'ابحث في أسماء الله الحسنى ومعانيها...',
                    prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
                    suffixIcon: ctrl.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => ctrl.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        title: 'لا توجد نتائج مطابقة',
                        message: 'جرب البحث بكلمة أو معنى آخر',
                        icon: Icons.search_off_rounded,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final int crossAxisCount = width > 840
                              ? 4
                              : (width > 560 ? 3 : 2);
                          final double aspectRatio = width > 560 ? 1.25 : 1.15;

                          return GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              left: AppSpacing.lg,
                              right: AppSpacing.lg,
                              bottom: AppSpacing.xl,
                              top: AppSpacing.xs,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final originalIndex =
                                  ctrl.nameOfAllah.indexOf(list[index]);
                              return NameOfAllahCard(
                                model: list[index],
                                index: originalIndex >= 0
                                    ? originalIndex
                                    : index,
                                fullList: ctrl.nameOfAllah,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
