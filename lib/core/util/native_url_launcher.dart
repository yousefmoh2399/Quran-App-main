import 'package:flutter/services.dart';

class NativeUrlLauncher {
  static const MethodChannel _channel =
      MethodChannel('com.taqarrab.quran/url_launcher');

  /// Launches a URL using the native Android intent mechanism or falls back gracefully.
  static Future<bool> launchUrl(String url, {String? packageName}) async {
    try {
      final res = await _channel.invokeMethod<bool>('launchUrl', {
        'url': url,
        'packageName': packageName,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canLaunchUrl(String url) async {
    try {
      final res = await _channel.invokeMethod<bool>('canLaunchUrl', {
        'url': url,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
