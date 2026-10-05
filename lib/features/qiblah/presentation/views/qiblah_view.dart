import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/components/app_scaffold.dart';
import 'package:quran_app_android/features/qiblah/presentation/view_model/qiblah_view_model.dart';
import 'package:quran_app_android/features/qiblah/presentation/views/widget/go_settings_view.dart';
import 'package:quran_app_android/features/qiblah/presentation/views/widget/qiblah_stream_builder.dart';

class QiblahView extends StatefulWidget {
  const QiblahView({super.key});

  @override
  State<QiblahView> createState() => _QiblahViewState();
}

class _QiblahViewState extends State<QiblahView>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  final double begin = 0.0;

  final QiblahViewModel qiblahViewModel = Get.isRegistered<QiblahViewModel>()
      ? Get.find<QiblahViewModel>()
      : Get.put(QiblahViewModel());

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'اتجاه القبلة',
      constrainContentWidth: true,
      body: GetBuilder<QiblahViewModel>(
        init: qiblahViewModel,
        builder: (controller) {
          // If permission is not granted AND no location is known, show settings request
          if (!controller.isDone.value && !controller.hasLocation.value) {
            return const GoSettingsView();
          }

          return QiblahStreamBuilder(
            animationController: animationController,
            begin: begin,
            qiblaDirection: controller.qiblaDirection.value,
            userLatitude: controller.userLatitude.value,
            userLongitude: controller.userLongitude.value,
          );
        },
      ),
    );
  }
}

