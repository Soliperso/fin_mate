import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_effects.dart';
import 'glass_container.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool enableGlass;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.enableGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 120,
          color: AppColors.textTertiary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: enableGlass
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
  }
}
