import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Enhanced empty state card widget with consistent styling across the app
///
/// Features:
/// - Beautiful gradient background with color customization
/// - Animated circular icon with border
/// - Subtle accent line at the bottom
/// - Fully responsive and centered layout
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color backgroundColor;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor.withValues(alpha: 0.08),
              backgroundColor.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.xl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon with background circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: backgroundColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: backgroundColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 48,
                        color: backgroundColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSizes.xl),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),

              // Message
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),

              // Subtle accent line
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
