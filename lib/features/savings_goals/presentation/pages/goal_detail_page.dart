import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/instant_fab_animator.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../../shared/widgets/empty_state_card.dart';
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
        title: Text('goalDetail.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
        actions: [
          CircularIconButton(
            icon: CupertinoIcons.pencil,
            onTap: () => _showEditGoalSheet(context, ref, goalAsync.value),
          ),
          const SizedBox(width: AppSizes.xs),
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.trash,
              onTap: () => _showDeleteConfirmation(context, ref),
            ),
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
            final currencyFormat = ref.watch(currencyFormat2Provider);
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
                                isCompleted ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.money_dollar,
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
                              icon: CupertinoIcons.arrow_up_right,
                              iconColor: AppColors.brandTeal,
                              label: 'goalDetail.remaining'.tr(),
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
                              icon: CupertinoIcons.calendar,
                              iconColor: _getDaysRemainingColor(goal.deadline!),
                              label: isCompleted
                                  ? 'goalDetail.deadline'.tr()
                                  : _getDaysRemaining(goal.deadline!),
                              value: DateFormat('MMM dd, yyyy', context.locale.languageCode).format(goal.deadline!),
                            ),
                          ),
                      ],
                    ),
                    if (goal.monthlySavingsNeeded != null) ...[
                      const SizedBox(height: AppSizes.sm),
                      _InfoChip(
                        isDark: isDark,
                        icon: CupertinoIcons.money_dollar,
                        iconColor: AppColors.warning,
                        label: 'goalDetail.monthlyTarget'.tr(),
                        value: '${currencyFormat.format(goal.monthlySavingsNeeded!)}/${'debt.moAbbr'.tr()}',
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
                            CupertinoIcons.star_fill,
                            color: AppColors.success,
                            size: AppSizes.iconSm,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'goalDetail.achieved'.tr(),
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
                    'goalDetail.contributions'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.md),

                  contributionsAsync.when(
                    data: (contributions) {
                      if (contributions.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EmptyStateCard(
                                icon: CupertinoIcons.plus_circle,
                                title: 'goalDetail.noContributions'.tr(),
                                message: 'goalDetail.noContributionsMessage'.tr(),
                                backgroundColor: AppColors.brandTeal,
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardBackgroundDark : AppColors.white,
                          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
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
                                      title: Text('goalDetail.deleteContribution'.tr()),
                                      content: Text('goalDetail.deleteMessage'.tr()),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext),
                                          child: Text('common.cancel'.tr()),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            confirmed = true;
                                            Navigator.pop(dialogContext);
                                          },
                                          child: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
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
                                      SuccessSnackbar.show(context, message: 'goalDetail.contributionDeleted'.tr());
                                    }
                                  } else if (context.mounted) {
                                    ErrorSnackbar.show(context, message: 'goalDetail.failedToDelete'.tr());
                                  }
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: AppSizes.lg),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                                  ),
                                  child: const Icon(CupertinoIcons.trash, color: AppColors.white),
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
                                  color: Theme.of(context).dividerColor,
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
                      title: 'goalDetail.failedToLoadContributions'.tr(),
                      message: 'goalDetail.failedToLoadContributionsMessage'.tr(),
                      onRetry: () => ref.invalidate(goalContributionsProvider(goalId)),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorRetryWidget(
            title: 'goalDetail.failedToLoadGoal'.tr(),
            message: 'goalDetail.failedToLoadGoalMessage'.tr(),
            onRetry: () => ref.invalidate(goalProvider(goalId)),
          ),
        ),
      ),
      floatingActionButtonAnimator: const InstantFabAnimator(),
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
                  icon: const Icon(CupertinoIcons.add, size: 20),
                  label: Text(
                    'goalDetail.addContribution'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getDaysRemaining(DateTime deadline) {
    final difference = deadline.difference(DateTime.now()).inDays;
    if (difference < 0) return 'goalDetail.overdue'.tr();
    if (difference == 0) return 'goalDetail.dueToday'.tr();
    if (difference == 1) return 'goalDetail.oneDayLeft'.tr();
    return 'goalDetail.daysLeft'.tr(namedArgs: {'days': '$difference'});
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

    GlassBottomSheet.show(
      context: context,
      child: AddContributionBottomSheet(goalId: goalId),
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
        SuccessSnackbar.show(context, message: 'goalDetail.contributionAdded'.tr());
      }
    });
  }

  void _showEditGoalSheet(BuildContext context, WidgetRef ref, goal) {
    if (goal == null) return;
    GlassBottomSheet.show(
      context: context,
      child: EditGoalBottomSheet(goal: goal),
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
        title: Text('goalDetail.deleteGoalTitle'.tr()),
        content: Text('goalDetail.deleteGoalMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
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
                SuccessSnackbar.show(context, message: 'goalDetail.goalDeleted'.tr());
              } else if (context.mounted) {
                ErrorSnackbar.show(context, message: 'goalDetail.failedToDeleteGoal'.tr());
              }
            },
            child: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
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
        title: Text('goalDetail.deleteContribution'.tr()),
        content: Text('goalDetail.deleteMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
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
                SuccessSnackbar.show(context, message: 'goalDetail.contributionDeleted'.tr());
              } else if (context.mounted) {
                ErrorSnackbar.show(context, message: 'goalDetail.failedToDelete'.tr());
              }
            },
            child: Text('common.delete'.tr(), style: const TextStyle(color: AppColors.error)),
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
                  style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                        color: AppColors.textSecondary,
                        inherit: true,
                      ),
                ),
                Text(
                  value,
                  style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.w600,
                        inherit: true,
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
              CupertinoIcons.add,
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
                  DateFormat('MMM dd, yyyy', context.locale.languageCode).format(contribution.contributedAt),
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
          CircularIconButton(
            icon: CupertinoIcons.trash,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
