import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/khatma_circle_model.dart';
import '../../data/services/khatma_circles_service.dart';
import '../controllers/khatma_circles_controller.dart';
import 'khatma_circle_detail_view.dart';

class KhatmaQrScannerView extends StatefulWidget {
  final String? targetCircleId;
  const KhatmaQrScannerView({super.key, this.targetCircleId});

  @override
  State<KhatmaQrScannerView> createState() => _KhatmaQrScannerViewState();
}

class _KhatmaQrScannerViewState extends State<KhatmaQrScannerView>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final KhatmaCirclesController _circlesController;
  late final AnimationController _animController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _circlesController = Get.isRegistered<KhatmaCirclesController>()
        ? Get.find<KhatmaCirclesController>()
        : Get.put(KhatmaCirclesController());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _handleBarcode(raw.trim());
        break;
      }
    }
  }

  Future<void> _handleBarcode(String raw) async {
    setState(() => _isProcessing = true);
    AppHaptics.itemCompleted();

    final service = KhatmaCirclesService.instance;

    // 1. Check if Full Circle QR
    if (raw.startsWith(KhatmaCirclesService.qrCirclePrefix) || raw.contains('"id":"circle_')) {
      final circle = service.parseCircleQrPayload(raw);
      if (circle != null && mounted) {
        await _showCircleImportConfirmation(circle);
        return;
      }
    }

    // 2. Check if Member Progress QR
    if (raw.startsWith(KhatmaCirclesService.qrProgressPrefix) || (raw.contains('"cid":') && raw.contains('"m":'))) {
      final progressData = service.parseMemberProgressQrPayload(raw);
      if (progressData != null && mounted) {
        await _showProgressUpdateConfirmation(progressData);
        return;
      }
    }

    // Unrecognized format
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرمز الممسوح غير صالح لختمات تقرّب، يرجى المحاولة ثانية'),
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showCircleImportConfirmation(KhatmaCircle circle) async {
    final colors = context.appColors;
    final percent = (circle.progressPercentage * 100).toInt();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.group_work_rounded, color: colors.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تم العثور على ختمة عائلية!',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                          Text(
                            circle.title,
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 14,
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (circle.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    circle.description,
                    style: TextStyle(
                      fontFamily: AppTypography.uiFont,
                      fontSize: 12.5,
                      color: colors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'الأجزاء المنجزة',
                            style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 11, color: colors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${circle.completedJuzCount} / 30',
                            style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'نسبة الإنجاز',
                            style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 11, color: colors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$percent%',
                            style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 16, fontWeight: FontWeight.bold, color: colors.primary),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'الأجزاء المتاحة',
                            style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 11, color: colors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${circle.availableJuzCount}',
                            style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('انضمام ومزامنة الختمة'),
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

    if (confirmed == true && mounted) {
      await _circlesController.importOrUpdateCircle(circle);
      if (!mounted) return;
      Get.snackbar(
        'تم الانضمام بنجاح ✅',
        'تمت مزامنة ختمة "${circle.title}" في جهازك بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );
      Navigator.of(context).pop();
      Get.to(() => KhatmaCircleDetailView(circleId: circle.id));
    } else {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showProgressUpdateConfirmation(Map<String, dynamic> data) async {
    final colors = context.appColors;
    final circleId = data['circleId'] as String;
    final memberName = data['memberName'] as String;
    final juzNumbers = data['juzNumbers'] as List<int>;
    final status = data['status'] as String;

    final targetCircle = await KhatmaCirclesService.instance.getCircleById(circleId);
    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.green, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تحديث إنجاز القراءة اليومي',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                          Text(
                            targetCircle?.title ?? 'ختمة القرآن الجماعية',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 13,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_rounded, size: 18, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            'المشارك: $memberName',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 18, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            'الأجزاء المقروءة: ${juzNumbers.map((j) => 'الجزء $j').join('، ')}',
                            style: TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 13.5,
                              color: colors.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'الحالة: ${status == 'completed' ? 'تمت القراءة بنجاح ✅' : 'قيد القراءة 📖'}',
                            style: const TextStyle(
                              fontFamily: AppTypography.uiFont,
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('تأكيد تحديث الختمة'),
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

    if (confirmed == true && mounted) {
      final success = await _circlesController.applyMemberProgressFromQr(data);
      if (!mounted) return;
      if (success) {
        Get.snackbar(
          'تم تحديث الإنجاز بنجاح 🎉',
          'تم تسجيل إتمام ($memberName) للأجزاء المحددة في الختمة',
          snackPosition: SnackPosition.BOTTOM,
        );
        Navigator.of(context).pop();
        if (targetCircle != null) {
          Get.to(() => KhatmaCircleDetailView(circleId: targetCircle.id));
        }
      } else {
        Get.snackbar(
          'تنبيه',
          'لم يتم العثور على الختمة في جهازك، يرجى مسح رمز الختمة الشامل أولاً',
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() => _isProcessing = false);
      }
    } else {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إدخال رمز الختمة يدوياً'),
            content: TextField(
              controller: textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'الصق الشفرة المنسوخة هنا...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = textController.text.trim();
                  Navigator.pop(ctx);
                  if (text.isNotEmpty) {
                    _handleBarcode(text);
                  }
                },
                child: const Text('فحص الشفرة'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'مسح رمز QR',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: ValueListenableBuilder<MobileScannerState>(
                valueListenable: _scannerController,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: Colors.white,
                  );
                },
              ),
              onPressed: () => _scannerController.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
              onPressed: () => _scannerController.switchCamera(),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Camera scanner view
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

            // Scanning Overlay UI
            Center(
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Animated scanning beam
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Positioned(
                          top: _animController.value * 250,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFFD4AF37),
                                  Colors.greenAccent,
                                  const Color(0xFFD4AF37),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Instructions & Manual Input
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'وجّه الكاميرا نحو رمز QR على هاتف العائلة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'يدعم مسح ختمة جديدة بالكامل أو مسح إنجاز عضو لتحديث أجزائه مباشرة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE8D08D),
                      backgroundColor: Colors.white.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: _showManualInputDialog,
                    icon: const Icon(Icons.keyboard_rounded, size: 18),
                    label: const Text(
                      'إدخال أو لصق الشفرة يدوياً',
                      style: TextStyle(
                        fontFamily: AppTypography.uiFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
