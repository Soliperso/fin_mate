import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../providers/insights_providers.dart';
import '../../domain/entities/recurring_expense_pattern.dart';
import '../../domain/entities/spending_anomaly.dart';
import '../../domain/entities/merchant_insight.dart';

class InsightsTab extends ConsumerWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(spendingInsightsProvider);
    final categoryBreakdownAsync = ref.watch(defaultCategoryBreakdownProvider);
    final forecastAsync = ref.watch(defaultForecastProvider);
    final recurringExpensesAsync = ref.watch(recurringExpensesProvider);
    final spendingAnomaliesAsync = ref.watch(spendingAnomaliesProvider);
    final merchantInsightsAsync = ref.watch(merchantInsightsProvider);
    final weekendVsWeekdayAsync = ref.watch(weekendVsWeekdayProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(spendingInsightsProvider);
        ref.invalidate(defaultCategoryBreakdownProvider);
        ref.invalidate(defaultForecastProvider);
        ref.invalidate(recurringExpensesProvider);
        ref.invalidate(spendingAnomaliesProvider);
        ref.invalidate(merchantInsightsProvider);
        ref.invalidate(weekendVsWeekdayProvider);
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
                  return _buildEmptyStateCard(
                    context,
                    icon: Icons.lightbulb_outline,
                    title: 'No Insights Yet',
                    message: 'Start adding transactions to unlock personalized financial insights and smart recommendations.',
                    backgroundColor: AppColors.primaryTeal,
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
                  return _buildEmptyStateCard(
                    context,
                    icon: Icons.pie_chart_outline,
                    title: 'No Spending Data',
                    message: 'Add some expenses to see your category breakdown and track where your money goes.',
                    backgroundColor: AppColors.primaryTeal,
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
                  return _buildEmptyStateCard(
                    context,
                    icon: Icons.trending_up_outlined,
                    title: 'No Forecast Yet',
                    message: 'Build up your transaction history to generate accurate cashflow forecasts for the next 3 months.',
                    backgroundColor: AppColors.primaryTeal,
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

            const SizedBox(height: AppSizes.xl),

            // Phase 1: Pattern Recognition Insights

            // Recurring Expenses Section
            Text(
              'Subscriptions & Recurring Bills',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            recurringExpensesAsync.when(
              data: (patterns) {
                if (patterns.isEmpty) {
                  return _buildEmptyStateCard(
                    context,
                    icon: Icons.subscriptions_outlined,
                    title: 'No Subscriptions Yet',
                    message: 'Add recurring transactions to identify your subscriptions and track price changes.',
                    backgroundColor: AppColors.primaryTeal,
                  );
                }
                return _buildRecurringExpensesSection(context, patterns);
              },
              loading: () => const SkeletonCard(height: 200),
              error: (error, stack) => ErrorRetryWidget(
                title: 'Failed to analyze patterns',
                message: 'Unable to detect recurring expenses',
                onRetry: () => ref.invalidate(recurringExpensesProvider),
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // Spending Anomalies Section
            Text(
              'Unusual Spending',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            spendingAnomaliesAsync.when(
              data: (anomalies) {
                if (anomalies.isEmpty) {
                  return _buildEmptyStateCard(
                    context,
                    icon: Icons.trending_flat,
                    title: 'Spending on Track',
                    message: 'Great news! No unusual spending detected. Your spending patterns are consistent.',
                    backgroundColor: AppColors.success,
                  );
                }
                return _buildSpendingAnomaliesSection(context, anomalies.take(5).toList());
              },
              loading: () => const SkeletonCard(height: 200),
              error: (error, stack) => ErrorRetryWidget(
                title: 'Failed to detect anomalies',
                message: 'Unable to analyze spending patterns',
                onRetry: () => ref.invalidate(spendingAnomaliesProvider),
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // Top Merchants Section
            Text(
              'Top Merchants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            merchantInsightsAsync.when(
              data: (merchants) {
                if (merchants.isEmpty) {
                  return _buildEmptyStateCard(
                    context,
                    icon: Icons.store_outlined,
                    title: 'No Merchant Data',
                    message: 'Start adding transactions to see your favorite merchants and spending patterns.',
                    backgroundColor: AppColors.warning,
                  );
                }
                return _buildTopMerchantsSection(context, merchants.where((m) => m.isTopMerchant).toList());
              },
              loading: () => const SkeletonCard(height: 250),
              error: (error, stack) => ErrorRetryWidget(
                title: 'Failed to analyze merchants',
                message: 'Unable to load merchant data',
                onRetry: () => ref.invalidate(merchantInsightsProvider),
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // Behavioral Insights Section
            Text(
              'Behavioral Patterns',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            weekendVsWeekdayAsync.when(
              data: (data) {
                return _buildBehavioralInsightsSection(context, data);
              },
              loading: () => const SkeletonCard(height: 150),
              error: (error, stack) => const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.md),
                  child: Text('Unable to analyze behavioral patterns'),
                ),
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

  // Phase 1: Pattern Recognition Builders

  Widget _buildRecurringExpensesSection(BuildContext context, List<RecurringExpensePattern> patterns) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Column(
      children: patterns.map((pattern) {
        final subtitle = '${pattern.interval.displayName} • ${currencyFormat.format(pattern.averageAmount)}';
        final priceChangeInfo = pattern.isPriceIncreased
            ? ' (increased ${pattern.priceChangePercentage?.toStringAsFixed(1)}%)'
            : '';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
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
                        color: pattern.isPriceIncreased
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        pattern.isPriceIncreased ? Icons.trending_up : Icons.subscriptions,
                        color: pattern.isPriceIncreased ? AppColors.warning : AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pattern.merchantName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            subtitle + priceChangeInfo,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Next charge expected: ${pattern.nextExpectedDate != null ? DateFormat('MMM d, yyyy').format(pattern.nextExpectedDate!) : 'Unknown'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpendingAnomaliesSection(BuildContext context, List<SpendingAnomaly> anomalies) {
    return Column(
      children: anomalies.map((anomaly) {
        Color severityColor;
        switch (anomaly.severity) {
          case AnomalySeverity.critical:
            severityColor = AppColors.error;
            break;
          case AnomalySeverity.high:
            severityColor = AppColors.warning;
            break;
          case AnomalySeverity.medium:
            severityColor = AppColors.warning.withValues(alpha: 0.7);
            break;
          case AnomalySeverity.low:
            severityColor = AppColors.primaryTeal;
            break;
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
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(Icons.warning, color: severityColor, size: 24),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anomaly.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        anomaly.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      }).toList(),
    );
  }

  Widget _buildTopMerchantsSection(BuildContext context, List<MerchantInsight> merchants) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Column(
      children: merchants.take(5).map((merchant) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant.merchantName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            merchant.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currencyFormat.format(merchant.totalSpent),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${merchant.visitCount} visits',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      '${merchant.percentageOfCategorySpending.toStringAsFixed(1)}% of category',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBehavioralInsightsSection(BuildContext context, Map<String, dynamic> data) {
    final insight = data['insight'] as String;

    return Card(
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
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekend vs Weekday',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        insight,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Weekday Avg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      '\$${(data['weekday_average'] as num).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Weekend Avg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      '\$${(data['weekend_average'] as num).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }

  // Empty State Builder - Consistent with app design

  Widget _buildEmptyStateCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor.withValues(alpha: 0.08),
              backgroundColor.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.xl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon with background circle
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: backgroundColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: backgroundColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 48,
                        color: backgroundColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSizes.xl),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),

              // Message
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),

              // Subtle accent line
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
