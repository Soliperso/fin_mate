import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../providers/insights_providers.dart';

class InsightsTab extends ConsumerWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(spendingInsightsProvider);
    final categoryBreakdownAsync = ref.watch(defaultCategoryBreakdownProvider);
    final forecastAsync = ref.watch(defaultForecastProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(spendingInsightsProvider);
        ref.invalidate(defaultCategoryBreakdownProvider);
        ref.invalidate(defaultForecastProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Insights Section
            Text(
              'Personalized Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            insightsAsync.when(
              data: (insights) {
                if (insights.isEmpty) {
                  return const EmptyState(
                    icon: Icons.insights,
                    title: 'No Insights Yet',
                    message: 'Start adding transactions to get personalized financial insights',
                    animated: false,
                  );
                }
                return Column(
                  children: insights.map((insight) => _buildInsightCard(context, insight)).toList(),
                );
              },
              loading: () => Column(
                children: const [
                  SkeletonCard(height: 100),
                  SkeletonCard(height: 100),
                  SkeletonCard(height: 100),
                ],
              ),
              error: (error, stack) => ErrorRetryWidget(
                title: 'Failed to load insights',
                message: 'Unable to analyze your spending patterns',
                onRetry: () => ref.invalidate(spendingInsightsProvider),
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // Category Breakdown
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            categoryBreakdownAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const EmptyState(
                    icon: Icons.pie_chart,
                    title: 'No Spending Data',
                    message: 'Add some expenses to see your category breakdown',
                    animated: false,
                  );
                }
                return _buildCategoryBreakdown(context, categories);
              },
              loading: () => const SkeletonCard(height: 300),
              error: (error, stack) => ErrorRetryWidget(
                title: 'Failed to load categories',
                message: 'Unable to load spending breakdown',
                onRetry: () => ref.invalidate(defaultCategoryBreakdownProvider),
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // Forecast Section
            Text(
              'Cashflow Forecast (Next 3 Months)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            forecastAsync.when(
              data: (forecast) {
                if (forecast.isEmpty) {
                  return const EmptyState(
                    icon: Icons.trending_up,
                    title: 'No Forecast Available',
                    message: 'Need more transaction history to generate forecasts',
                    animated: false,
                  );
                }
                return _buildForecastSection(context, forecast);
              },
              loading: () => const SkeletonCard(height: 250),
              error: (error, stack) => ErrorRetryWidget(
                title: 'Failed to generate forecast',
                message: 'Unable to predict future cashflow',
                onRetry: () => ref.invalidate(defaultForecastProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, Map<String, dynamic> insight) {
    final type = insight['color'] as String? ?? 'info';
    Color color;
    Color bgColor;

    switch (type) {
      case 'warning':
        color = AppColors.warning;
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        break;
      case 'error':
        color = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.1);
        break;
      case 'success':
        color = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.1);
        break;
      default:
        color = AppColors.primaryTeal;
        bgColor = AppColors.primaryTeal.withValues(alpha: 0.1);
    }

    IconData icon;
    switch (insight['icon'] as String?) {
      case 'trending_up':
        icon = Icons.trending_up;
        break;
      case 'check_circle':
        icon = Icons.check_circle;
        break;
      case 'warning':
        icon = Icons.warning;
        break;
      case 'savings':
        icon = Icons.savings;
        break;
      case 'info':
        icon = Icons.info;
        break;
      default:
        icon = Icons.lightbulb;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    insight['message'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, List<Map<String, dynamic>> categories) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final total = categories.fold(0.0, (sum, cat) => sum + (cat['total_amount'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: categories.take(5).map((category) {
            final amount = category['total_amount'] as double;
            final percentage = total > 0 ? (amount / total * 100) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category['category_name'] as String,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        currencyFormat.format(amount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: AppColors.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildForecastSection(BuildContext context, List<Map<String, dynamic>> forecast) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: forecast.map((month) {
            final monthStr = month['month'] as String;
            final income = month['income'] as double;
            final expense = month['expense'] as double;
            final net = month['net'] as double;
            final isPositive = net >= 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatMonthYear(monthStr),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'In: ${currencyFormat.format(income)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                        ),
                        Text(
                          'Out: ${currencyFormat.format(expense)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Text(
                      '${isPositive ? '+' : ''}${currencyFormat.format(net)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isPositive ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatMonthYear(String monthStr) {
    final parts = monthStr.split('-');
    if (parts.length != 2) return monthStr;

    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 1;

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${monthNames[month - 1]} $year';
  }
}
