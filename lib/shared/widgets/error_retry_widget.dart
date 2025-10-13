import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Reusable error widget with retry button
class ErrorRetryWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const ErrorRetryWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Unable to load data. Please try again.',
    required this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
            const SizedBox(height: AppSizes.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
