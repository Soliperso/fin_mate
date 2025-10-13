import '../../domain/entities/admin_user_entity.dart';
import '../../domain/entities/system_stats_entity.dart';
import '../../domain/entities/user_growth_trend_entity.dart';
import '../../domain/entities/financial_trend_entity.dart';
import '../../domain/entities/feature_adoption_entity.dart';
import '../../domain/entities/category_breakdown_entity.dart';
import '../../domain/entities/engagement_metric_entity.dart';
import '../../domain/entities/net_worth_percentile_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

/// Implementation of admin repository
class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AdminUserEntity>> getAllUsers({
    int? limit,
    int? offset,
    String? searchQuery,
  }) async {
    return await remoteDataSource.getAllUsers(
      limit: limit,
      offset: offset,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<SystemStatsEntity> getSystemStats() async {
    return await remoteDataSource.getSystemStats();
  }

  @override
  Future<AdminUserEntity> getUserDetails(String userId) async {
    return await remoteDataSource.getUserDetails(userId);
  }

  @override
  Future<void> updateUserRole(String userId, String role) async {
    return await remoteDataSource.updateUserRole(userId, role);
  }

  // Advanced Analytics Methods

  @override
  Future<List<UserGrowthTrendEntity>> getUserGrowthTrends({
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'day',
  }) async {
    return await remoteDataSource.getUserGrowthTrends(
      startDate: startDate,
      endDate: endDate,
      granularity: granularity,
    );
  }

  @override
  Future<List<FinancialTrendEntity>> getFinancialTrends({
    required DateTime startDate,
    required DateTime endDate,
    String granularity = 'day',
  }) async {
    return await remoteDataSource.getFinancialTrends(
      startDate: startDate,
      endDate: endDate,
      granularity: granularity,
    );
  }

  @override
  Future<List<FeatureAdoptionEntity>> getFeatureAdoptionStats() async {
    return await remoteDataSource.getFeatureAdoptionStats();
  }

  @override
  Future<List<CategoryBreakdownEntity>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await remoteDataSource.getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<EngagementMetricEntity>> getUserEngagementMetrics({
    int periodDays = 30,
  }) async {
    return await remoteDataSource.getUserEngagementMetrics(
      periodDays: periodDays,
    );
  }

  @override
  Future<List<NetWorthPercentileEntity>> getNetWorthPercentiles() async {
    return await remoteDataSource.getNetWorthPercentiles();
  }
}
