import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quran_app_android/core/services/app_haptics_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/khatma_circle_model.dart';
import '../../data/services/khatma_circles_service.dart';

class KhatmaCirclesController extends GetxController {
  final KhatmaCirclesService _service;

  KhatmaCirclesController({KhatmaCirclesService? service})
      : _service = service ?? KhatmaCirclesService();

  final RxList<KhatmaCircle> circles = <KhatmaCircle>[].obs;
  final Rxn<KhatmaCircle> currentCircle = Rxn<KhatmaCircle>();
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCircles();
  }

  Future<void> loadCircles() async {
    isLoading.value = true;
    try {
      final list = await _service.getCircles();
      circles.assignAll(list);
    } catch (e, st) {
      if (kDebugMode) debugPrint('KhatmaCirclesController.loadCircles error: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCircleDetail(String id) async {
    try {
      final c = await _service.getCircleById(id);
      currentCircle.value = c;
    } catch (e, st) {
      if (kDebugMode) debugPrint('loadCircleDetail error: $e\n$st');
    }
  }

  Future<KhatmaCircle> createCircle({
    required String title,
    String description = '',
    String? targetDate,
  }) async {
    final created = await _service.createCircle(
      title: title,
      description: description,
      targetDate: targetDate,
    );
    AppHaptics.itemCompleted();
    await loadCircles();
    return created;
  }

  Future<void> updateJuzAssignment(
    int juzNumber, {
    required String assignedTo,
    required String status,
  }) async {
    final circle = currentCircle.value;
    if (circle == null) return;

    await _service.updateJuzAssignment(
      circle.id,
      juzNumber,
      assignedTo: assignedTo,
      status: status,
    );
    AppHaptics.selection();
    await loadCircleDetail(circle.id);
    await loadCircles();
  }

  Future<void> toggleJuzCompleted(int juzNumber, bool isCompleted) async {
    final circle = currentCircle.value;
    if (circle == null) return;

    await _service.toggleJuzCompleted(circle.id, juzNumber, isCompleted);
    if (isCompleted) {
      AppHaptics.itemCompleted();
    } else {
      AppHaptics.selection();
    }
    await loadCircleDetail(circle.id);
    await loadCircles();
  }

  Future<void> deleteCircle(String id) async {
    await _service.deleteCircle(id);
    AppHaptics.selection();
    if (currentCircle.value?.id == id) {
      currentCircle.value = null;
    }
    await loadCircles();
  }

  void shareViaWhatsApp(KhatmaCircle circle) {
    AppHaptics.selection();
    final text = _service.generateWhatsAppShareText(circle);
    Share.share(text);
  }

  String getShareText(KhatmaCircle circle) {
    return _service.generateWhatsAppShareText(circle);
  }

  // ==========================================
  // OFFLINE QR SYSTEM INTEGRATION
  // ==========================================

  String getCircleQrPayload(KhatmaCircle circle) {
    return _service.generateCircleQrPayload(circle);
  }

  String getMemberProgressQrPayload({
    required String circleId,
    required String memberName,
    required List<int> juzNumbers,
    required String status,
  }) {
    return _service.generateMemberProgressQrPayload(
      circleId: circleId,
      memberName: memberName,
      juzNumbers: juzNumbers,
      status: status,
    );
  }

  Future<KhatmaCircle> importOrUpdateCircle(KhatmaCircle circle) async {
    final saved = await _service.importOrUpdateCircle(circle);
    AppHaptics.itemCompleted();
    await loadCircles();
    if (currentCircle.value?.id == circle.id) {
      await loadCircleDetail(circle.id);
    }
    return saved;
  }

  Future<bool> applyMemberProgressFromQr(Map<String, dynamic> data) async {
    final circleId = data['circleId'] as String;
    final memberName = data['memberName'] as String;
    final juzNumbers = data['juzNumbers'] as List<int>;
    final status = data['status'] as String;

    final success = await _service.applyMemberProgress(
      circleId: circleId,
      memberName: memberName,
      juzNumbers: juzNumbers,
      status: status,
    );

    if (success) {
      AppHaptics.itemCompleted();
      await loadCircles();
      if (currentCircle.value?.id == circleId) {
        await loadCircleDetail(circleId);
      }
    }
    return success;
  }
}
