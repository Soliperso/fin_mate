import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/add_contribution_bottom_sheet.dart';
import '../widgets/edit_goal_bottom_sheet.dart';

class GoalDetailPage extends ConsumerWidget {
  final String goalId;

  const GoalDetailPage({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalProvider(goalId));
    final contributionsAsync = ref.watch(goalContributionsProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditGoalSheet(context, ref, goalAsync.value),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(goalProvider(goalId));
          ref.invalidate(goalContributionsProvider(goalId));
        },
        child: goalAsync.when(
          data: (goal) {
            final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
            final progress = goal.progress;
            final remaining = goal.targetAmount - goal.currentAmount;
            final isCompleted = goal.isCompleted;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal Overview Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSizes.md),
                                decoration: BoxDecoration(
                                  color: (isCompleted ? AppColors.success : AppColors.primaryTeal)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                ),
                                child: Icon(
                                  isCompleted ? Icons.check_circle : Icons.savings,
                                  color: isCompleted ? AppColors.success : AppColors.primaryTeal,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.name,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                    ),
                                    if (goal.category != null) ...[
                                      const SizedBox(height: AppSizes.xs),
                                      Text(
                                        goal.category!,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (goal.description != null && goal.description!.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.md),
                            Text(
                              goal.description!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                          const SizedBox(height: AppSizes.lg),

                          // Progress Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${progress.toStringAsFixed(1)}%',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.primaryTeal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  minHeight: 12,
                                  backgroundColor: AppColors.lightGray,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted ? AppColors.success : AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                      Text(
                                        currencyFormat.format(goal.currentAmount),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Target',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                      Text(
                                        currencyFormat.format(goal.targetAmount),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (!isCompleted) ...[
                                const SizedBox(height: AppSizes.sm),
                                Container(
                                  padding: const EdgeInsets.all(AppSizes.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGray,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.trending_up,
                                        size: AppSizes.iconSm,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSizes.xs),
                                      Text(
                                        '${currencyFormat.format(remaining)} to go',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Deadline Section
                          if (goal.deadline != null) ...[
                            const SizedBox(height: AppSizes.lg),
                            Container(
                              padding: const EdgeInsets.all(AppSizes.md),
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: AppSizes.iconSm,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Target Date',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(goal.deadline!),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isCompleted) ...[
                                    Text(
                                      _getDaysRemaining(goal.deadline!),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: _getDaysRemainingColor(goal.deadline!),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          // Completed Badge
                          if (isCompleted) ...[
                            const SizedBox(height: AppSizes.lg),
                            Container(
                              padding: const EdgeInsets.all(AppSizes.md),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.celebration,
                                    color: AppColors.success,
                                    size: AppSizes.iconMd,
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  Text(
                                    'Goal Completed! 🎉',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Contributions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contributions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (!isCompleted)
                        TextButton.icon(
                          onPressed: () => _showAddContributionSheet(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),

                  contributionsAsync.when(
                    data: (contributions) {
                      if (contributions.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.xl),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 48,
                                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: AppSizes.md),
                                  Text(
                                    'No contributions yet',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  if (!isCompleted) ...[
                                    const SizedBox(height: AppSizes.sm),
                                    TextButton(
                                      onPressed: () => _showAddContributionSheet(context, ref),
                                      child: const Text('Add your first contribution'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: contributions.map((contribution) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.sm),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(AppSizes.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                currencyFormat.format(contribution.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(contribution.contributedAt),
                                  ),
                                  if (contribution.notes != null && contribution.notes!.isNotEmpty)
                                    Text(
                                      contribution.notes!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _showDeleteContributionConfirmation(
                                  context,
                                  ref,
                                  contribution.id,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => Column(
                      children: [
                        const SkeletonCard(height: 80),
                        const SizedBox(height: AppSizes.sm),
                        const SkeletonCard(height: 80),
                        const SizedBox(height: AppSizes.sm),
                        const SkeletonCard(height: 80),
                      ],
                    ),
                    error: (error, stack) => ErrorRetryWidget(
                      title: 'Failed to load contributions',
                      message: 'Unable to fetch contribution history.',
                      onRetry: () => ref.invalidate(goalContributionsProvider(goalId)),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorRetryWidget(
            title: 'Failed to load goal',
            message: 'Unable to fetch goal details. Please try again.',
            onRetry: () => ref.invalidate(goalProvider(goalId)),
          ),
        ),
      ),
      floatingActionButton: goalAsync.value?.isCompleted == false
          ? FloatingActionButton.extended(
              onPressed: () => _showAddContributionSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Contribution'),
            )
          : null,
    );
  }

  String _getDaysRemaining(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return '1 day left';
    } else {
      return '$difference days left';
    }
  }

  Color _getDaysRemainingColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;

    if (difference < 0) {
      return AppColors.error;
    } else if (difference <= 7) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  void _showAddContributionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddContributionBottomSheet(goalId: goalId),
    ).then((added) {
      if (added == true) {
        ref.invalidate(goalProvider(goalId));
        ref.invalidate(goalContributionsProvider(goalId));
        ref.invalidate(savingsGoalsProvider);
        ref.invalidate(goalsSummaryProvider);
      }
    });
  }

  void _showEditGoalSheet(BuildContext context, WidgetRef ref, goal) {
    if (goal == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditGoalBottomSheet(goal: goal),
    ).then((updated) {
      if (updated == true) {
        ref.invalidate(goalProvider(goalId));
        ref.invalidate(savingsGoalsProvider);
        ref.invalidate(goalsSummaryProvider);
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text(
          'Are you sure you want to delete this goal? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(goalOperationsProvider.notifier);
              final success = await notifier.deleteGoal(goalId);

              if (success && context.mounted) {
                ref.invalidate(savingsGoalsProvider);
                ref.invalidate(goalsSummaryProvider);
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goal deleted successfully')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete goal')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteContributionConfirmation(
    BuildContext context,
    WidgetRef ref,
    String contributionId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contribution'),
        content: const Text('Are you sure you want to delete this contribution?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(goalOperationsProvider.notifier);
              final success = await notifier.deleteContribution(contributionId);

              if (success && context.mounted) {
                ref.invalidate(goalProvider(goalId));
                ref.invalidate(goalContributionsProvider(goalId));
                ref.invalidate(savingsGoalsProvider);
                ref.invalidate(goalsSummaryProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contribution deleted')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete contribution')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
