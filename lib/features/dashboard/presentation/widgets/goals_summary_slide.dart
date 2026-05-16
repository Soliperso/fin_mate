import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../savings_goals/presentation/providers/savings_goal_providers.dart';

class GoalsSummarySlide extends ConsumerWidget {
  const GoalsSummarySlide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return goalsAsync.when(
      data: (goals) {
        final active = goals.where((g) => !g.isCompleted).toList();
        final activeGoals = active.length;
        final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);

        if (activeGoals == 0) {
          return GestureDetector(
            onTap: () => context.push('/goals'),
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.flag_circle,
                      size: 36,
                      color: AppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Savings Goals',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryLabel,
                                  ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Set a goal, start saving',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Tap to create your first goal',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.secondaryLabel,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: AppSizes.iconSm,
                    color: AppColors.secondaryLabel,
                  ),
                ],
              ),
            ),
          );
        }

        final completedGoals = goals.where((g) => g.isCompleted).length;
        final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
        final overallProgress =
            totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

        final progressPct = (overallProgress * 100).toStringAsFixed(0);
        final currencyFmt = ref.watch(currencyFormat2Provider);

        final ringBg = isDark
            ? AppColors.tertiarySystemBackgroundDark
            : AppColors.systemGray5;

        return GestureDetector(
          onTap: () => context.push('/goals'),
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
                // ── Progress ring ────────────────────────────────────────────
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
                          value: overallProgress.clamp(0.0, 1.0),
                          strokeWidth: 7,
                          backgroundColor: ringBg,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.brandTeal,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$progressPct%',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandTeal,
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
                        'Savings Goals',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryLabel,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        currencyFmt.format(totalSaved),
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
                        'of ${currencyFmt.format(totalTarget)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryLabel,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm + 2,
                              vertical: AppSizes.xs - 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.brandTeal.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text(
                              '$activeGoals active',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brandTeal,
                                  ),
                            ),
                          ),
                          if (completedGoals > 0) ...[
                            const SizedBox(width: AppSizes.xs),
                            const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              size: 14,
                              color: AppColors.systemGreen,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$completedGoals done',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.systemGreen),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Chevron ──────────────────────────────────────────────────
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: AppSizes.iconSm,
                  color: AppColors.secondaryLabel,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => GestureDetector(
        onTap: () => ref.invalidate(savingsGoalsProvider),
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
