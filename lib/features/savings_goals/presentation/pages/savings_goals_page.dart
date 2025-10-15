import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../providers/savings_goal_providers.dart';
import '../widgets/create_goal_bottom_sheet.dart';
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
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
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
            if (goals.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'No Savings Goals Yet',
                    message: 'Start planning for your future by creating your first savings goal',
                    actionLabel: 'Create Goal',
                    onAction: () => _showCreateGoalSheet(context, ref),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.md),
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
                    'Active Goals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.md),
                  ...goals.where((g) => !g.isCompleted).map((goal) => GoalCard(goal: goal)),

                  // Completed Goals
                  if (goals.any((g) => g.isCompleted)) ...[
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Completed Goals',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...goals.where((g) => g.isCompleted).map((goal) => GoalCard(goal: goal)),
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
                  title: 'Failed to load goals',
                  message: 'Unable to fetch your savings goals. Please try again.',
                  onRetry: () => ref.invalidate(savingsGoalsProvider),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGoalSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  void _showCreateGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateGoalBottomSheet(),
    ).then((created) {
      if (created == true) {
        ref.invalidate(savingsGoalsProvider);
        ref.invalidate(goalsSummaryProvider);
      }
    });
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Savings Goals'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set and track your financial goals with ease.'),
              SizedBox(height: AppSizes.md),
              Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: AppSizes.sm),
              Text('• Create goals with target amounts'),
              Text('• Set optional deadlines'),
              Text('• Track progress with contributions'),
              Text('• Categorize your goals'),
              Text('• Celebrate when you achieve them!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
