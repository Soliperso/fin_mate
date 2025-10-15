import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Shimmer loading skeleton widget
class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
    // Safely get theme brightness, fallback to light if no theme found
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : AppColors.lightGray;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Card-shaped loading skeleton
class SkeletonCard extends StatelessWidget {
  final double? height;

  const SkeletonCard({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LoadingSkeleton(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      LoadingSkeleton(
                        width: 150,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (height != null && height! > 100) ...[
              const SizedBox(height: AppSizes.md),
              LoadingSkeleton(
                width: double.infinity,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: AppSizes.sm),
              LoadingSkeleton(
                width: 200,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// List loading skeleton
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double? itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
    );
  }
}

/// Dashboard stat card skeleton
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingSkeleton(
              width: 100,
              height: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSizes.md),
            LoadingSkeleton(
              width: 150,
              height: 24,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSizes.sm),
            LoadingSkeleton(
              width: 80,
              height: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chart loading skeleton
class SkeletonChart extends StatelessWidget {
  final double height;

  const SkeletonChart({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingSkeleton(
              width: 120,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSizes.md),
            LoadingSkeleton(
              width: double.infinity,
              height: height,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
          ],
        ),
      ),
    );
  }
}
