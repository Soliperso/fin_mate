import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../providers/admin_providers.dart';
import '../widgets/analytics_line_chart.dart';
import '../widgets/analytics_bar_chart.dart';
import '../widgets/analytics_pie_chart.dart';
import 'analytics_overview_tab.dart';

class SystemAnalyticsPageEnhanced extends ConsumerStatefulWidget {
  const SystemAnalyticsPageEnhanced({super.key});

  @override
  ConsumerState<SystemAnalyticsPageEnhanced> createState() =>
      _SystemAnalyticsPageEnhancedState();
}

class _SystemAnalyticsPageEnhancedState
    extends ConsumerState<SystemAnalyticsPageEnhanced>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _refreshController;
  late AnalyticsDateRange _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _dateRange = AnalyticsDateRange.last30Days();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  String get _dateRangeLabel {
    if (_dateRange.startDate == AnalyticsDateRange.last7Days().startDate) {
      return 'Last 7 Days';
    }
    if (_dateRange.startDate == AnalyticsDateRange.last30Days().startDate) {
      return 'Last 30 Days';
    }
    if (_dateRange.startDate == AnalyticsDateRange.last90Days().startDate) {
      return 'Last 90 Days';
    }
    return 'Last 12 Months';
  }

  void _showDateRangePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final options = [
      (
        'Last 7 Days',
        'Daily granularity · quick overview',
        CupertinoIcons.calendar,
        AppColors.systemBlue,
        AnalyticsDateRange.last7Days(),
      ),
      (
        'Last 30 Days',
        'Daily granularity · monthly trends',
        CupertinoIcons.calendar_today,
        AppColors.brandTeal,
        AnalyticsDateRange.last30Days(),
      ),
      (
        'Last 90 Days',
        'Weekly granularity · quarterly view',
        CupertinoIcons.chart_bar_square,
        AppColors.systemOrange,
        AnalyticsDateRange.last90Days(),
      ),
      (
        'Last 12 Months',
        'Monthly granularity · full year',
        CupertinoIcons.calendar_badge_plus,
        AppColors.systemPurple,
        AnalyticsDateRange.last12Months(),
      ),
    ];

    GlassBottomSheet.show(
      context: context,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle + header
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: AppSizes.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.tertiaryLabelDark
                      : AppColors.systemGray4,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding, AppSizes.md, AppSizes.pagePadding, AppSizes.sm),
              child: Text(
                'TIME RANGE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.secondaryLabel,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            // Options
            ...options.map((opt) {
              final isSelected = _dateRange.startDate == opt.$5.startDate &&
                  _dateRange.endDate == opt.$5.endDate;
              return _buildDateRangeOption(
                label: opt.$1,
                description: opt.$2,
                icon: opt.$3,
                iconColor: opt.$4,
                range: opt.$5,
                isSelected: isSelected,
                isDark: isDark,
              );
            }),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeOption({
    required String label,
    required String description,
    required IconData icon,
    required Color iconColor,
    required AnalyticsDateRange range,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _dateRange = range);
        Navigator.pop(context);
        ref.invalidate(userGrowthTrendsProvider);
        ref.invalidate(financialTrendsProvider);
        ref.invalidate(categoryBreakdownProvider);
        ref.invalidate(engagementMetricsProvider);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pagePadding, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandTeal.withValues(alpha: 0.15)
                    : iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.brandTeal : iconColor,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.brandTeal
                              : null,
                        ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.secondaryLabelDark
                              : AppColors.secondaryLabel,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.brandTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.checkmark,
                  size: 13,
                  color: Colors.white,
                ),
              )
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }

  void _refreshAll() {
    _refreshController.repeat();
    ref.invalidate(systemStatsProvider);
    ref.invalidate(userGrowthTrendsProvider);
    ref.invalidate(financialTrendsProvider);
    ref.invalidate(featureAdoptionStatsProvider);
    ref.invalidate(categoryBreakdownProvider);
    ref.invalidate(engagementMetricsProvider);
    ref.invalidate(netWorthPercentilesProvider);
    ref.invalidate(churnMetricsProvider);
    ref.invalidate(subscriptionCohortsProvider);
    ref.invalidate(subscriptionTimelineProvider);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _refreshController.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Analytics'),
            Text(
              _dateRangeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.calendar,
              onTap: _showDateRangePicker,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: GestureDetector(
              onTap: _refreshAll,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardTheme.color,
                ),
                child: RotationTransition(
                  turns: _refreshController,
                  child: Icon(
                    CupertinoIcons.arrow_counterclockwise,
                    size: 18,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            height: 52,
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.brandTeal,
              unselectedLabelColor: isDark
                  ? AppColors.secondaryLabelDark
                  : AppColors.secondaryLabel,
              indicator: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
              unselectedLabelStyle:
                  Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 0,
                      ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.xs),
              tabs: const [
                _AdminTab(icon: CupertinoIcons.square_grid_2x2, label: 'Overview'),
                _AdminTab(icon: CupertinoIcons.chart_bar, label: 'Trends'),
                _AdminTab(icon: CupertinoIcons.person_2, label: 'Engagement'),
                _AdminTab(icon: CupertinoIcons.checkmark_seal, label: 'Features'),
                _AdminTab(icon: CupertinoIcons.lightbulb, label: 'Insights'),
                _AdminTab(icon: CupertinoIcons.creditcard, label: 'Subscription'),
              ] as List<Widget>,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AnalyticsOverviewTab(),
          _buildTrendsTab(),
          _buildEngagementTab(),
          _buildFeaturesTab(),
          _buildInsightsTab(),
          _buildSubscriptionTab(),
        ],
      ),
    );
  }

  // ── Section label with horizontal rule ────────────────────────────────────

  Widget _sectionLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ruleColor = isDark ? AppColors.separatorDark : AppColors.separator;
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Container(height: 0.5, color: ruleColor),
        ),
      ],
    );
  }

  // ── Chart card ─────────────────────────────────────────────────────────────

  Widget _chartCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: isDark
            ? null
            : Border.all(color: AppColors.separator, width: 0.5),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: child,
    );
  }

  Widget _chartCardLoading() {
    return _chartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(
              width: 160,
              height: 14,
              borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: AppSizes.md),
          LoadingSkeleton(
              height: 160,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
        ],
      ),
    );
  }

  // ── Trends Tab ─────────────────────────────────────────────────────────────

  Widget _buildTrendsTab() {
    final userGrowthAsync = ref.watch(userGrowthTrendsProvider(_dateRange));
    final financialTrendsAsync = ref.watch(financialTrendsProvider(_dateRange));

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async {
        ref.invalidate(userGrowthTrendsProvider);
        ref.invalidate(financialTrendsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('User Growth'),
            const SizedBox(height: AppSizes.sm),
            userGrowthAsync.when(
              data: (trends) => trends.isEmpty
                  ? EmptyStateCard(
                      icon: CupertinoIcons.arrow_up_right,
                      title: 'No User Growth Data',
                      message: 'User growth trends will appear once data is available',
                      backgroundColor: AppColors.brandTeal,
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _chartCard(
                            child: AnalyticsLineChart(
                              dates: trends.map((t) => t.periodStart).toList(),
                              values: trends.map((t) => t.newUsers.toDouble()).toList(),
                              title: 'New Users',
                              lineColor: AppColors.brandTeal,
                              compact: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: _chartCard(
                            child: AnalyticsLineChart(
                              dates: trends.map((t) => t.periodStart).toList(),
                              values: trends.map((t) => t.cumulativeUsers.toDouble()).toList(),
                              title: 'Total Users',
                              lineColor: AppColors.systemOrange,
                              compact: true,
                            ),
                          ),
                        ),
                      ],
                    ),
              loading: () => Row(
                children: [
                  Expanded(child: _chartCardLoading()),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(child: _chartCardLoading()),
                ],
              ),
              error: (e, _) => EmptyStateCard(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Error Loading Data',
                message: e.toString(),
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            _sectionLabel('Financial Trends'),
            const SizedBox(height: AppSizes.sm),
            financialTrendsAsync.when(
              data: (trends) => trends.isEmpty
                  ? EmptyStateCard(
                      icon: CupertinoIcons.chart_bar,
                      title: 'No Financial Data',
                      message: 'Financial trends will appear as users make transactions',
                      backgroundColor: AppColors.systemGreen,
                    )
                  : Column(
                      children: [
                        // Income + Expenses side by side
                        Row(
                          children: [
                            Expanded(
                              child: _chartCard(
                                child: AnalyticsLineChart(
                                  dates: trends.map((t) => t.periodStart).toList(),
                                  values: trends.map((t) => t.totalIncome).toList(),
                                  title: 'Income',
                                  lineColor: AppColors.systemGreen,
                                  valuePrefix: '\$',
                                  compact: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: _chartCard(
                                child: AnalyticsLineChart(
                                  dates: trends.map((t) => t.periodStart).toList(),
                                  values: trends.map((t) => t.totalExpense).toList(),
                                  title: 'Expenses',
                                  lineColor: AppColors.systemRed,
                                  valuePrefix: '\$',
                                  compact: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Transaction Volume — full width
                        _chartCard(
                          child: AnalyticsLineChart(
                            dates: trends.map((t) => t.periodStart).toList(),
                            values: trends.map((t) => t.transactionCount.toDouble()).toList(),
                            title: 'Transaction Volume',
                            lineColor: AppColors.tealBlue,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Net Cash Flow — full width (most important)
                        _chartCard(
                          child: AnalyticsLineChart(
                            dates: trends.map((t) => t.periodStart).toList(),
                            values: trends.map((t) => t.netCashflow).toList(),
                            title: 'Net Cash Flow · Income − Expenses',
                            lineColor: AppColors.brandTeal,
                            valuePrefix: '\$',
                          ),
                        ),
                      ],
                    ),
              loading: () => Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _chartCardLoading()),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(child: _chartCardLoading()),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  _chartCardLoading(),
                  const SizedBox(height: AppSizes.md),
                  _chartCardLoading(),
                ],
              ),
              error: (e, _) => EmptyStateCard(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Error Loading Data',
                message: e.toString(),
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  // ── Engagement Tab ─────────────────────────────────────────────────────────

  Widget _buildEngagementTab() {
    final periodDays = _dateRange.endDate.difference(_dateRange.startDate).inDays;
    final engagementAsync = ref.watch(engagementMetricsProvider(periodDays));
    final categoryBreakdownAsync =
        ref.watch(categoryBreakdownProvider(_dateRange));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async {
        ref.invalidate(engagementMetricsProvider);
        ref.invalidate(categoryBreakdownProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Engagement Metrics'),
            const SizedBox(height: AppSizes.sm),
            engagementAsync.when(
              data: (metrics) => Column(
                children: metrics.map((metric) {
                  final accent = _engagementAccent(metric.metricName);
                  final isRate = metric.metricName.contains('Rate') ||
                      metric.metricName.contains('Percentage');
                  final formattedValue = isRate
                      ? '${metric.metricValue.toStringAsFixed(1)}%'
                      : metric.metricValue.toStringAsFixed(1);

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusCard),
                      border: isDark
                          ? null
                          : Border.all(
                              color: AppColors.separator, width: 0.5),
                      boxShadow: AppColors.cardShadow(isDark),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent.$2.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: Icon(accent.$1,
                              size: 16, color: accent.$2),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metric.metricName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                metric.metricDescription,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.secondaryLabelDark
                                          : AppColors.secondaryLabel,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          formattedValue,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: accent.$2,
                                letterSpacing: -0.3,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              loading: () => Column(
                children: List.generate(
                  4,
                  (_) => Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusCard)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LoadingSkeleton(
                            width: 120,
                            height: 14,
                            borderRadius: BorderRadius.circular(4)),
                        LoadingSkeleton(
                            width: 50,
                            height: 14,
                            borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ),
                ),
              ),
              error: (e, _) => EmptyStateCard(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Error',
                message: e.toString(),
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            _sectionLabel('Top Spending Categories'),
            const SizedBox(height: AppSizes.sm),
            categoryBreakdownAsync.when(
              data: (categories) => categories.isEmpty
                  ? EmptyStateCard(
                      icon: CupertinoIcons.square_grid_2x2,
                      title: 'No Category Data',
                      message: 'Category data will appear once transactions are created',
                      backgroundColor: AppColors.tealBlue,
                    )
                  : Column(
                      children: [
                        _buildCategoryBreakdownChart(categories, isDark),
                        const SizedBox(height: AppSizes.lg),
                        _sectionLabel('Category Details'),
                        const SizedBox(height: AppSizes.sm),
                        _buildCategoryDetailsList(categories, isDark),
                      ],
                    ),
              loading: () => _chartCardLoading(),
              error: (e, _) => EmptyStateCard(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Error',
                message: e.toString(),
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  /// Returns (icon, color) for an engagement metric based on its name.
  (IconData, Color) _engagementAccent(String metricName) {
    final name = metricName.toLowerCase();
    if (name.contains('rate') || name.contains('retention')) {
      return (CupertinoIcons.arrow_up_right_circle, AppColors.systemGreen);
    }
    if (name.contains('session') || name.contains('duration')) {
      return (CupertinoIcons.timer, AppColors.systemOrange);
    }
    if (name.contains('transaction')) {
      return (CupertinoIcons.arrow_right_arrow_left, AppColors.brandTeal);
    }
    return (CupertinoIcons.chart_bar, AppColors.systemBlue);
  }

  // ── Features Tab ───────────────────────────────────────────────────────────

  Widget _buildFeaturesTab() {
    final featuresAsync = ref.watch(featureAdoptionStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async => ref.invalidate(featureAdoptionStatsProvider),
      child: featuresAsync.when(
        data: (features) {
          if (features.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              child: EmptyStateCard(
                icon: CupertinoIcons.square_grid_2x2,
                title: 'No Feature Data',
                message: 'Feature adoption metrics will appear once users start using features',
                backgroundColor: AppColors.tealBlue,
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Adoption Rates'),
                const SizedBox(height: AppSizes.sm),
                _chartCard(
                  child: AnalyticsBarChart(
                    labels: features.map((f) => f.featureName).toList(),
                    values: features.map((f) => f.adoptionPercentage).toList(),
                    title: 'Feature Adoption (%)',
                    barColor: AppColors.tealBlue,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                _sectionLabel('Details'),
                const SizedBox(height: AppSizes.sm),
                ...features.map((feature) {
                  final tier = _adoptionTier(feature.adoptionPercentage);
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusCard),
                      border: isDark
                          ? null
                          : Border.all(
                              color: AppColors.separator, width: 0.5),
                      boxShadow: AppColors.cardShadow(isDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                feature.featureName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.sm, vertical: 3),
                              decoration: BoxDecoration(
                                color: tier.$1.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                              child: Text(
                                tier.$2,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tier.$1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          child: LinearProgressIndicator(
                            value: feature.adoptionPercentage / 100,
                            backgroundColor: isDark
                                ? AppColors.tertiarySystemBackgroundDark
                                : AppColors.secondarySystemBackground,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(tier.$1),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          '${feature.usersUsingFeature} of ${feature.totalUsers} users · ${feature.totalItems} total items',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.secondaryLabelDark
                                    : AppColors.secondaryLabel,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          );
        },
        loading: () => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: _chartCardLoading(),
        ),
        error: (e, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          child: EmptyStateCard(
            icon: CupertinoIcons.exclamationmark_circle,
            title: 'Error',
            message: e.toString(),
            backgroundColor: AppColors.error,
          ),
        ),
      ),
    );
  }

  /// Returns (color, tierLabel) for an adoption percentage.
  (Color, String) _adoptionTier(double pct) {
    if (pct >= 70) return (AppColors.systemGreen, 'High');
    if (pct >= 40) return (AppColors.brandTeal, 'Medium');
    if (pct >= 20) return (AppColors.systemOrange, 'Low');
    return (AppColors.systemRed, 'Very Low');
  }

  // ── Subscription Tab ───────────────────────────────────────────────────────

  Widget _buildSubscriptionTab() {
    final churnAsync = ref.watch(churnMetricsProvider(_dateRange));
    final cohortsAsync = ref.watch(subscriptionCohortsProvider);
    final timelineAsync = ref.watch(subscriptionTimelineProvider(_dateRange));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async {
        ref.invalidate(churnMetricsProvider);
        ref.invalidate(subscriptionCohortsProvider);
        ref.invalidate(subscriptionTimelineProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPI Cards — 2-column grid ──────────────────────────────
            _sectionLabel('Key Metrics'),
            const SizedBox(height: AppSizes.sm),
            churnAsync.when(
              data: (metrics) => metrics.isEmpty
                  ? EmptyStateCard(
                      icon: CupertinoIcons.creditcard,
                      title: 'No Subscription Data',
                      message:
                          'Subscription metrics will appear once users subscribe',
                      backgroundColor: AppColors.systemPurple,
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSizes.sm,
                      crossAxisSpacing: AppSizes.sm,
                      childAspectRatio: 1.4,
                      children: metrics
                          .map((m) => _buildChurnKpiTile(
                                m.metricLabel,
                                m.isPercent
                                    ? '${m.metricValue.toStringAsFixed(1)}%'
                                    : NumberFormat.compact()
                                        .format(m.metricValue),
                                m.metricChange,
                                m.lowerIsBetter,
                                cardColor,
                                isDark,
                              ))
                          .toList(),
                    ),
              loading: () => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSizes.sm,
                crossAxisSpacing: AppSizes.sm,
                childAspectRatio: 1.4,
                children: List.generate(
                  6,
                  (_) => Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    ),
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LoadingSkeleton(
                            width: 80,
                            height: 12,
                            borderRadius: BorderRadius.circular(4)),
                        LoadingSkeleton(
                            width: 50,
                            height: 20,
                            borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ),
                ),
              ),
              error: (e, _) => EmptyStateCard(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Error',
                message: e.toString(),
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Subscription Timeline ──────────────────────────────────
            _sectionLabel('Subscription Events'),
            const SizedBox(height: AppSizes.sm),
            timelineAsync.when(
              data: (timeline) {
                final hasData = timeline.any((t) =>
                    t.newSubs > 0 ||
                    t.cancellations > 0 ||
                    t.renewals > 0 ||
                    t.trials > 0);
                if (!hasData) {
                  return EmptyStateCard(
                    icon: CupertinoIcons.chart_bar,
                    title: 'No Event Data',
                    message:
                        'Subscription events will appear as users subscribe or cancel',
                    backgroundColor: AppColors.brandTeal,
                  );
                }
                return Column(
                  children: [
                    _chartCard(
                      child: AnalyticsLineChart(
                        dates: timeline.map((t) => t.periodDate).toList(),
                        values: timeline
                            .map((t) => t.newSubs.toDouble())
                            .toList(),
                        title: 'New Subscriptions',
                        lineColor: AppColors.systemGreen,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _chartCard(
                      child: AnalyticsLineChart(
                        dates: timeline.map((t) => t.periodDate).toList(),
                        values: timeline
                            .map((t) => t.cancellations.toDouble())
                            .toList(),
                        title: 'Cancellations',
                        lineColor: AppColors.systemRed,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _chartCard(
                      child: AnalyticsLineChart(
                        dates: timeline.map((t) => t.periodDate).toList(),
                        values:
                            timeline.map((t) => t.renewals.toDouble()).toList(),
                        title: 'Renewals',
                        lineColor: AppColors.brandTeal,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _chartCard(
                      child: AnalyticsLineChart(
                        dates: timeline.map((t) => t.periodDate).toList(),
                        values:
                            timeline.map((t) => t.trials.toDouble()).toList(),
                        title: 'Trial Starts',
                        lineColor: AppColors.systemPurple,
                      ),
                    ),
                  ],
                );
              },
              loading: () => _chartCardLoading(),
              error: (e, _) => EmptyStateCard(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Error',
                message: e.toString(),
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Cohorts by Signup Month ────────────────────────────────
            _sectionLabel('Cohorts by Signup Month'),
            const SizedBox(height: AppSizes.sm),
            cohortsAsync.when(
              data: (cohorts) => cohorts.isEmpty
                  ? EmptyStateCard(
                      icon: CupertinoIcons.person_3,
                      title: 'No Cohort Data',
                      message: 'Cohort data will appear as users sign up',
                      backgroundColor: AppColors.tealBlue,
                    )
                  : Column(
                      children: [
                        _chartCard(
                          child: AnalyticsBarChart(
                            labels: cohorts
                                .map((c) => c.cohortMonth)
                                .toList()
                                .reversed
                                .toList(),
                            values: cohorts
                                .map((c) => c.conversionRate)
                                .toList()
                                .reversed
                                .toList(),
                            title: 'Trial-to-Paid Conversion by Signup Month (%)',
                            barColor: AppColors.systemPurple,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Cohort table
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusCard),
                            border: isDark
                                ? null
                                : Border.all(
                                    color: AppColors.separator, width: 0.5),
                            boxShadow: AppColors.cardShadow(isDark),
                          ),
                          child: Column(
                            children: [
                              // Header row
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.md, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Cohort',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.secondaryLabelDark
                                                  : AppColors.secondaryLabel,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Signups',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.secondaryLabelDark
                                                  : AppColors.secondaryLabel,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Premium',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.secondaryLabelDark
                                                  : AppColors.secondaryLabel,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Conv. %',
                                        textAlign: TextAlign.right,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.secondaryLabelDark
                                                  : AppColors.secondaryLabel,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 0, thickness: 0.5),
                              ...cohorts.map((c) => Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSizes.md,
                                            vertical: 11),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                c.cohortMonth,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${c.totalSignups}',
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${c.premiumCount}',
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${c.conversionRate.toStringAsFixed(1)}%',
                                                textAlign: TextAlign.right,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.brandTeal,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (c != cohorts.last)
                                        const Divider(
                                            height: 0, thickness: 0.5),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
              loading: () => _chartCardLoading(),
              error: (e, _) => EmptyStateCard(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Error',
                message: e.toString(),
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  /// Tile layout (vertical) for 2-column subscription KPI grid.
  Widget _buildChurnKpiTile(
    String label,
    String value,
    double change,
    bool lowerIsBetter,
    Color cardColor,
    bool isDark,
  ) {
    final isPositiveChange = change > 0;
    final changeColor = change == 0
        ? (isDark ? AppColors.secondaryLabelDark : AppColors.secondaryLabel)
        : (lowerIsBetter
            ? (isPositiveChange ? AppColors.systemRed : AppColors.systemGreen)
            : (isPositiveChange ? AppColors.systemGreen : AppColors.systemRed));

    final changeIcon = change == 0
        ? CupertinoIcons.minus
        : (isPositiveChange
            ? CupertinoIcons.arrow_up_right
            : CupertinoIcons.arrow_down_right);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: isDark
            ? null
            : Border.all(color: AppColors.separator, width: 0.5),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandTeal,
                      letterSpacing: -0.5,
                    ),
              ),
              if (change != 0) ...[
                const SizedBox(width: AppSizes.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(changeIcon, size: 13, color: changeColor),
                      const SizedBox(width: 2),
                      Text(
                        change.abs().toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: changeColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Insights Tab ───────────────────────────────────────────────────────────

  Widget _buildInsightsTab() {
    final percentilesAsync = ref.watch(netWorthPercentilesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () async => ref.invalidate(netWorthPercentilesProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Net Worth Distribution'),
            const SizedBox(height: AppSizes.sm),
            percentilesAsync.when(
              data: (percentiles) {
                if (percentiles.isEmpty) {
                  return EmptyStateCard(
                    icon: CupertinoIcons.info_circle,
                    title: 'No Percentile Data',
                    message: 'Net worth distribution data will appear once users create accounts',
                    backgroundColor: AppColors.brandTeal,
                  );
                }
                final maxValue = percentiles
                    .map((p) => p.netWorthValue)
                    .reduce((a, b) => a > b ? a : b);

                return Column(
                  children: [
                    _chartCard(
                      child: AnalyticsBarChart(
                        labels: percentiles
                            .map((p) => p.percentile)
                            .toList(),
                        values: percentiles
                            .map((p) => p.netWorthValue)
                            .toList(),
                        title: 'Net Worth by Percentile',
                        barColor: AppColors.brandTeal,
                        valuePrefix: '\$',
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...percentiles.map((p) {
                      final relativeValue =
                          maxValue > 0 ? (p.netWorthValue / maxValue) : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSizes.sm),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusCard),
                          border: isDark
                              ? null
                              : Border.all(
                                  color: AppColors.separator, width: 0.5),
                          boxShadow: AppColors.cardShadow(isDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.percentile,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${p.userCount} users',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: isDark
                                                  ? AppColors.secondaryLabelDark
                                                  : AppColors.secondaryLabel,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$')
                                      .format(p.netWorthValue),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandTeal,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                              child: LinearProgressIndicator(
                                value: relativeValue.toDouble(),
                                backgroundColor:
                                    AppColors.brandTeal.withValues(alpha: 0.10),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.brandTeal),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => _chartCardLoading(),
              error: (e, _) => EmptyStateCard(
                icon: CupertinoIcons.exclamationmark_circle,
                title: 'Error',
                message: e.toString(),
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownChart(
      List<dynamic> categories, bool isDark) {
    final top5 = categories.take(5).toList();
    final hasOthers = categories.length > 5;

    final chartLabels =
        top5.map((c) => c.categoryName as String).toList();
    final chartValues =
        top5.map((c) => c.totalAmount as double).toList();

    if (hasOthers) {
      final othersTotal = categories
          .skip(5)
          .fold<double>(0, (sum, c) => sum + (c.totalAmount as double));
      chartLabels.add('Others');
      chartValues.add(othersTotal);
    }

    return _chartCard(
      child: AnalyticsPieChart(
        labels: chartLabels,
        values: chartValues,
        title: 'Top ${hasOthers ? '5+' : '5'} Categories',
      ),
    );
  }

  Widget _buildCategoryDetailsList(
      List<dynamic> categories, bool isDark) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Column(
      children: categories.asMap().entries.map((entry) {
        final rank = entry.key + 1;
        final category = entry.value;
        final name = category.categoryName as String;
        final amount = category.totalAmount as double;
        final percentage = category.percentageOfTotal as double;
        final formattedAmount =
            NumberFormat.currency(symbol: '\$').format(amount);
        final formattedPercentage = percentage.toStringAsFixed(1);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: isDark
                ? null
                : Border.all(color: AppColors.separator, width: 0.5),
            boxShadow: AppColors.cardShadow(isDark),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandTeal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedAmount,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.secondaryLabel,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  '$formattedPercentage%',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandTeal,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AdminTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AdminTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 36,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }
}
