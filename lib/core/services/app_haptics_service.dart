import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized service providing physical device vibration and premium haptic feedback.
///
/// Features:
/// - Real hardware vibration on Android & iOS (buzzes the phone motor).
/// - Graceful fallback to Flutter's [HapticFeedback] when running in unsupported environments.
/// - Specialized presets for Qiblah alignment, Tasbeeh cycle completion, wird completion, etc.
class AppHaptics {
  AppHaptics._();

  static const MethodChannel _channel = MethodChannel('com.taqarrab.quran/vibration');

  /// Distinct physical vibration when phone aligns precisely with the Qiblah (الكعبة المشرفة).
  ///
  /// Vibrates the physical motor for 380ms + heavy haptic impact.
  static Future<void> qiblaAligned() async {
    try {
      HapticFeedback.heavyImpact();
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _channel.invokeMethod('vibrate', {'duration': 380});
      } else {
        HapticFeedback.vibrate();
      }
    } catch (e) {
      debugPrint('AppHaptics.qiblaAligned error: $e');
      HapticFeedback.vibrate();
    }
  }

  /// Distinct celebratory double-pulse vibration for completing a cycle:
  /// - Completing Tasbeeh round (33 / 100 counts)
  /// - Marking daily wird or commute wird completed
  /// - Finishing all post-prayer azkar
  static Future<void> cycleCompleted() async {
    try {
      HapticFeedback.heavyImpact();
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _channel.invokeMethod('vibratePattern', {
          'pattern': [0, 160, 90, 240],
          'repeat': -1,
        });
      } else {
        HapticFeedback.vibrate();
      }
    } catch (e) {
      debugPrint('AppHaptics.cycleCompleted error: $e');
      HapticFeedback.vibrate();
    }
  }

  /// Solid single vibration pulse (220ms) for item completion:
  /// - Finishing the required count of a single Dhikr
  /// - Marking a prayer as performed
  /// - Saving a bookmark
  static Future<void> itemCompleted() async {
    try {
      HapticFeedback.mediumImpact();
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _channel.invokeMethod('vibrate', {'duration': 220});
      } else {
        HapticFeedback.vibrate();
      }
    } catch (e) {
      debugPrint('AppHaptics.itemCompleted error: $e');
      HapticFeedback.vibrate();
    }
  }

  /// Light tactile tick for each count in Tasbeeh or digital counter.
  static void tap() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Selection click for UI toggles, tabs, chips, bookmarks.
  static void selection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Stop any ongoing vibration immediately.
  static Future<void> cancel() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _channel.invokeMethod('cancel');
      }
    } catch (_) {}
  }
}
