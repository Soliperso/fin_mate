import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/ai_query_limit_provider.dart';
import '../../../../core/providers/subscription_provider.dart';

/// Compact single-row strip showing AI chat query usage for freemium users.
/// Appears after the first query so users always see their remaining count.
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
          data: (usage) => _CompactStrip(usage: usage),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

enum _UsageState { healthy, warning, blocked }

class _CompactStrip extends StatelessWidget {
  final AIQueryUsage usage;
  const _CompactStrip({required this.usage});

  _UsageState get _state {
    if (usage.hasReachedLimit) return _UsageState.blocked;
    if (usage.queriesRemaining <= 3) return _UsageState.warning;
    return _UsageState.healthy;
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    final Color accentColor = switch (state) {
      _UsageState.healthy => AppColors.brandTeal,
      _UsageState.warning => AppColors.systemOrange,
      _UsageState.blocked => AppColors.error,
    };

    final IconData icon = switch (state) {
      _UsageState.healthy => CupertinoIcons.sparkles,
      _UsageState.warning => CupertinoIcons.exclamationmark_triangle_fill,
      _UsageState.blocked => CupertinoIcons.lock_fill,
    };

    final String labelText = switch (state) {
      _UsageState.healthy => '${usage.queriesRemaining} queries left',
      _UsageState.warning => 'Only ${usage.queriesRemaining} left',
      _UsageState.blocked => 'Limit reached',
    };

    final String ctaText = switch (state) {
      _UsageState.healthy => 'Go Pro',
      _UsageState.warning => 'Upgrade',
      _UsageState.blocked => 'Unlock',
    };

    final double borderOpacity = switch (state) {
      _UsageState.healthy => 0.15,
      _UsageState.warning => 0.25,
      _UsageState.blocked => 0.35,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.xs,
        AppSizes.md,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm + 4,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: accentColor.withValues(alpha: borderOpacity),
        ),
      ),
      child: Row(
        children: [
          // Icon in a soft rounded container
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            labelText,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: state == _UsageState.blocked
                      ? AppColors.error
                      : AppColors.textPrimary,
                  letterSpacing: -0.1,
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
          // Pill CTA button
          GestureDetector(
            onTap: () => context.push('/paywall'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(
                  alpha: state == _UsageState.blocked ? 0.15 : 0.10,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                ctaText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
