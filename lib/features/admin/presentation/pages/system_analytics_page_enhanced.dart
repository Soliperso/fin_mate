import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../providers/admin_providers.dart';
import '../widgets/analytics_line_chart.dart';
import '../widgets/analytics_bar_chart.dart';
import '../widgets/analytics_pie_chart.dart';
import 'analytics_overview_tab.dart';

class SystemAnalyticsPageEnhanced extends ConsumerStatefulWidget {
  const SystemAnalyticsPageEnhanced({super.key});

  @override
  ConsumerState<SystemAnalyticsPageEnhanced> createState() => _SystemAnalyticsPageEnhancedState();
}

class _SystemAnalyticsPageEnhancedState extends ConsumerState<SystemAnalyticsPageEnhanced>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnalyticsDateRange _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _dateRange = AnalyticsDateRange.last30Days();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDateRangePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Time Range',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),
            _buildDateRangeOption('Last 7 Days', AnalyticsDateRange.last7Days()),
            _buildDateRangeOption('Last 30 Days', AnalyticsDateRange.last30Days()),
            _buildDateRangeOption('Last 90 Days', AnalyticsDateRange.last90Days()),
            _buildDateRangeOption('Last 12 Months', AnalyticsDateRange.last12Months()),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeOption(String label, AnalyticsDateRange range) {
    return ListTile(
      title: Text(label),
      trailing: _dateRange.startDate == range.startDate && _dateRange.endDate == range.endDate
          ? const Icon(Icons.check, color: AppColors.primaryTeal)
          : null,
      onTap: () {
        setState(() {
          _dateRange = range;
        });
        Navigator.pop(context);
        // Invalidate relevant providers to refresh data
        ref.invalidate(userGrowthTrendsProvider);
        ref.invalidate(financialTrendsProvider);
        ref.invalidate(categoryBreakdownProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Analytics'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Engagement'),
            Tab(text: 'Features'),
            Tab(text: 'Insights'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Date Range',
            onPressed: _showDateRangePicker,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(systemStatsProvider);
              ref.invalidate(userGrowthTrendsProvider);
              ref.invalidate(financialTrendsProvider);
              ref.invalidate(featureAdoptionStatsProvider);
              ref.invalidate(categoryBreakdownProvider);
              ref.invalidate(engagementMetricsProvider);
              ref.invalidate(netWorthPercentilesProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AnalyticsOverviewTab(),
          _buildTrendsTab(),
          _buildEngagementTab(),
          _buildFeaturesTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // Trends Tab
  // ============================================================================

  Widget _buildTrendsTab() {
    final userGrowthAsync = ref.watch(userGrowthTrendsProvider(_dateRange));
    final financialTrendsAsync = ref.watch(financialTrendsProvider(_dateRange));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userGrowthTrendsProvider);
        ref.invalidate(financialTrendsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Growth Chart
            userGrowthAsync.when(
              data: (trends) {
                if (trends.isEmpty) {
                  return EmptyStateCard(
                    icon: Icons.trending_up_outlined,
                    title: 'No User Growth Data',
                    message: 'User growth trends will appear once data is available',
                    backgroundColor: AppColors.primaryTeal,
                  );
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: AnalyticsLineChart(
                      dates: trends.map((t) => t.periodStart).toList(),
                      values: trends.map((t) => t.newUsers.toDouble()).toList(),
                      title: 'User Growth (New Users)',
                      lineColor: AppColors.primaryTeal,
                    ),
                  ),
                );
              },
              loading: () => Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => EmptyStateCard(
                icon: Icons.error_outline,
                title: 'Error Loading User Growth',
                message: 'Failed to load user growth data: $error',
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Financial Trends
            financialTrendsAsync.when(
              data: (trends) {
                if (trends.isEmpty) {
                  return EmptyStateCard(
                    icon: Icons.show_chart_outlined,
                    title: 'No Financial Data Available',
                    message: 'Financial trends will appear as users make transactions',
                    backgroundColor: AppColors.success,
                  );
                }
                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: AnalyticsLineChart(
                          dates: trends.map((t) => t.periodStart).toList(),
                          values: trends.map((t) => t.totalIncome).toList(),
                          title: 'Income Trends',
                          lineColor: AppColors.success,
                          valuePrefix: '\$',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: AnalyticsLineChart(
                          dates: trends.map((t) => t.periodStart).toList(),
                          values: trends.map((t) => t.totalExpense).toList(),
                          title: 'Expense Trends',
                          lineColor: AppColors.error,
                          valuePrefix: '\$',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: AnalyticsLineChart(
                          dates: trends.map((t) => t.periodStart).toList(),
                          values: trends.map((t) => t.transactionCount.toDouble()).toList(),
                          title: 'Transaction Volume',
                          lineColor: AppColors.tealBlue,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => EmptyStateCard(
                icon: Icons.error_outline,
                title: 'Error Loading Financial Data',
                message: 'Failed to load financial trends: $error',
                backgroundColor: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Engagement Tab
  // ============================================================================

  Widget _buildEngagementTab() {
    final engagementAsync = ref.watch(engagementMetricsProvider(30));
    final categoryBreakdownAsync = ref.watch(categoryBreakdownProvider(_dateRange));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(engagementMetricsProvider);
        ref.invalidate(categoryBreakdownProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            engagementAsync.when(
              data: (metrics) => Column(
                children: metrics
                    .map((metric) => Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.md),
                          child: ListTile(
                            title: Text(metric.metricName),
                            subtitle: Text(metric.metricDescription),
                            trailing: Text(
                              metric.metricName.contains('Rate') || metric.metricName.contains('Percentage')
                                  ? '${metric.metricValue.toStringAsFixed(1)}%'
                                  : metric.metricValue.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTeal,
                                  ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
            const SizedBox(height: AppSizes.xl),

            // Category Breakdown
            categoryBreakdownAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return EmptyStateCard(
                    icon: Icons.category_outlined,
                    title: 'No Category Data Available',
                    message: 'Category spending data will appear once transactions are created',
                    backgroundColor: AppColors.tealBlue,
                  );
                }
                final top5 = categories.take(5).toList();
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: AnalyticsPieChart(
                      labels: top5.map((c) => c.categoryName).toList(),
                      values: top5.map((c) => c.totalAmount).toList(),
                      title: 'Top Spending Categories',
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => EmptyStateCard(
                icon: Icons.error_outline,
                title: 'Error Loading Category Data',
                message: 'Failed to load category breakdown: $error',
                backgroundColor: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Features Tab
  // ============================================================================

  Widget _buildFeaturesTab() {
    final featuresAsync = ref.watch(featureAdoptionStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(featureAdoptionStatsProvider);
      },
      child: featuresAsync.when(
        data: (features) {
          if (features.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.md),
              child: EmptyStateCard(
                icon: Icons.apps_outlined,
                title: 'No Feature Adoption Data',
                message: 'Feature adoption metrics will appear once users start using features',
                backgroundColor: AppColors.tealBlue,
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: AnalyticsBarChart(
                      labels: features.map((f) => f.featureName).toList(),
                      values: features.map((f) => f.adoptionPercentage).toList(),
                      title: 'Feature Adoption Rates (%)',
                      barColor: AppColors.tealBlue,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                ...features.map((feature) => Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.md),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  feature.featureName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '${feature.adoptionPercentage.toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryTeal,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),
                            LinearProgressIndicator(
                              value: feature.adoptionPercentage / 100,
                              backgroundColor: AppColors.lightGray,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              '${feature.usersUsingFeature} of ${feature.totalUsers} users • ${feature.totalItems} total items',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.md),
          child: EmptyStateCard(
            icon: Icons.error_outline,
            title: 'Error Loading Features',
            message: 'Failed to load feature adoption data: $error',
            backgroundColor: AppColors.error,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Insights Tab
  // ============================================================================

  Widget _buildInsightsTab() {
    final percentilesAsync = ref.watch(netWorthPercentilesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(netWorthPercentilesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Worth Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            percentilesAsync.when(
              data: (percentiles) {
                if (percentiles.isEmpty) {
                  return EmptyStateCard(
                    icon: Icons.info_outline,
                    title: 'No Percentile Data Available',
                    message: 'Net worth distribution data will appear once users create accounts',
                    backgroundColor: AppColors.primaryTeal,
                  );
                }
                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: AnalyticsBarChart(
                          labels: percentiles.map((p) => p.percentile).toList(),
                          values: percentiles.map((p) => p.netWorthValue).toList(),
                          title: 'Net Worth by Percentile',
                          barColor: AppColors.primaryTeal,
                          valuePrefix: '\$',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    ...percentiles.map((percentile) => Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.md),
                          child: ListTile(
                            title: Text(percentile.percentile),
                            trailing: Text(
                              NumberFormat.currency(symbol: '\$').format(percentile.netWorthValue),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTeal,
                                  ),
                            ),
                          ),
                        )),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => EmptyStateCard(
                icon: Icons.error_outline,
                title: 'Error Loading Percentile Data',
                message: 'Failed to load net worth distribution: $error',
                backgroundColor: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
