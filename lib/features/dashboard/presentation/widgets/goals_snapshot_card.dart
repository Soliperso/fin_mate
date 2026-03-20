import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../savings_goals/domain/entities/savings_goal_entity.dart';
import '../../../savings_goals/presentation/providers/savings_goal_providers.dart';

class GoalsSnapshotCard extends ConsumerWidget {
  const GoalsSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return goalsAsync.when(
      data: (goals) {
        final activeGoals = goals.where((g) => !g.isCompleted).toList();
        if (activeGoals.isEmpty) return const SizedBox.shrink();

        final shown = activeGoals.take(3).toList();

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.md, AppSizes.sm, AppSizes.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.savings_rounded,
                          size: AppSizes.iconSm,
                          color: AppColors.brandTeal,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          'Savings Goals',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (activeGoals.length > 3) ...[
                          const SizedBox(width: AppSizes.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.brandTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text(
                              '+${activeGoals.length - 3} more',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.brandTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.go('/goals'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Goal rows
              for (int i = 0; i < shown.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 0,
                    thickness: 0.5,
                    indent: AppSizes.md,
                    color: isDark ? AppColors.separatorDark : AppColors.separator,
                  ),
                _GoalRow(goal: shown[i]),
              ],
              const SizedBox(height: AppSizes.sm),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final SavingsGoal goal;

  const _GoalRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress / 100;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return InkWell(
      onTap: () => context.go('/goals/${goal.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  '${goal.progress.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.brandTeal.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandTeal),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(goal.currentAmount),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  'of ${currencyFormat.format(goal.targetAmount)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
