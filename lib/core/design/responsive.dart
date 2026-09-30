import 'package:flutter/material.dart';

/// Screen size categorization for responsive layouts.
enum ScreenDeviceType {
  compact, // < 600 (phone)
  medium,  // 600 - 840 (tablet / foldable portrait)
  expanded // > 840 (tablet landscape / desktop)
}

/// Helper class for responsive breakpoints and layout adaptations.
class Responsive {
  static const double compactBreakpoint = 600.0;
  static const double mediumBreakpoint = 840.0;
  static const double maxContentWidth = 720.0;

  static ScreenDeviceType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactBreakpoint) {
      return ScreenDeviceType.compact;
    } else if (width <= mediumBreakpoint) {
      return ScreenDeviceType.medium;
    } else {
      return ScreenDeviceType.expanded;
    }
  }

  static bool isCompact(BuildContext context) =>
      deviceType(context) == ScreenDeviceType.compact;

  static bool isMedium(BuildContext context) =>
      deviceType(context) == ScreenDeviceType.medium;

  static bool isExpanded(BuildContext context) =>
      deviceType(context) == ScreenDeviceType.expanded;

  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compactBreakpoint;
}

/// Builder widget that renders different layouts according to screen breakpoints.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? expanded;

  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final type = Responsive.deviceType(context);
    switch (type) {
      case ScreenDeviceType.expanded:
        if (expanded != null) return expanded!(context);
        if (medium != null) return medium!(context);
        return compact(context);
      case ScreenDeviceType.medium:
        if (medium != null) return medium!(context);
        return compact(context);
      case ScreenDeviceType.compact:
        return compact(context);
    }
  }
}

/// Constrains child width on tablets and wide screens to keep readable measure.
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
