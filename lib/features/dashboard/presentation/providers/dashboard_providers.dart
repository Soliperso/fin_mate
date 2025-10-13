import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../widgets/cash_flow_chart.dart';
import '../widgets/net_worth_trend_chart.dart';

/// Provider for dashboard repository
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl();
});

/// Provider for dashboard stats
///
/// This provider fetches dashboard statistics from the repository.
/// It automatically handles loading, error, and data states.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboardStats();
});

/// Provider for manual refresh of dashboard stats
///
/// Use this provider when you need to manually refresh the dashboard,
/// such as in pull-to-refresh scenarios.
final refreshDashboardProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.refreshDashboardStats();
});

/// State notifier for dashboard management
class DashboardNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  /// Load dashboard stats
  Future<void> loadDashboard() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getDashboardStats();
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh dashboard stats
  Future<void> refresh() async {
    try {
      final stats = await _repository.refreshDashboardStats();
      state = AsyncValue.data(stats);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for dashboard notifier
final dashboardNotifierProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repository);
});

/// Provider for monthly cash flow data
final monthlyFlowDataProvider = FutureProvider.autoDispose<List<MonthlyFlowData>>((ref) async {
  // Watch the dashboard state to trigger refresh when dashboard updates
  ref.watch(dashboardNotifierProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getMonthlyFlowData(months: 6);
});

/// Provider for net worth snapshots
final netWorthSnapshotsProvider = FutureProvider.autoDispose<List<NetWorthSnapshot>>((ref) async {
  // Watch the dashboard state to trigger refresh when dashboard updates
  ref.watch(dashboardNotifierProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getNetWorthSnapshots(days: 30);
});
