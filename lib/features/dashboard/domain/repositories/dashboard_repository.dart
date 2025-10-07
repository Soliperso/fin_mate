import '../entities/dashboard_stats.dart';
import '../../presentation/widgets/cash_flow_chart.dart';
import '../../presentation/widgets/net_worth_trend_chart.dart';

/// Repository interface for dashboard data
abstract class DashboardRepository {
  /// Get comprehensive dashboard statistics
  ///
  /// Returns aggregated data including:
  /// - Net worth across all accounts
  /// - Monthly income and expenses
  /// - Money health score
  /// - Recent transactions
  /// - Upcoming bills
  Future<DashboardStats> getDashboardStats();

  /// Refresh all dashboard data
  Future<DashboardStats> refreshDashboardStats();

  /// Get monthly cash flow data for trend chart
  ///
  /// Returns income and expenses for each month in the specified range
  Future<List<MonthlyFlowData>> getMonthlyFlowData({
    int months = 6,
  });

  /// Get net worth snapshots for trend chart
  ///
  /// Returns historical net worth data points
  Future<List<NetWorthSnapshot>> getNetWorthSnapshots({
    int days = 30,
  });

  /// Create a net worth snapshot for today
  Future<void> createNetWorthSnapshot();
}
