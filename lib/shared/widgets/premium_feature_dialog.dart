import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Dialog that prompts user to upgrade to premium for a feature
class PremiumFeatureDialog extends StatelessWidget {
  final String featureName;
  final List<String> benefits;
  final VoidCallback? onUpgradePressed;

  const PremiumFeatureDialog({
    super.key,
    required this.featureName,
    this.benefits = const [
      'Scan and organize receipts',
      'AI-powered expense insights',
      'Unlimited transaction categories',
    ],
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium icon header
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryTeal.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Title
            Text(
              'Unlock $featureName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),

            // Subtitle
            Text(
              'Available with Premium',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.md),

            // Benefits list
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Column(
                children: benefits
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key < benefits.length - 1
                              ? AppSizes.sm
                              : 0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                              color: AppColors.primaryTeal,
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Upgrade button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUpgradePressed ??
                    () {
                      Navigator.pop(context);
                      context.push('/pricing');
                    },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.md,
                  ),
                ),
                child: const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // Maybe later button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show premium feature dialog
  static Future<void> show(
    BuildContext context, {
    required String featureName,
    List<String>? benefits,
    VoidCallback? onUpgradePressed,
  }) {
    return showDialog(
      context: context,
      builder: (context) => PremiumFeatureDialog(
        featureName: featureName,
        benefits: benefits ?? const [],
        onUpgradePressed: onUpgradePressed,
      ),
    );
  }
}
