import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_effects.dart';
import 'glass_container.dart';

class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool enableGlass;
  final bool animated;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.enableGlass = false,
    this.animated = true,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Icon(
                widget.icon,
                size: 120,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          widget.message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        if (widget.actionLabel != null && widget.onAction != null) ...[
          const SizedBox(height: AppSizes.xl),
          FilledButton.icon(
            onPressed: widget.onAction,
            icon: const Icon(Icons.add),
            label: Text(widget.actionLabel!),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.md,
              ),
            ),
          ),
        ],
      ],
    );

    Widget result = Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: widget.enableGlass
            ? GlassContainer(
                blur: AppEffects.blurMd,
                opacity: AppEffects.opacityMedium,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                padding: const EdgeInsets.all(AppSizes.xl),
                child: content,
              )
            : content,
      ),
    );

    if (widget.animated) {
      result = FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: result,
        ),
      );
    }

    return result;
  }
}
