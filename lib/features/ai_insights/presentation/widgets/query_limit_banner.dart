import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/ai_query_limit_provider.dart';
import '../../../../core/providers/subscription_provider.dart';

/// Compact single-row strip showing AI chat query usage for freemium users.
/// Appears when the user has used 7 or more of their 10 free queries.
/// Disappears entirely for premium users.
class QueryLimitBanner extends ConsumerWidget {
  const QueryLimitBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final queryUsageAsync = ref.watch(aiQueryUsageProvider);

    return isPremiumAsync.when(
      data: (isPremium) {
        if (isPremium) return const SizedBox.shrink();

        return queryUsageAsync.when(
          data: (usage) {
            // Only show when 7+ queries used (warning zone + limit)
            if (usage.queriesUsed < 7) return const SizedBox.shrink();
            return _CompactStrip(usage: usage);
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CompactStrip extends StatelessWidget {
  final AIQueryUsage usage;
  const _CompactStrip({required this.usage});

  @override
  Widget build(BuildContext context) {
    final hasReachedLimit = usage.hasReachedLimit;
    final accentColor = hasReachedLimit ? AppColors.error : AppColors.brandTeal;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.xs,
        AppSizes.md,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: accentColor.withValues(alpha: hasReachedLimit ? 0.25 : 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasReachedLimit ? CupertinoIcons.nosign : CupertinoIcons.sparkles,
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            '${usage.queriesUsed}/10 free queries',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasReachedLimit
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: usage.usagePercentage,
                minHeight: 4,
                backgroundColor: AppColors.systemGray5,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: () => context.push('/paywall'),
            child: Text(
              hasReachedLimit ? 'Upgrade' : 'Go Premium',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.brandTeal,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
