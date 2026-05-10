import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/instant_fab_animator.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/add_contribution_bottom_sheet.dart';
import '../widgets/create_goal_bottom_sheet.dart';
import '../widgets/goal_achievement_dialog.dart';
import '../widgets/goal_card.dart';
import '../widgets/goals_summary_card.dart';

class SavingsGoalsPage extends ConsumerWidget {
  const SavingsGoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final summaryAsync = ref.watch(goalsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('savings.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.info_circle,
              onTap: () => _showInfoDialog(context),
            ),
          ),
        ],
      ),
      floatingActionButtonAnimator: const InstantFabAnimator(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: goalsAsync.value?.isNotEmpty == true
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeightMd,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateGoalSheet(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.add, size: 20),
                  label: Text(
                    'savings.newGoal'.tr(),
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savingsGoalsProvider);
          ref.invalidate(goalsSummaryProvider);
        },
        child: goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmptyStateCard(
                      icon: CupertinoIcons.money_dollar,
                      title: 'savings.noGoals'.tr(),
                      message: 'savings.noGoalsMessage'.tr(),
                      backgroundColor: AppColors.brandTeal,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeightMd,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCreateGoalSheet(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandTeal,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor:
                              AppColors.brandTeal.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.add, size: 20),
                        label: Text(
                          'savings.newGoal'.tr(),
                          style:
                              Theme.of(context).textTheme.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.md, AppSizes.md, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  summaryAsync.when(
                    data: (summary) => GoalsSummaryCard(summary: summary),
                    loading: () => const SkeletonCard(height: 150),
                    error: (error, stack) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Active Goals
                  Text(
                    'savings.activeGoals'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.md),
                  ...goals.where((g) => !g.isCompleted).map((goal) => GoalCard(
                        goal: goal,
                        onContribute: () =>
                            _showContributeSheet(context, ref, goal),
                      )),

                  // Completed Goals
                  if (goals.any((g) => g.isCompleted)) ...[
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'savings.completedGoals'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...goals
                        .where((g) => g.isCompleted)
                        .map((goal) => GoalCard(goal: goal)),
                  ],
                ],
              ),
            );
          },
          loading: () => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              children: [
                const SkeletonCard(height: 150),
                const SizedBox(height: AppSizes.lg),
                const SkeletonCard(height: 180),
                const SkeletonCard(height: 180),
                const SkeletonCard(height: 180),
              ],
            ),
          ),
          error: (error, stack) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(savingsGoalsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: ErrorRetryWidget(
                  title: 'savings.failedToLoad'.tr(),
                  message: 'savings.failedMessage'.tr(),
                  onRetry: () => ref.invalidate(savingsGoalsProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showContributeSheet(
      BuildContext context, WidgetRef ref, SavingsGoal goal) {
    GlassBottomSheet.show(
      context: context,
      child: AddContributionBottomSheet(goalId: goal.id),
    ).then((result) {
      if (result == null) return;

      ref.invalidate(savingsGoalsProvider);
      ref.invalidate(goalsSummaryProvider);

      if (!context.mounted) return;

      final contributedAmount = result is double ? result : null;
      final achieved = contributedAmount != null &&
          !goal.isCompleted &&
          (goal.currentAmount + contributedAmount) >= goal.targetAmount;

      if (achieved) {
        ref.read(goalOperationsProvider.notifier).markGoalAsCompleted(goal.id);
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          builder: (_) => GoalAchievementDialog(goalName: goal.name),
        );
      }
    });
  }

  void _showCreateGoalSheet(BuildContext context, WidgetRef ref) {
    GlassBottomSheet.show(
      context: context,
      child: const CreateGoalBottomSheet(),
    ).then((created) {
      if (created == true) {
        ref.invalidate(savingsGoalsProvider);
        ref.invalidate(goalsSummaryProvider);
      }
    });
  }

  void _showInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget stepRow({
      required IconData icon,
      required Color color,
      required String text,
    }) {
      final label = text.startsWith('• ') ? text.substring(2) : text;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppColors.labelDark : AppColors.label,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xxl,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardBackgroundDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gradient header ────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.xl,
                    AppSizes.lg,
                    AppSizes.lg,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.brandTeal, AppColors.brandTealLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.money_dollar,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'savings.aboutTitle'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        'savings.aboutContent'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // ── Feature steps ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md,
                    AppSizes.md,
                    AppSizes.md,
                    AppSizes.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'savings.featuresLabel'.tr(),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.secondaryLabelDark
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      stepRow(
                        icon: CupertinoIcons.flag_fill,
                        color: AppColors.systemBlue,
                        text: 'savings.feature1'.tr(),
                      ),
                      stepRow(
                        icon: CupertinoIcons.calendar,
                        color: AppColors.systemOrange,
                        text: 'savings.feature2'.tr(),
                      ),
                      stepRow(
                        icon: CupertinoIcons.chart_bar_alt_fill,
                        color: AppColors.brandTeal,
                        text: 'savings.feature3'.tr(),
                      ),
                      stepRow(
                        icon: CupertinoIcons.tag_fill,
                        color: AppColors.systemPurple,
                        text: 'savings.feature4'.tr(),
                      ),
                      stepRow(
                        icon: CupertinoIcons.rosette,
                        color: AppColors.systemYellow,
                        text: 'savings.feature5'.tr(),
                      ),
                      const SizedBox(height: AppSizes.md),
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightMd,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandTeal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                          ),
                          child: Text(
                            'common.gotIt'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
