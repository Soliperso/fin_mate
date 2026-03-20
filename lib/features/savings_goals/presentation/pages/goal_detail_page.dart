import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/add_contribution_bottom_sheet.dart';
import '../widgets/edit_goal_bottom_sheet.dart';
import '../widgets/goal_achievement_dialog.dart';

class GoalDetailPage extends ConsumerWidget {
  final String goalId;

  const GoalDetailPage({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalProvider(goalId));
    final contributionsAsync = ref.watch(goalContributionsProvider(goalId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditGoalSheet(context, ref, goalAsync.value),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
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
            final progress = goal.progress.clamp(0.0, 100.0);
            final remaining = goal.targetAmount - goal.currentAmount;
            final isCompleted = goal.isCompleted;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Card ───────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCompleted
                            ? [AppColors.success, const Color(0xFF27A349)]
                            : [AppColors.brandTeal, AppColors.brandTealLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted ? AppColors.success : AppColors.brandTeal)
                              .withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: AppSizes.iconContainer,
                              height: AppSizes.iconContainer,
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              ),
                              child: Icon(
                                isCompleted ? Icons.check_circle_rounded : Icons.savings_rounded,
                                color: AppColors.white,
                                size: AppSizes.iconMd,
                              ),
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (goal.category != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      goal.category!,
                                      style: TextStyle(
                                        color: AppColors.white.withValues(alpha: 0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '${progress.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (goal.description != null && goal.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            goal.description!,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.lg),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 8,
                            backgroundColor: AppColors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),

                        // Current / Target
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currencyFormat.format(goal.currentAmount),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              currencyFormat.format(goal.targetAmount),
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // ── Info Chips Row ──────────────────────────────────────
                  if (!isCompleted || goal.deadline != null) ...[
                    Row(
                      children: [
                        if (!isCompleted) ...[
                          Expanded(
                            child: _InfoChip(
                              isDark: isDark,
                              icon: Icons.trending_up_rounded,
                              iconColor: AppColors.brandTeal,
                              label: 'Remaining',
                              value: currencyFormat.format(remaining < 0 ? 0 : remaining),
                            ),
                          ),
                          if (goal.deadline != null)
                            const SizedBox(width: AppSizes.sm),
                        ],
                        if (goal.deadline != null)
                          Expanded(
                            child: _InfoChip(
                              isDark: isDark,
                              icon: Icons.calendar_today_rounded,
                              iconColor: _getDaysRemainingColor(goal.deadline!),
                              label: isCompleted
                                  ? 'Deadline'
                                  : _getDaysRemaining(goal.deadline!),
                              value: DateFormat('MMM dd, yyyy').format(goal.deadline!),
                            ),
                          ),
                      ],
                    ),
                    if (goal.monthlySavingsNeeded != null) ...[
                      const SizedBox(height: AppSizes.sm),
                      _InfoChip(
                        isDark: isDark,
                        icon: Icons.savings_outlined,
                        iconColor: AppColors.warning,
                        label: 'Monthly target to hit deadline',
                        value: '${currencyFormat.format(goal.monthlySavingsNeeded!)}/mo',
                      ),
                    ],
                  ],

                  // ── Completed Banner ────────────────────────────────────
                  if (isCompleted) ...[
                    const SizedBox(height: AppSizes.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm + 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.celebration_rounded,
                            color: AppColors.success,
                            size: AppSizes.iconSm,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Goal Achieved!',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.lg),

                  // ── Contributions Section ───────────────────────────────
                  Text(
                    'Contributions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.md),

                  contributionsAsync.when(
                    data: (contributions) {
                      if (contributions.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.xl),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardBackgroundDark
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                            boxShadow: AppColors.cardShadow(isDark),
                          ),
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
                            ],
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardBackgroundDark : AppColors.white,
                          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                          boxShadow: AppColors.cardShadow(isDark),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < contributions.length; i++) ...[
                              Dismissible(
                                key: ValueKey(contributions[i].id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  bool confirmed = false;
                                  await showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Delete Contribution'),
                                      content: const Text('Are you sure you want to delete this contribution?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            confirmed = true;
                                            Navigator.pop(dialogContext);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  );
                                  return confirmed;
                                },
                                onDismissed: (_) async {
                                  final success = await ref
                                      .read(goalOperationsProvider.notifier)
                                      .deleteContribution(contributions[i].id);
                                  if (success) {
                                    ref.invalidate(goalProvider(goalId));
                                    ref.invalidate(goalContributionsProvider(goalId));
                                    ref.invalidate(savingsGoalsProvider);
                                    ref.invalidate(goalsSummaryProvider);
                                    if (context.mounted) {
                                      SuccessSnackbar.show(context, message: 'Contribution deleted');
                                    }
                                  } else if (context.mounted) {
                                    ErrorSnackbar.show(context, message: 'Failed to delete contribution');
                                  }
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: AppSizes.lg),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: AppColors.white),
                                ),
                                child: _ContributionRow(
                                  contribution: contributions[i],
                                  currencyFormat: currencyFormat,
                                  onDelete: () => _showDeleteContributionConfirmation(
                                    context,
                                    ref,
                                    contributions[i].id,
                                  ),
                                ),
                              ),
                              if (i < contributions.length - 1)
                                Divider(
                                  height: 1,
                                  indent: AppSizes.lg + AppSizes.iconContainer,
                                  endIndent: 0,
                                  color: isDark
                                      ? AppColors.separatorDark
                                      : AppColors.separator,
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                    loading: () => Column(
                      children: const [
                        SkeletonCard(height: 72),
                        SizedBox(height: AppSizes.sm),
                        SkeletonCard(height: 72),
                        SizedBox(height: AppSizes.sm),
                        SkeletonCard(height: 72),
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
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeightMd,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddContributionSheet(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: AppColors.white,
                    elevation: 4,
                    shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Add Contribution',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getDaysRemaining(DateTime deadline) {
    final difference = deadline.difference(DateTime.now()).inDays;
    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Due today';
    if (difference == 1) return '1 day left';
    return '$difference days left';
  }

  Color _getDaysRemainingColor(DateTime deadline) {
    final difference = deadline.difference(DateTime.now()).inDays;
    if (difference < 0) return AppColors.error;
    if (difference <= 7) return AppColors.warning;
    return AppColors.success;
  }

  void _showAddContributionSheet(BuildContext context, WidgetRef ref) {
    // Snapshot goal state BEFORE sheet opens for deterministic achievement check
    final goalSnapshot = ref.read(goalProvider(goalId)).value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddContributionBottomSheet(goalId: goalId),
    ).then((result) {
      if (result == null) return;

      ref.invalidate(goalProvider(goalId));
      ref.invalidate(goalContributionsProvider(goalId));
      ref.invalidate(savingsGoalsProvider);
      ref.invalidate(goalsSummaryProvider);

      if (!context.mounted) return;

      // Compute achievement locally — no extra DB call needed.
      // result is the double amount that was contributed.
      final contributedAmount = result is double ? result : null;
      final achieved = goalSnapshot != null &&
          contributedAmount != null &&
          !goalSnapshot.isCompleted &&
          (goalSnapshot.currentAmount + contributedAmount) >= goalSnapshot.targetAmount;

      if (achieved) {
        ref.read(goalOperationsProvider.notifier).markGoalAsCompleted(goalId);
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          builder: (_) => GoalAchievementDialog(goalName: goalSnapshot.name),
        );
      } else {
        SuccessSnackbar.show(context, message: 'Contribution added successfully!');
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text(
          'Are you sure you want to delete this goal? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success =
                  await ref.read(goalOperationsProvider.notifier).deleteGoal(goalId);
              if (success && context.mounted) {
                ref.invalidate(savingsGoalsProvider);
                ref.invalidate(goalsSummaryProvider);
                context.pop();
                SuccessSnackbar.show(context, message: 'Goal deleted successfully');
              } else if (context.mounted) {
                ErrorSnackbar.show(context, message: 'Failed to delete goal');
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Contribution'),
        content: const Text('Are you sure you want to delete this contribution?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(goalOperationsProvider.notifier)
                  .deleteContribution(contributionId);
              if (success && context.mounted) {
                ref.invalidate(goalProvider(goalId));
                ref.invalidate(goalContributionsProvider(goalId));
                ref.invalidate(savingsGoalsProvider);
                ref.invalidate(goalsSummaryProvider);
                SuccessSnackbar.show(context, message: 'Contribution deleted');
              } else if (context.mounted) {
                ErrorSnackbar.show(context, message: 'Failed to delete contribution');
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Small info chip ────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoChip({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: iconColor),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contribution row ───────────────────────────────────────────────────────────

class _ContributionRow extends StatelessWidget {
  final dynamic contribution;
  final NumberFormat currencyFormat;
  final VoidCallback onDelete;

  const _ContributionRow({
    required this.contribution,
    required this.currencyFormat,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.iconContainer,
            height: AppSizes.iconContainer,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.success,
              size: AppSizes.iconSm,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currencyFormat.format(contribution.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(contribution.contributedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (contribution.notes != null && contribution.notes!.isNotEmpty)
                  Text(
                    contribution.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: AppSizes.iconSm,
              color: AppColors.textTertiary,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
