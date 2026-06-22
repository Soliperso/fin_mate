import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
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
import '../../domain/entities/churn_metric_entity.dart';
import '../../domain/entities/subscription_cohort_entity.dart';
import '../../domain/entities/subscription_timeline_entity.dart';
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
// Users List Provider (Real-time)
// ============================================================================

final usersListProvider =
    StreamProvider.autoDispose.family<List<AdminUserEntity>, UsersFilter>(
  (ref, filter) async* {
    final repository = ref.watch(adminRepositoryProvider);
    final changeController = StreamController<void>.broadcast();
    late RealtimeChannel channel;

    try {
      // Initial fetch
      yield await repository.getAllUsers(
        limit: filter.limit,
        offset: filter.offset,
        searchQuery: filter.searchQuery,
      );

      // Set up real-time listener on user_profiles changes
      channel = supabase
          .channel('user_profiles:${filter.hashCode}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'user_profiles',
            callback: (_) => changeController.add(null),
          )
          .subscribe();

      // Refetch when changes detected
      yield* changeController.stream.asyncMap((_) async {
        return await repository.getAllUsers(
          limit: filter.limit,
          offset: filter.offset,
          searchQuery: filter.searchQuery,
        );
      });
    } finally {
      await changeController.close();
      await supabase.removeChannel(channel);
    }
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsersFilter &&
          runtimeType == other.runtimeType &&
          limit == other.limit &&
          offset == other.offset &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(limit, offset, searchQuery);
}

// ============================================================================
// Subscription Overview Provider (admin dashboard)
// ============================================================================

class SubscriptionOverview {
  final int activeSubscribers;
  final int trialUsers;
  final int annualSubscribers;
  final int monthlySubscribers;
  final int estimatedMrrCents;

  const SubscriptionOverview({
    required this.activeSubscribers,
    required this.trialUsers,
    required this.annualSubscribers,
    required this.monthlySubscribers,
    required this.estimatedMrrCents,
  });

  double get estimatedMrrUsd => estimatedMrrCents / 100.0;
}

final subscriptionOverviewProvider =
    FutureProvider.autoDispose<SubscriptionOverview>((ref) async {
  final ds = ref.watch(adminRemoteDataSourceProvider);
  final raw = await ds.getSubscriptionOverview();
  return SubscriptionOverview(
    activeSubscribers: raw['active_subscribers'] ?? 0,
    trialUsers: raw['trial_users'] ?? 0,
    annualSubscribers: raw['annual_subscribers'] ?? 0,
    monthlySubscribers: raw['monthly_subscribers'] ?? 0,
    estimatedMrrCents: raw['estimated_mrr_cents'] ?? 0,
  );
});

// ============================================================================
// System Stats Provider (Real-time)
// ============================================================================

final systemStatsProvider =
    StreamProvider.autoDispose<SystemStatsEntity>((ref) async* {
  final repository = ref.watch(adminRepositoryProvider);
  final changeController = StreamController<void>.broadcast();
  late RealtimeChannel channel;

  try {
    // Initial fetch
    yield await repository.getSystemStats();

    // Set up real-time listener on all tables that contribute to system stats
    channel = supabase
        .channel('admin_system_stats')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_profiles',
          callback: (_) => changeController.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          callback: (_) => changeController.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'accounts',
          callback: (_) => changeController.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'budgets',
          callback: (_) => changeController.add(null),
        )
        .subscribe();

    // Refetch stats when changes detected
    yield* changeController.stream.asyncMap((_) async {
      return await repository.getSystemStats();
    });
  } finally {
    await changeController.close();
    await supabase.removeChannel(channel);
  }
});

// ============================================================================
// User Details Provider
// ============================================================================

final userDetailsProvider =
    FutureProvider.autoDispose.family<AdminUserEntity, String>(
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
final userGrowthTrendsProvider = FutureProvider.autoDispose
    .family<List<UserGrowthTrendEntity>, AnalyticsDateRange>(
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
final financialTrendsProvider = FutureProvider.autoDispose
    .family<List<FinancialTrendEntity>, AnalyticsDateRange>(
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
    FutureProvider.autoDispose<List<FeatureAdoptionEntity>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getFeatureAdoptionStats();
});

/// Category Breakdown Provider
final categoryBreakdownProvider = FutureProvider.autoDispose
    .family<List<CategoryBreakdownEntity>, AnalyticsDateRange>(
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
    FutureProvider.autoDispose.family<List<EngagementMetricEntity>, int>(
  (ref, periodDays) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getUserEngagementMetrics(
      periodDays: periodDays,
    );
  },
);

/// Net Worth Percentiles Provider
final netWorthPercentilesProvider =
    FutureProvider.autoDispose<List<NetWorthPercentileEntity>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getNetWorthPercentiles();
});

/// Churn Metrics Provider
final churnMetricsProvider = FutureProvider.autoDispose
    .family<List<ChurnMetricEntity>, AnalyticsDateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getChurnMetrics(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    );
  },
);

/// Subscription Cohorts Provider
final subscriptionCohortsProvider =
    FutureProvider.autoDispose<List<SubscriptionCohortEntity>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSubscriptionCohorts();
});

/// Subscription Timeline Provider
final subscriptionTimelineProvider = FutureProvider.autoDispose
    .family<List<SubscriptionTimelineEntity>, AnalyticsDateRange>(
  (ref, dateRange) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getSubscriptionTimeline(
      startDate: dateRange.startDate,
      endDate: dateRange.endDate,
    );
  },
);

// ============================================================================
// Admin Actions Providers
// ============================================================================

/// Reset user password provider
final resetUserPasswordProvider =
    FutureProvider.autoDispose.family<void, String>((ref, email) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.resetUserPassword(email);
});

/// Disable user account provider
final disableUserAccountProvider =
    FutureProvider.autoDispose.family<void, String>((ref, userId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.disableUserAccount(userId);
});

/// Enable user account provider
final enableUserAccountProvider =
    FutureProvider.autoDispose.family<void, String>((ref, userId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.enableUserAccount(userId);
});

/// Get user audit log provider
final userAuditLogProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, userId) async {
    final repository = ref.watch(adminRepositoryProvider);
    return await repository.getUserAuditLog(userId);
  },
);

/// Update user role provider
final updateUserRoleProvider = FutureProvider.autoDispose
    .family<void, ({String userId, String role})>((ref, args) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.updateUserRole(args.userId, args.role);
});

/// Get system-wide audit log provider
final systemAuditLogProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSystemAuditLog();
});

// ============================================================================
// Default Categories Provider
// ============================================================================

final defaultCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRemoteDataSourceProvider).getDefaultCategories();
});

// ============================================================================
// Feature Flags Provider
// ============================================================================

final featureFlagsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRemoteDataSourceProvider).getFeatureFlags();
});

// ============================================================================
// Email Templates Provider
// ============================================================================

final emailTemplatesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRemoteDataSourceProvider).getEmailTemplates();
});
