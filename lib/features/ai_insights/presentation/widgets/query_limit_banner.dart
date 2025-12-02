import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/ai_query_limit_provider.dart';
import '../../../../core/providers/subscription_provider.dart';
import '../../../../shared/widgets/glass_container.dart';

/// Banner showing AI query usage limit for freemium users
class QueryLimitBanner extends ConsumerWidget {
  const QueryLimitBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumAsync = ref.watch(stripePremiumProvider);
    final queryUsageAsync = ref.watch(aiQueryUsageProvider);

    return isPremiumAsync.when(
      data: (isPremium) {
        if (isPremium) {
          // Premium users see unlimited banner
          return _PremiumBanner();
        }

        // Freemium users see query limit
        return queryUsageAsync.when(
          data: (usage) => _FreemiumBanner(usage: usage),
          loading: () => const _LoadingBanner(),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
      loading: () => const _LoadingBanner(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      enableGlass: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Unlimited AI queries',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _FreemiumBanner extends ConsumerWidget {
  final AIQueryUsage usage;

  const _FreemiumBanner({required this.usage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.read(aiQueryOperationsProvider);
    final daysUntilReset = operations.getDaysUntilReset();
    final hasReachedLimit = usage.hasReachedLimit;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSizes.lg),
      enableGlass: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasReachedLimit
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasReachedLimit
                      ? Icons.block
                      : Icons.chat_bubble_outline,
                  color: hasReachedLimit
                      ? AppColors.error
                      : AppColors.primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasReachedLimit
                          ? 'Query Limit Reached'
                          : 'AI Queries',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${usage.queriesUsed} of 10 used this month • Resets in $daysUntilReset days',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasReachedLimit)
                TextButton(
                  onPressed: () => context.push('/pricing'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Upgrade',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usage.usagePercentage,
              backgroundColor: AppColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                hasReachedLimit ? AppColors.error : AppColors.primaryTeal,
              ),
              minHeight: 6,
            ),
          ),
          if (hasReachedLimit) ...[
            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Upgrade to Premium for unlimited AI queries',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      enableGlass: false,
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSizes.md),
          Text(
            'Loading query limit...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
