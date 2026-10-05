import 'package:flutter/material.dart';

/// Computes the exact [Rect] bounds of the widget associated with [context]
/// for iPad popover anchoring in [Share.share] and [Share.shareXFiles].
///
/// Falls back to the center of the screen if the widget render box is not yet laid out.
Rect? getSharePositionOrigin(BuildContext context) {
  try {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize && renderBox.size.width > 0 && renderBox.size.height > 0) {
      final origin = renderBox.localToGlobal(Offset.zero);
      return origin & renderBox.size;
    }
  } catch (_) {}

  try {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery != null && mediaQuery.size.width > 0 && mediaQuery.size.height > 0) {
      return Rect.fromCenter(
        center: Offset(mediaQuery.size.width / 2, mediaQuery.size.height / 2),
        width: 2,
        height: 2,
      );
    }
  } catch (_) {}

  return null;
}
