import 'package:flutter/material.dart';
import 'package:quran_app_android/features/home/presentation/view_model/home_view_model.dart';
import 'package:quran_app_android/features/home/presentation/views/widget/home_grid_view_items.dart';

class HomeGridView extends StatelessWidget {
  const HomeGridView({super.key, required this.controller});
  final HomeViewModel controller;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 0.0,
            mainAxisSpacing: 0.0,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return HomeGridViewItems(
              page: controller.routes[index],
              index: index,
              image: controller.images[index],
              list: controller.titles[index],
            );
          },
        ),
      ),
    );
  }
}
