import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Staggered Entrance Animation
/// Gently fades and slides in list items or components with an index-based delay.
/// Engineered to be 100% non-blocking for user interaction.
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final double slideOffset;
  final Curve curve;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.slideOffset = 18.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final delayFactor = (widget.index * 0.06).clamp(0.0, 0.4);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayFactor, 1.0, curve: widget.curve),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer Skeleton Placeholder
/// Produces a continuous, gentle metallic shimmer effect for loading states.
class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  const ShimmerSkeleton.circular({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = size / 2;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  (_controller.value - 0.3).clamp(0.0, 1.0),
                  _controller.value.clamp(0.0, 1.0),
                  (_controller.value + 0.3).clamp(0.0, 1.0),
                ],
                colors: const [
                  AppColors.charcoalSurfaceVariant,
                  AppColors.charcoalSurfaceElevated,
                  AppColors.charcoalSurfaceVariant,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Card Skeleton
/// Reusable card skeleton structure for discovery feeds and team rosters.
class CardSkeleton extends StatelessWidget {
  final double height;

  const CardSkeleton({super.key, this.height = 140.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoalSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.charcoalBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShimmerSkeleton.circular(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerSkeleton(width: 140, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerSkeleton(width: 90, height: 10, borderRadius: 4),
                  ],
                ),
              ),
              const ShimmerSkeleton(width: 60, height: 22, borderRadius: 12),
            ],
          ),
          const Spacer(),
          const ShimmerSkeleton(width: double.infinity, height: 12, borderRadius: 4),
          const SizedBox(height: 8),
          const ShimmerSkeleton(width: 220, height: 12, borderRadius: 4),
          const Spacer(),
          Row(
            children: const [
              ShimmerSkeleton(width: 50, height: 20, borderRadius: 6),
              SizedBox(width: 8),
              ShimmerSkeleton(width: 65, height: 20, borderRadius: 6),
              SizedBox(width: 8),
              ShimmerSkeleton(width: 55, height: 20, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }
}
