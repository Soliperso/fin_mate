import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../domain/entities/savings_goal_entity.dart';

class GoalCard extends ConsumerWidget {
  final SavingsGoal goal;
  final VoidCallback? onContribute;

  const GoalCard({super.key, required this.goal, this.onContribute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final progress = goal.progress;
    final isCompleted = goal.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      shape: goal.isOverdue
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              side: const BorderSide(color: AppColors.error, width: 1.5),
            )
          : null,
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
                      color: (isCompleted
                              ? AppColors.success
                              : AppColors.brandTeal)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(
                      isCompleted
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.flag_fill,
                      color:
                          isCompleted ? AppColors.success : AppColors.brandTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.systemGray
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm),
                              ),
                              child: Text(
                                isCompleted
                                    ? 'Done'
                                    : goal.isOverdue
                                        ? 'Overdue'
                                        : 'Active',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: isCompleted
                                          ? AppColors.success
                                          : goal.isOverdue
                                              ? AppColors.error
                                              : AppColors.systemGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (goal.category != null)
                          Text(
                            goal.category!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(goal.currentAmount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    'of ${currencyFormat.format(goal.targetAmount)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.success : AppColors.brandTeal,
                ),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 8),
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
                    Row(
                      children: [
                        Text(
                          '${currencyFormat.format(goal.remainingAmount)} to go',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        if (onContribute != null) ...[
                          const SizedBox(width: AppSizes.sm),
                          GestureDetector(
                            onTap: onContribute,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.brandTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.add,
                                  color: AppColors.white, size: 16),
                            ),
                          ),
                        ],
                      ],
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
