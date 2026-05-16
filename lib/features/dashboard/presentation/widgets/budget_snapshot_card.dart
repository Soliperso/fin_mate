import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';

class BudgetSnapshotCard extends ConsumerWidget {
  const BudgetSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsWithSpendingProvider);

    return budgetsAsync.when(
      data: (budgets) {
        final active = budgets.where((b) => b.isActive).toList();
        if (active.isEmpty) return const SizedBox.shrink();

        final totalBudgeted = active.fold<double>(
          0.0,
          (sum, b) => sum + b.effectiveAmount,
        );
        if (totalBudgeted == 0) return const SizedBox.shrink();

        final totalSpent = active.fold<double>(
          0.0,
          (sum, b) => sum + (b.spent ?? 0.0),
        );
        final progress = (totalSpent / totalBudgeted).clamp(0.0, 1.0);
        final usedPct = (progress * 100).toStringAsFixed(0);

        final isOverBudget = totalSpent > totalBudgeted;
        final isNearLimit = !isOverBudget && progress >= 0.8;

        final statusColor = isOverBudget
            ? AppColors.systemRed
            : isNearLimit
                ? AppColors.systemOrange
                : AppColors.systemGreen;

        final statusLabel = isOverBudget
            ? 'Over budget'
            : isNearLimit
                ? 'Near limit'
                : 'On track';

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final ringBg = isDark
            ? AppColors.tertiarySystemBackgroundDark
            : AppColors.systemGray5;
        final currencyFmt = ref.watch(currencyFormat2Provider);

        return GestureDetector(
          onTap: () => context.go('/budgets'),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.secondarySystemBackgroundDark
                  : AppColors.systemBackground,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                // ── Ring ────────────────────────────────────────────────────
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          backgroundColor: ringBg,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$usedPct%',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: -0.5,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                // ── Info column ──────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Monthly Budget',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryLabel,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        currencyFmt.format(totalBudgeted - totalSpent),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryLabel,
                                  letterSpacing: -0.5,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'of ${currencyFmt.format(totalBudgeted)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryLabel,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm + 2,
                          vertical: AppSizes.xs - 1,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          statusLabel,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => GestureDetector(
        onTap: () => ref.invalidate(budgetsWithSpendingProvider),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 14, color: AppColors.error),
              const SizedBox(width: AppSizes.xs),
              Text(
                'Failed to load · Tap to retry',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
