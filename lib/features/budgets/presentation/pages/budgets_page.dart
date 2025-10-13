import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/budget_entity.dart';
import '../providers/budget_providers.dart';
import '../widgets/create_budget_bottom_sheet.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsState = ref.watch(budgetNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {
              // TODO: Show budget insights
            },
          ),
        ],
      ),
      body: budgetsState.when(
        data: (budgets) => budgets.isEmpty
            ? _buildEmptyState(context)
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(budgetNotifierProvider.notifier).refresh();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    return _buildBudgetCard(context, ref, budget);
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Failed to load budgets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(budgetNotifierProvider.notifier).loadBudgets();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateBudgetBottomSheet(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
              size: 120,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'No Budgets Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Create budgets to track your spending by category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, WidgetRef ref, BudgetEntity budget) {
    final spent = budget.spent ?? 0.0;
    final remaining = budget.remaining ?? budget.amount;
    final percentage = budget.spentPercentage.clamp(0.0, 100.0) / 100;
    final isOverBudget = budget.isExceeded;
    final isNearLimit = budget.isNearLimit;

    // Get color for the category icon
    final categoryColor = _parseColor(budget.categoryColor) ?? AppColors.primaryTeal;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: InkWell(
        onTap: () {
          _showBudgetOptions(context, ref, budget);
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
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(
                      _getIconFromName(budget.categoryIcon),
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.categoryName ?? 'Uncategorized',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          budget.period.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isOverBudget
                        ? Icons.warning
                        : isNearLimit
                            ? Icons.warning_amber
                            : Icons.check_circle,
                    color: isOverBudget
                        ? AppColors.error
                        : isNearLimit
                            ? AppColors.warning
                            : AppColors.success,
                    size: AppSizes.iconSm,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showBudgetOptions(context, ref, budget);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: AppColors.lightGray,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget
                        ? AppColors.error
                        : isNearLimit
                            ? AppColors.warning
                            : categoryColor,
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
                        'Spent',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        '\$${spent.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        isOverBudget ? 'Over by' : 'Remaining',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        '\$${remaining.abs().toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isOverBudget ? AppColors.error : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Budget',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        '\$${budget.amount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
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

  void _showCreateBudgetBottomSheet(BuildContext context, {BudgetEntity? budget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateBudgetBottomSheet(budget: budget),
    );
  }

  void _showBudgetOptions(BuildContext context, WidgetRef ref, BudgetEntity budget) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Budget'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateBudgetBottomSheet(context, budget: budget);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete Budget', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Budget'),
                      content: const Text('Are you sure you want to delete this budget?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      await ref.read(budgetNotifierProvider.notifier).deleteBudget(budget.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Budget deleted successfully',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                            elevation: 6,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Failed to delete budget: $e',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.all(16),
                            elevation: 6,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.category;

    // Map common icon names to IconData
    switch (iconName.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'directions_car':
      case 'car':
        return Icons.directions_car;
      case 'movie':
      case 'entertainment':
        return Icons.movie;
      case 'local_hospital':
      case 'health':
        return Icons.local_hospital;
      case 'home':
        return Icons.home;
      case 'school':
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;

    try {
      // Remove # if present
      final hexColor = colorString.replaceAll('#', '');

      // Add FF for alpha if not present
      final colorValue = hexColor.length == 6 ? 'FF$hexColor' : hexColor;

      return Color(int.parse(colorValue, radix: 16));
    } catch (e) {
      return null;
    }
  }
}
