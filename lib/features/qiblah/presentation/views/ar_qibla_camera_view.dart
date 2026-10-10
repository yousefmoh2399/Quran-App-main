import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../view_model/qiblah_view_model.dart';

/// Interactive Offline AR Qibla Camera View.
/// Uses device back camera and magnetometer / compass sensor to project
/// the Kaaba in 3D-space overlaid onto the real world.
class ArQiblaCameraView extends StatefulWidget {
  final double? qiblaDirection;
  final double? userLatitude;
  final double? userLongitude;

  const ArQiblaCameraView({
    super.key,
    this.qiblaDirection,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<ArQiblaCameraView> createState() => _ArQiblaCameraViewState();
}

class _ArQiblaCameraViewState extends State<ArQiblaCameraView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _cameraError = false;
  String _cameraErrorMessage = '';
  bool _isFlashOn = false;

  late final QiblahViewModel _qiblahViewModel;

  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentHeading = 0.0;
  bool _hasReceivedHeading = false;
  bool _isAligned = false;
  bool _hasHapticTriggered = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _qiblahViewModel = Get.isRegistered<QiblahViewModel>()
        ? Get.find<QiblahViewModel>()
        : Get.put(QiblahViewModel());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCamera();
    _listenToCompass();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = true;
            _cameraErrorMessage = 'لا توجد كاميرا متاحة في هذا الجهاز';
          });
        }
        return;
      }

      // Pick back camera if available, otherwise first
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _cameraController = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final isDenied = e is CameraException && (e.code == 'CameraAccessDenied' || e.code == 'CameraAccessRestricted');
        setState(() {
          _cameraError = true;
          _cameraErrorMessage = isDenied
              ? 'تم رفض إذن الكاميرا. يرجى السماح به من الإعدادات للرؤية المعززة.'
              : 'تعذر تشغيل الكاميرا: $e';
        });
      }
    }
  }

  void _listenToCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final heading = event.heading;
      if (heading != null) {
        setState(() {
          _currentHeading = heading;
          _hasReceivedHeading = true;
        });
        _checkAlignment();
      }
    });
  }

  void _checkAlignment() {
    final qibla = _resolvedQiblaDirection;
    final delta = _calculateDeltaAngle(qibla, _currentHeading);
    final isNowAligned = delta.abs() <= 6.0;

    if (isNowAligned && !_hasHapticTriggered) {
      AppHaptics.qiblaAligned();
      _hasHapticTriggered = true;
    } else if (!isNowAligned && delta.abs() > 10.0) {
      _hasHapticTriggered = false;
    }

    if (isNowAligned != _isAligned) {
      setState(() {
        _isAligned = isNowAligned;
      });
    }
  }

  double get _resolvedQiblaDirection {
    if (widget.qiblaDirection != null && widget.qiblaDirection! > 0) {
      return widget.qiblaDirection!;
    }
    return _qiblahViewModel.qiblaDirection.value;
  }

  double get _resolvedLatitude {
    if (widget.userLatitude != null && widget.userLatitude! != 0) {
      return widget.userLatitude!;
    }
    return _qiblahViewModel.userLatitude.value;
  }

  double get _resolvedLongitude {
    if (widget.userLongitude != null && widget.userLongitude! != 0) {
      return widget.userLongitude!;
    }
    return _qiblahViewModel.userLongitude.value;
  }

  /// Calculates the shortest angular delta between heading and target in degrees [-180, 180]
  double _calculateDeltaAngle(double targetAngle, double currentHeading) {
    double diff = (targetAngle - currentHeading) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff;
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() => _isFlashOn = true);
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassSubscription?.cancel();
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.of(context).size;
    final qiblaAngle = _resolvedQiblaDirection;
    final delta = _calculateDeltaAngle(qiblaAngle, _currentHeading);

    final double distanceKm = Geolocator.distanceBetween(
      _resolvedLatitude != 0 ? _resolvedLatitude : 30.0444,
      _resolvedLongitude != 0 ? _resolvedLongitude : 31.2357,
      21.422487,
      39.826206,
    ) / 1000;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Camera Feed or Fallback Simulator
            if (_isCameraInitialized && _cameraController != null)
              _buildCameraPreview(size)
            else
              _buildCameraFallback(colors),

            // 2. HUD Reticle in center
            _buildCenterReticle(colors),

            // 3. AR Kaaba Marker & Projected Compass
            _buildARKaabaOverlay(size, delta),

            // 4. Directional Off-Screen Guide Arrows
            _buildOffScreenGuide(size, delta, colors),

            // 5. Top Bar Controls & Live Metrics
            _buildTopBar(context, colors, distanceKm, qiblaAngle),

            // 6. Bottom Guidance Card & Status
            _buildBottomGuidance(colors, delta),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(Size size) {
    final controller = _cameraController!;
    var scale = size.aspectRatio * controller.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildCameraFallback(AppColorsExtension colors) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF020617)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withOpacity(0.12),
                border: Border.all(color: colors.primary.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(Icons.videocam_off_rounded, size: 48, color: colors.primary),
            ),
            AppSpacing.verticalMd,
            Text(
              _cameraError ? 'وضع المحاكاة التفاعلي' : 'جاري تشغيل الكاميرا...',
              style: TextStyle(
                fontFamily: AppTypography.uiFont,
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_cameraErrorMessage.isNotEmpty) ...[
              AppSpacing.verticalXs,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _cameraErrorMessage.contains('إذن')
                      ? _cameraErrorMessage
                      : 'تنبيه: الكاميرا غير مفعلة، تعمل البوصلة ومؤشرات الواقع المعزز بكفاءة تامة.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFont,
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              if (_cameraError && _cameraErrorMessage.contains('إذن')) ...[
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.settings_rounded, size: 18),
                  label: const Text(
                    'فتح إعدادات الجهاز لمنح الإذن',
                    style: TextStyle(fontFamily: AppTypography.uiFont, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => openAppSettings(),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterReticle(AppColorsExtension colors) {
    final accentColor = _isAligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37);

    return IgnorePointer(
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isAligned ? 190 : 160,
          height: _isAligned ? 190 : 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withOpacity(_isAligned ? 0.9 : 0.4),
              width: _isAligned ? 2.5 : 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer dashed pulse if aligned
              if (_isAligned)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Crosshair lines
              Container(
                width: 14,
                height: 2,
                color: accentColor.withOpacity(0.8),
              ),
              Container(
                width: 2,
                height: 14,
                color: accentColor.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildARKaabaOverlay(Size size, double delta) {
    // Horizontal Field Of View in degrees (standard mobile wide camera ~ 65°)
    const double hfov = 60.0;
    final bool isVisibleInView = delta.abs() <= (hfov / 2);

    if (!isVisibleInView) {
      return const SizedBox.shrink();
    }

    // Normalized X position from -1.0 (left edge) to 1.0 (right edge)
    final double normX = delta / (hfov / 2);
    final double screenCenterX = size.width / 2;
    // Account for RTL vs standard coordinate
    final double targetX = screenCenterX - (normX * (size.width * 0.42));
    final double targetY = size.height * 0.44;

    return Positioned(
      left: targetX - 55,
      top: targetY - 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Kaaba Icon with Glowing Halo
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = _isAligned ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAligned
                        ? const Color(0xFF10B981).withOpacity(0.25)
                        : const Color(0xFFD4AF37).withOpacity(0.2),
                    border: Border.all(
                      color: _isAligned
                          ? const Color(0xFF10B981)
                          : const Color(0xFFD4AF37),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isAligned
                            ? const Color(0xFF10B981).withOpacity(0.6)
                            : const Color(0xFFD4AF37).withOpacity(0.4),
                        blurRadius: _isAligned ? 24 : 14,
                        spreadRadius: _isAligned ? 4 : 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🕋',
                      style: TextStyle(fontSize: 38),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Floating Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: AppRadius.borderFull,
              border: Border.all(
                color: _isAligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAligned ? Icons.check_circle_rounded : Icons.place_rounded,
                  size: 14,
                  color: _isAligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37),
                ),
                const SizedBox(width: 4),
                Text(
                  _isAligned ? 'الكعبة المشرفة' : 'اتجاه القبلة',
                  style: const TextStyle(
                    fontFamily: AppTypography.uiFont,
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffScreenGuide(Size size, double delta, AppColorsExtension colors) {
    const double hfov = 60.0;
    if (delta.abs() <= (hfov / 2)) {
      return const SizedBox.shrink();
    }

    final bool turnRight = delta > 0;
    final int degreesLeft = delta.abs().toInt();

    return Positioned(
      top: size.height * 0.42,
      left: turnRight ? null : 16,
      right: turnRight ? 16 : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(turnRight ? (_pulseAnimation.value * 6 - 6) : -(_pulseAnimation.value * 6 - 6), 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (turnRight)
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFFD4AF37), size: 22)
                  else
                    const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    turnRight ? 'استدر يميناً $degreesLeft°' : 'استدر يساراً $degreesLeft°',
                    style: const TextStyle(
                      fontFamily: AppTypography.uiFont,
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppColorsExtension colors,
    double distanceKm,
    double qiblaAngle,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'رجوع',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بوصلة الواقع المعزز (AR)',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'حرّك الكاميرا حتى يتطابق الهدف مع الكعبة',
                        style: TextStyle(
                          fontFamily: AppTypography.uiFont,
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isCameraInitialized)
                  IconButton(
                    tooltip: _isFlashOn ? 'إطفاء الفلاش' : 'تشغيل الفلاش',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                    ),
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isFlashOn ? const Color(0xFFFBBF24) : Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Live Stats Badges
            Row(
              children: [
                _buildLiveBadge(
                  icon: Icons.explore_rounded,
                  label: _hasReceivedHeading
                      ? 'البوصلة: ${_currentHeading.toInt()}°'
                      : 'جاري القراءة...',
                ),
                const SizedBox(width: 8),
                _buildLiveBadge(
                  icon: Icons.mosque_rounded,
                  label: 'القبلة: ${qiblaAngle.toInt()}°',
                  highlight: true,
                ),
                const SizedBox(width: 8),
                _buildLiveBadge(
                  icon: Icons.near_me_rounded,
                  label: '${distanceKm.toStringAsFixed(0)} كم',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge({
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFD4AF37).withOpacity(0.2)
              : Colors.black.withOpacity(0.45),
          borderRadius: AppRadius.borderFull,
          border: Border.all(
            color: highlight
                ? const Color(0xFFD4AF37).withOpacity(0.6)
                : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlight ? const Color(0xFFD4AF37) : Colors.white70,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.uiFont,
                  color: highlight ? const Color(0xFFD4AF37) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomGuidance(AppColorsExtension colors, double delta) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.92),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Guidance status banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _isAligned
                    ? const Color(0xFF10B981).withOpacity(0.2)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isAligned
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD4AF37).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAligned ? Icons.verified_rounded : Icons.info_outline_rounded,
                    color: _isAligned ? const Color(0xFF10B981) : const Color(0xFFD4AF37),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAligned
                              ? 'أنت تواجه القبلة المشرفة بدقة! 🕋'
                              : 'حرّك الهاتف ببطء نحو الهدف',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            color: _isAligned ? const Color(0xFF10B981) : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isAligned
                              ? 'تم تثبيت الاتجاه ومحاذاة الكعبة المشرفة في الواقع المعزز.'
                              : delta.abs() <= 20
                                  ? 'أنت قريب جداً! حرّك الهاتف بضع درجات للمطابقة'
                                  : 'اتبع السهم الذهبي على الشاشة للوصول للاتجاه الصحيح',
                          style: const TextStyle(
                            fontFamily: AppTypography.uiFont,
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Switch to classic compass button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text(
                  'العودة للبوصلة الكلاسيكية',
                  style: TextStyle(
                    fontFamily: AppTypography.uiFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
