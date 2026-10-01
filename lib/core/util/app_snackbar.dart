import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Safe snackbar utility that never crashes with "No Overlay widget found".
/// Uses [ScaffoldMessenger] if available, falling back to Get.snackbar safely.
class AppSnackbar {
  static void show(
    String title,
    String message, {
    BuildContext? context,
    Color backgroundColor = const Color(0xFF1B4D3E),
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
  }) {
    final ctx = context ?? Get.context;
    if (ctx != null) {
      try {
        final messenger = ScaffoldMessenger.maybeOf(ctx);
        if (messenger != null) {
          messenger.removeCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ],
              ),
              backgroundColor: backgroundColor,
              behavior: SnackBarBehavior.floating,
              duration: duration,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
      } catch (_) {}
    }

    // Fallback: try Get.rawSnackbar only if overlay exists
    try {
      if (Get.overlayContext != null) {
        Get.rawSnackbar(
          title: title.isNotEmpty ? title : null,
          message: message,
          backgroundColor: backgroundColor,
          snackPosition: SnackPosition.BOTTOM,
          duration: duration,
          margin: const EdgeInsets.all(16),
          borderRadius: 10,
        );
      }
    } catch (_) {}
  }
}
