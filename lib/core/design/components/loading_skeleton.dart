import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';

/// Shimmer loading skeleton container with smooth pulsing opacity animation.
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  const LoadingSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = const BorderRadius.all(AppRadius.radiusFull);

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final baseColor = colors.divider;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? AppRadius.borderSm,
          ),
        );
      },
    );
  }
}

/// Ready-made skeleton for list tiles (leading icon + two lines of text).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const LoadingSkeleton.circle(size: 40),
          AppSpacing.horizontalMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  width: MediaQuery.sizeOf(context).width * 0.45,
                  height: 14,
                ),
                AppSpacing.verticalSm,
                LoadingSkeleton(
                  width: MediaQuery.sizeOf(context).width * 0.25,
                  height: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
