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
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/add_contribution_bottom_sheet.dart';
import '../widgets/create_goal_bottom_sheet.dart';
import '../widgets/goal_achievement_dialog.dart';
import '../widgets/goal_card.dart';
import '../widgets/goals_summary_card.dart';

class SavingsGoalsPage extends ConsumerStatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  ConsumerState<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends ConsumerState<SavingsGoalsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final summaryAsync = ref.watch(goalsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('savings.title'.tr()),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () =>
                context.canPop() ? context.pop() : context.go('/dashboard'),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.add,
              onTap: () => _showCreateGoalSheet(context, ref),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savingsGoalsProvider);
          ref.invalidate(goalsSummaryProvider);
        },
        child: goalsAsync.when(
          data: (goals) {
            final filtered = _searchQuery.isEmpty
                ? goals
                : goals
                    .where((g) => g.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

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
                  const SizedBox(height: AppSizes.md),

                  // Search bar
                  Builder(builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return TextField(
                      controller: _searchController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'savings.searchHint'.tr(),
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                }),
                                child: const Icon(CupertinoIcons.xmark_circle_fill,
                                    size: 18, color: AppColors.systemGray3),
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.secondarySystemBackgroundDark
                            : AppColors.systemGray6,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md, vertical: 10),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    );
                  }),
                  const SizedBox(height: AppSizes.lg),

                  // Active Goals
                  if (filtered.any((g) => !g.isCompleted)) ...[
                    Text(
                      'savings.activeGoals'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...filtered
                        .where((g) => !g.isCompleted)
                        .map((goal) => GoalCard(
                              goal: goal,
                              onContribute: () =>
                                  _showContributeSheet(context, ref, goal),
                            )),
                  ],

                  // Completed Goals
                  if (filtered.any((g) => g.isCompleted)) ...[
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'savings.completedGoals'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...filtered
                        .where((g) => g.isCompleted)
                        .map((goal) => GoalCard(goal: goal)),
                  ],

                  // No results state
                  if (filtered.isEmpty && _searchQuery.isNotEmpty)
                    EmptyStateCard(
                      icon: CupertinoIcons.search,
                      title: 'savings.noSearchResults'.tr(),
                      message: 'savings.noSearchResultsMessage'.tr(),
                      backgroundColor: AppColors.brandTeal,
                    ),
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
              ref.invalidate(goalsSummaryProvider);
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

}
