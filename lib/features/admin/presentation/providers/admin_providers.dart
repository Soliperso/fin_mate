import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/admin_user_entity.dart';
import '../../domain/entities/system_stats_entity.dart';
import '../../domain/entities/user_growth_trend_entity.dart';
import '../../domain/entities/financial_trend_entity.dart';
import '../../domain/entities/feature_adoption_entity.dart';
import '../../domain/entities/category_breakdown_entity.dart';
import '../../domain/entities/engagement_metric_entity.dart';
import '../../domain/entities/net_worth_percentile_entity.dart';
import '../../domain/repositories/admin_repository.dart';

// ============================================================================
// Data Source Provider
// ============================================================================

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSource();
});

// ============================================================================
// Repository Provider
// ============================================================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(
    remoteDataSource: ref.read(adminRemoteDataSourceProvider),
  );
});

// ============================================================================
// Users List Provider
// ============================================================================

final usersListProvider = FutureProvider.family<List<AdminUserEntity>, UsersFilter>(
  (ref, filter) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getAllUsers(
      limit: filter.limit,
      offset: filter.offset,
      searchQuery: filter.searchQuery,
    );
  },
);

class UsersFilter {
  final int limit;
  final int offset;
  final String? searchQuery;

  const UsersFilter({
    this.limit = 50,
    this.offset = 0,
    this.searchQuery,
  });

  UsersFilter copyWith({
    int? limit,
    int? offset,
    String? searchQuery,
  }) {
    return UsersFilter(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ============================================================================
// System Stats Provider
// ============================================================================

final systemStatsProvider = FutureProvider<SystemStatsEntity>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSystemStats();
});

// ============================================================================
// User Details Provider
// ============================================================================

final userDetailsProvider = FutureProvider.family<AdminUserEntity, String>(
  (ref, userId) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getUserDetails(userId);
  },
);

// ============================================================================
// Advanced Analytics Providers
// ============================================================================

/// Date range filter for analytics
class AnalyticsDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String granularity; // 'day', 'week', 'month'

  const AnalyticsDateRange({
    required this.startDate,
    required this.endDate,
    this.granularity = 'day',
  });

  /// Last 7 days
  factory AnalyticsDateRange.last7Days() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
      granularity: 'day',
    );
  }

  /// Last 30 days
  factory AnalyticsDateRange.last30Days() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      granularity: 'day',
    );
  }

  /// Last 90 days
  factory AnalyticsDateRange.last90Days() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: now.subtract(const Duration(days: 90)),
      endDate: now,
      granularity: 'week',
    );
  }

  /// Last 12 months
  factory AnalyticsDateRange.last12Months() {
    final now = DateTime.now();
    return AnalyticsDateRange(
      startDate: DateTime(now.year - 1, now.month, now.day),
      endDate: now,
      granularity: 'month',
    );
  }

  AnalyticsDateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? granularity,
  }) {
    return AnalyticsDateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      granularity: granularity ?? this.granularity,
    );
  }
}

/// User Growth Trends Provider
final userGrowthTrendsProvider =
    FutureProvider.family<List<UserGrowthTrendEntity>, AnalyticsDateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getUserGrowthTrends(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
      granularity: dateRange.granularity,
    );
  },
);

/// Financial Trends Provider
final financialTrendsProvider =
    FutureProvider.family<List<FinancialTrendEntity>, AnalyticsDateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getFinancialTrends(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
      granularity: dateRange.granularity,
    );
  },
);

/// Feature Adoption Stats Provider
final featureAdoptionStatsProvider =
    FutureProvider<List<FeatureAdoptionEntity>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getFeatureAdoptionStats();
});

/// Category Breakdown Provider
final categoryBreakdownProvider =
    FutureProvider.family<List<CategoryBreakdownEntity>, AnalyticsDateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getCategoryBreakdown(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    );
  },
);

/// User Engagement Metrics Provider
final engagementMetricsProvider =
    FutureProvider.family<List<EngagementMetricEntity>, int>(
  (ref, periodDays) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getUserEngagementMetrics(
      periodDays: periodDays,
    );
  },
);

/// Net Worth Percentiles Provider
final netWorthPercentilesProvider =
    FutureProvider<List<NetWorthPercentileEntity>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getNetWorthPercentiles();
});
