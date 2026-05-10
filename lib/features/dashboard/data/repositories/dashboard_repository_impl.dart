import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/error/global_error_handler.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../presentation/widgets/cash_flow_chart.dart';
import '../../presentation/widgets/net_worth_trend_chart.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      // Get current month date range
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Fetch all data in parallel
      final results = await Future.wait([
        _getNetWorth(),
        _getPreviousMonthNetWorth(),
        _getMonthlyIncome(startOfMonth, endOfMonth),
        _getMonthlyExpenses(startOfMonth, endOfMonth),
        _getMoneyHealthScore(),
        _getRecentTransactions(limit: 5),
        _getUpcomingBills(limit: 3),
      ]);

      // Create a net worth snapshot after fetching baseline (to avoid comparing against just-created snapshot)
      await createNetWorthSnapshot();

      final currentNetWorth = results[0] as double;
      final previousNetWorth = results[1] as double?;
      final monthlyIncome = results[2] as double;
      final monthlyExpenses = results[3] as double;
      final healthScore = results[4] as int;
      final recentTransactions = results[5] as List<TransactionModel>;
      final upcomingBills = results[6] as List<UpcomingBill>;

      // Calculate net worth change percentage.
      //
      // Rules:
      //  • No previous snapshot → 0 %, neutral (first-ever load).
      //  • Previous ≈ $0 → can't compute a meaningful %, show 0 %.
      //  • Current = $0 → user has no data; always show 0 % neutral so a
      //    stale snapshot from a prior session never produces a scary –100 %.
      //  • Normal case → standard period-over-period % change.
      double changePercentage = 0;
      bool isPositive;

      if (previousNetWorth == null || currentNetWorth == 0) {
        // No baseline or no current data — neutral badge.
        isPositive = currentNetWorth >= 0;
      } else {
        final base = previousNetWorth.abs();
        if (base < 0.01) {
          // Previous was ~$0: division would be meaningless.
          changePercentage = 0;
          isPositive = currentNetWorth >= 0;
        } else {
          changePercentage =
              ((currentNetWorth - previousNetWorth) / base) * 100;
          isPositive = currentNetWorth >= previousNetWorth;
        }
      }

      return DashboardStats(
        netWorth: currentNetWorth,
        netWorthChangePercentage: changePercentage.abs(),
        isNetWorthPositive: isPositive,
        monthlyIncome: monthlyIncome,
        monthlyExpenses: monthlyExpenses,
        moneyHealthScore: healthScore,
        recentTransactions:
            recentTransactions.map((model) => model.toEntity()).toList(),
        upcomingBills: upcomingBills,
      );
    } catch (e, st) {
      await GlobalErrorHandler.handleError(e, st,
          context: 'DashboardRepository.getDashboardStats');
      return DashboardStats.empty;
    }
  }

  @override
  Future<DashboardStats> refreshDashboardStats() async {
    // Same as getDashboardStats - no caching for now
    return getDashboardStats();
  }

  /// Get total net worth across all accounts
  /// Calculated as: Sum of Assets (non-credit card accounts) - Credit Card Debt
  Future<double> _getNetWorth() async {
    try {
      final result = await _supabase.rpc('calculate_true_net_worth', params: {
        'p_user_id': _supabase.auth.currentUser?.id,
      });

      return (result as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0;
    }
  }

  /// Get net worth snapshot from the start of the current month (for % comparison).
  /// Returns the first snapshot on or after the start of the month.
  /// If none exists, returns the most recent snapshot from the previous month.
  /// Returns null if no snapshots exist yet (can't compute a meaningful change).
  Future<double?> _getPreviousMonthNetWorth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // First, try to get a snapshot on or after the start of the month
      final response = await _supabase.rpc('get_net_worth_snapshots', params: {
        'p_user_id': _supabase.auth.currentUser?.id,
        'p_start_date': startOfMonth.toIso8601String().split('T')[0],
        'p_end_date': now.toIso8601String().split('T')[0],
      });

      if (response is List && response.isNotEmpty) {
        // Return the first (earliest) snapshot from this month
        return (response.first['net_worth'] as num?)?.toDouble();
      }

      // Fallback: get the most recent snapshot from the previous month
      int prevMonth = now.month - 1;
      int prevYear = now.year;
      if (prevMonth <= 0) {
        prevMonth = 12;
        prevYear = now.year - 1;
      }

      final previousMonthStart = DateTime(prevYear, prevMonth, 1);
      final previousMonthEnd = DateTime(prevYear, prevMonth + 1, 0);

      final fallbackResponse =
          await _supabase.rpc('get_net_worth_snapshots', params: {
        'p_user_id': _supabase.auth.currentUser?.id,
        'p_start_date': previousMonthStart.toIso8601String().split('T')[0],
        'p_end_date': previousMonthEnd.toIso8601String().split('T')[0],
      });

      if (fallbackResponse is List && fallbackResponse.isNotEmpty) {
        // Return the last (most recent) snapshot from the previous month
        return (fallbackResponse.last['net_worth'] as num?)?.toDouble();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get total income for a date range
  Future<double> _getMonthlyIncome(DateTime startDate, DateTime endDate) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return 0.0;
      }

      final result = await _supabase.rpc('get_total_by_type', params: {
        'p_user_id': userId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'transaction_type': 'income',
      });

      return (result as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get total expenses for a date range
  Future<double> _getMonthlyExpenses(
      DateTime startDate, DateTime endDate) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return 0.0;
      }

      final result = await _supabase.rpc('get_total_by_type', params: {
        'p_user_id': userId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'transaction_type': 'expense',
      });

      return (result as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get money health score
  Future<int> _getMoneyHealthScore() async {
    try {
      final result = await _supabase.rpc('calculate_money_health_score');
      return result as int? ?? 50;
    } catch (e) {
      return 50;
    }
  }

  /// Get recent transactions
  Future<List<TransactionModel>> _getRecentTransactions({int limit = 5}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final response = await _supabase.from('transactions').select('''
        *,
        categories(name),
        accounts!transactions_account_id_fkey(name),
        to_account:accounts!transactions_to_account_id_fkey(name)
      ''').eq('user_id', userId).order('date', ascending: false).limit(limit);

      return (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        data['category_name'] = json['categories']?['name'];
        data['account_name'] = json['accounts']?['name'];
        data['to_account_name'] = json['to_account']?['name'];
        return TransactionModel.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get upcoming bills from recurring transactions
  Future<List<UpcomingBill>> _getUpcomingBills({int limit = 3}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      final response = await _supabase
          .from('recurring_transactions')
          .select('''
            id,
            description,
            amount,
            next_occurrence,
            category_id,
            categories(name)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gte('next_occurrence', now.toIso8601String().split('T')[0])
          .lte('next_occurrence',
              thirtyDaysFromNow.toIso8601String().split('T')[0])
          .order('next_occurrence')
          .limit(limit);

      return (response as List).map((json) {
        return UpcomingBill(
          id: json['id'] as String,
          name: (json['description'] as String?) ?? 'Recurring Payment',
          amount: ((json['amount'] as num?)?.toDouble() ?? 0),
          dueDate: DateTime.parse(json['next_occurrence'] as String),
          categoryId: json['category_id'] as String?,
          categoryName: json['categories']?['name'] as String?,
        );
      }).toList();
    } catch (e) {
      // Return empty list if no recurring transactions or error
      return [];
    }
  }

  @override
  Future<List<MonthlyFlowData>> getMonthlyFlowData({int months = 6}) async {
    try {
      final now = DateTime.now();

      // Build date ranges synchronously, then fire all RPC calls in parallel.
      final ranges = <({DateTime start, DateTime end})>[];
      for (int i = months - 1; i >= 0; i--) {
        int month = now.month - i;
        int year = now.year;
        while (month <= 0) {
          month += 12;
          year -= 1;
        }
        final start = DateTime(year, month, 1);
        final end = month == 12
            ? DateTime(year + 1, 1, 0)
            : DateTime(year, month + 1, 0);
        ranges.add((start: start, end: end));
      }

      // Fire all income + expense futures simultaneously (12 RPCs → 1 round-trip batch)
      final results = await Future.wait([
        for (final r in ranges) _getMonthlyIncome(r.start, r.end),
        for (final r in ranges) _getMonthlyExpenses(r.start, r.end),
      ]);

      return [
        for (int i = 0; i < ranges.length; i++)
          MonthlyFlowData(
            month: ranges[i].start,
            income: results[i],
            expenses: results[i + ranges.length],
          ),
      ];
    } catch (e, st) {
      await GlobalErrorHandler.handleError(e, st,
          context: 'DashboardRepository.getMonthlyFlowData');
      return [];
    }
  }

  @override
  Future<List<NetWorthSnapshot>> getNetWorthSnapshots({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final response = await _supabase.rpc('get_net_worth_snapshots', params: {
        'p_user_id': _supabase.auth.currentUser?.id,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      });

      if (response == null || response is! List) {
        return [];
      }

      return response.map((row) {
        return NetWorthSnapshot(
          date: DateTime.parse(row['snapshot_date'] as String),
          netWorth: ((row['net_worth'] as num?)?.toDouble() ?? 0),
        );
      }).toList();
    } catch (e, st) {
      await GlobalErrorHandler.handleError(e, st,
          context: 'DashboardRepository.getNetWorthSnapshots');
      return [];
    }
  }

  @override
  Future<void> createNetWorthSnapshot() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('create_net_worth_snapshot', params: {
        'p_user_id': userId,
        'p_date': DateTime.now().toIso8601String().split('T')[0],
      });
    } catch (e) {
      // Silently fail
    }
  }
}
