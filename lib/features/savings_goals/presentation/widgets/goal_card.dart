import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/savings_goal_entity.dart';

class GoalCard extends ConsumerWidget {
  final SavingsGoal goal;

  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final progress = goal.progress;
    final isCompleted = goal.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: InkWell(
        onTap: () {
          context.go('/goals/${goal.id}');
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: (isCompleted ? AppColors.success : AppColors.primaryTeal)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : Icons.savings,
                      color: isCompleted ? AppColors.success : AppColors.primaryTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (goal.category != null)
                          Text(
                            goal.category!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (goal.deadline != null && !isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: goal.isOverdue
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Text(
                        '${goal.daysRemaining} days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: goal.isOverdue ? AppColors.error : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(goal.currentAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isCompleted ? AppColors.success : AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'of ${currencyFormat.format(goal.targetAmount)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.success : AppColors.primaryTeal,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.toStringAsFixed(1)}% complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (!isCompleted)
                    Text(
                      '${currencyFormat.format(goal.remainingAmount)} to go',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
