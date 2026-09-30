import 'package:flutter/material.dart';

/// Design system elevation and shadow tokens.
class AppShadows {
  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.04),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> elevated(bool isDark) => [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.45) : Colors.black.withOpacity(0.08),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> modal(bool isDark) => [
        BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.12),
          offset: const Offset(0, -4),
          blurRadius: 24,
          spreadRadius: 0,
        ),
      ];
}
