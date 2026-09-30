import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/design/app_colors.dart';
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
  Future<Position>? getPosition;

  final QiblahViewModel qiblahViewModel = Get.isRegistered<QiblahViewModel>()
      ? Get.find<QiblahViewModel>()
      : Get.put(QiblahViewModel());

  @override
  void initState() {
    super.initState();
    qiblahViewModel.requestLocationPermission();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    getPosition = _determinePosition();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppScaffold(
      title: 'اتجاه القبلة',
      constrainContentWidth: true,
      body: GetBuilder<QiblahViewModel>(
        init: qiblahViewModel,
        builder: (controller) {
          if (!controller.isDone.value) {
            return const GoSettingsView();
          }

          return FutureBuilder<Position>(
            future: getPosition,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                );
              }

              if (snapshot.hasError) {
                // Fallback to Cairo coordinates if location retrieval times out
                final Coordinates coordinates = Coordinates(30.0444, 31.2357);
                final double qiblaDirection = Qibla(coordinates).direction;
                return QiblahStreamBuilder(
                  animationController: animationController,
                  begin: begin,
                  qiblaDirection: qiblaDirection,
                );
              }

              if (snapshot.hasData) {
                final Position pos = snapshot.data!;
                final Coordinates coordinates = Coordinates(pos.latitude, pos.longitude);
                final double qiblaDirection = Qibla(coordinates).direction;
                return QiblahStreamBuilder(
                  animationController: animationController,
                  begin: begin,
                  qiblaDirection: qiblaDirection,
                );
              }

              return const GoSettingsView();
            },
          );
        },
      ),
    );
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied');
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.medium,
    timeLimit: const Duration(seconds: 15),
  );
}
