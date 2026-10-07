import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app_android/features/umrah/data/services/tawaf_heading_accumulator.dart';

void main() {
  group('TawafHeadingAccumulator Unit Tests', () {
    test('Simulated 360 rotation triggers candidate callback', () {
      bool candidateTriggered = false;
      final accumulator = TawafHeadingAccumulator(
        thresholdDegrees: 330.0,
        minJitterDegrees: 1.0,
        alpha: 1.0, // test with instantaneous integration for deterministic check
        onRotationCandidate: () {
          candidateTriggered = true;
        },
      );

      // Simulate step increments: 0 -> 90 -> 180 -> 270 -> 360 (0)
      accumulator.addHeading(0.0);
      accumulator.addHeading(90.0);
      expect(accumulator.accumulatedRotation, equals(90.0));
      expect(candidateTriggered, isFalse);

      accumulator.addHeading(180.0);
      expect(accumulator.accumulatedRotation, equals(180.0));
      expect(candidateTriggered, isFalse);

      accumulator.addHeading(270.0);
      expect(accumulator.accumulatedRotation, equals(270.0));
      expect(candidateTriggered, isFalse);

      // Final quarter turn: 270 to 350 -> +80 => 350.0 >= 330.0
      accumulator.addHeading(350.0);
      expect(accumulator.accumulatedRotation, equals(350.0));
      expect(candidateTriggered, isTrue);
      expect(accumulator.isCandidatePending, isTrue);
    });

    test('Small sensor jitter below minJitterDegrees is rejected', () {
      final accumulator = TawafHeadingAccumulator(
        minJitterDegrees: 2.0,
        alpha: 1.0,
      );

      accumulator.addHeading(100.0);
      // Small jitter of 0.8 degrees
      accumulator.addHeading(100.8);
      expect(accumulator.accumulatedRotation, equals(0.0));

      // Small jitter of 1.4 degrees
      accumulator.addHeading(101.4);
      expect(accumulator.accumulatedRotation, equals(0.0));

      // Movement greater than jitter threshold (e.g. 5 degrees)
      accumulator.addHeading(105.0);
      expect(accumulator.accumulatedRotation, isPositive);
    });

    test('acknowledgeCandidate clears rotation and pending flag', () {
      bool callbackFired = false;
      final accumulator = TawafHeadingAccumulator(
        thresholdDegrees: 100.0,
        alpha: 1.0,
        minJitterDegrees: 1.0,
        onRotationCandidate: () => callbackFired = true,
      );

      accumulator.addHeading(0.0);
      accumulator.addHeading(110.0);
      expect(callbackFired, isTrue);
      expect(accumulator.isCandidatePending, isTrue);

      accumulator.acknowledgeCandidate();
      expect(accumulator.isCandidatePending, isFalse);
      expect(accumulator.accumulatedRotation, equals(0.0));
    });

    test('reset resets all state completely', () {
      final accumulator = TawafHeadingAccumulator(alpha: 1.0);
      accumulator.addHeading(0.0);
      accumulator.addHeading(50.0);
      expect(accumulator.accumulatedRotation, equals(50.0));

      accumulator.reset();
      expect(accumulator.accumulatedRotation, equals(0.0));
      expect(accumulator.isCandidatePending, isFalse);
    });
  });
}
