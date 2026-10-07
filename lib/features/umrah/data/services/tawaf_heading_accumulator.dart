import 'dart:math' as math;

/// Accumulator that filters and tracks heading changes to estimate full circumambulation (360° rotation) around the Kaaba.
///
/// Principles:
/// - Purely orientation-based (no GPS or location coordinates).
/// - Low-pass filter to reject magnetic noise and high-frequency jitter.
/// - Requires consistent rotational progression (counter-clockwise around Kaaba).
/// - Triggers a candidate callback; MUST require manual user confirmation.
class TawafHeadingAccumulator {
  final double thresholdDegrees;
  final double minJitterDegrees;
  final double alpha; // Exponential smoothing factor

  double? _lastSmoothedHeading;
  double _accumulatedRotation = 0.0;
  bool _isCandidatePending = false;

  final void Function()? onRotationCandidate;

  TawafHeadingAccumulator({
    this.thresholdDegrees = 330.0,
    this.minJitterDegrees = 1.5,
    this.alpha = 0.35,
    this.onRotationCandidate,
  });

  double get accumulatedRotation => _accumulatedRotation;
  bool get isCandidatePending => _isCandidatePending;

  /// Feeds a new raw compass heading (0° to 360°).
  void addHeading(double rawHeading) {
    if (rawHeading.isNaN || rawHeading.isInfinite) return;

    // Normalize to [0, 360)
    final normalized = (rawHeading % 360.0 + 360.0) % 360.0;

    if (_lastSmoothedHeading == null) {
      _lastSmoothedHeading = normalized;
      return;
    }

    // Shortest angular difference between new and last heading
    double delta = normalized - _lastSmoothedHeading!;
    while (delta > 180.0) {
      delta -= 360.0;
    }
    while (delta < -180.0) {
      delta += 360.0;
    }

    // Ignore tiny sensor jitter
    if (delta.abs() < minJitterDegrees) return;

    // Apply low-pass exponential smoothing
    final smoothedDelta = delta * alpha;
    _lastSmoothedHeading = (_lastSmoothedHeading! + smoothedDelta) % 360.0;

    // Tawaf circumambulation is counter-clockwise (bearing decreases or increases cyclically)
    // We accumulate absolute angular displacement towards the threshold
    _accumulatedRotation += smoothedDelta.abs();

    if (_accumulatedRotation >= thresholdDegrees && !_isCandidatePending) {
      _isCandidatePending = true;
      onRotationCandidate?.call();
    }
  }

  /// Clears pending state after user either accepts or rejects the lap.
  void acknowledgeCandidate() {
    _accumulatedRotation = 0.0;
    _isCandidatePending = false;
  }

  /// Full reset (e.g. new lap or resetting counter).
  void reset() {
    _lastSmoothedHeading = null;
    _accumulatedRotation = 0.0;
    _isCandidatePending = false;
  }

  /// Progress fraction towards 360° [0.0 .. 1.0]
  double get rotationProgress =>
      math.min(1.0, math.max(0.0, _accumulatedRotation / thresholdDegrees));
}
