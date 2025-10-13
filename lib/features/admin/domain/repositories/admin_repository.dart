import '../entities/admin_user_entity.dart';
import '../entities/system_stats_entity.dart';
import '../entities/user_growth_trend_entity.dart';
import '../entities/financial_trend_entity.dart';
import '../entities/feature_adoption_entity.dart';
import '../entities/category_breakdown_entity.dart';
import '../entities/engagement_metric_entity.dart';
import '../entities/net_worth_percentile_entity.dart';

/// Repository interface for admin operations
abstract class AdminRepository {
  /// Get all users with statistics
  Future<List<AdminUserEntity>> getAllUsers({
    int? limit,
    int? offset,
    String? searchQuery,
  });

  /// Get system-wide statistics
  Future<SystemStatsEntity> getSystemStats();

  /// Get user details by ID
  Future<AdminUserEntity> getUserDetails(String userId);

  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, String role);

  // Advanced Analytics Methods

  /// Get user growth trends over time
  Future<List<UserGrowthTrendEntity>> getUserGrowthTrends({
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'day',
  });

  /// Get financial trends over time
  Future<List<FinancialTrendEntity>> getFinancialTrends({
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'day',
  });

  /// Get feature adoption statistics
  Future<List<FeatureAdoptionEntity>> getFeatureAdoptionStats();

  /// Get spending breakdown by category
  Future<List<CategoryBreakdownEntity>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get user engagement metrics
  Future<List<EngagementMetricEntity>> getUserEngagementMetrics({
    int periodDays = 30,
  });

  /// Get net worth distribution percentiles
  Future<List<NetWorthPercentileEntity>> getNetWorthPercentiles();
}
