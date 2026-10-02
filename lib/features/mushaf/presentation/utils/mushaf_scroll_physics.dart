import 'package:flutter/material.dart';

/// Calibrated physics for Mushaf reading:
/// Combines [PageScrollPhysics] with custom damping and spring constants
/// to ensure silky smooth page transitions and prevent jarring abrupt stops on mid/low-end devices.
class MushafScrollPhysics extends PageScrollPhysics {
  const MushafScrollPhysics({super.parent});

  @override
  MushafScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return MushafScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 80,
        stiffness: 100,
        damping: 1.1,
      );
}
