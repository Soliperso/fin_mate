import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
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

      final currentNetWorth = results[0] as double;
      final previousNetWorth = results[1] as double;
      final monthlyIncome = results[2] as double;
      final monthlyExpenses = results[3] as double;
      final healthScore = results[4] as int;
      final recentTransactions = results[5] as List<TransactionModel>;
      final upcomingBills = results[6] as List<UpcomingBill>;

      // Calculate net worth change percentage
      double changePercentage = 0;
      if (previousNetWorth > 0) {
        changePercentage = ((currentNetWorth - previousNetWorth) / previousNetWorth) * 100;
      } else if (currentNetWorth > 0) {
        changePercentage = 100;
      }

      return DashboardStats(
        netWorth: currentNetWorth,
        netWorthChangePercentage: changePercentage.abs(),
        isNetWorthPositive: changePercentage >= 0,
        monthlyIncome: monthlyIncome,
        monthlyExpenses: monthlyExpenses,
        moneyHealthScore: healthScore,
        recentTransactions: recentTransactions.map((model) => model.toEntity()).toList(),
        upcomingBills: upcomingBills,
      );
    } catch (e) {
      // Return empty stats on error
      return DashboardStats.empty;
    }
  }

  @override
  Future<DashboardStats> refreshDashboardStats() async {
    // Same as getDashboardStats - no caching for now
    return getDashboardStats();
  }

  /// Get total net worth across all accounts
  Future<double> _getNetWorth() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return 0;
      }

      final response = await _supabase
          .from('accounts')
          .select('balance')
          .eq('user_id', userId)
          .eq('is_active', true);

      if (response.isEmpty) {
        return 0;
      }

      return (response as List).fold<double>(
        0,
        (sum, account) => sum + ((account['balance'] as num?)?.toDouble() ?? 0),
      );
    } catch (e) {
      return 0;
    }
  }

  /// Get net worth from previous month (for comparison)
  Future<double> _getPreviousMonthNetWorth() async {
    // For now, return current net worth
    // TODO: Implement historical account balance tracking
    return _getNetWorth();
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
  Future<double> _getMonthlyExpenses(DateTime startDate, DateTime endDate) async {
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
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return 50;
      }

      final result = await _supabase.rpc('calculate_money_health_score', params: {
        'p_user_id': userId,
      });
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
      ''')
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(limit);

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
          .lte('next_occurrence', thirtyDaysFromNow.toIso8601String().split('T')[0])
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
      final List<MonthlyFlowData> flowData = [];

      // Get data for each of the last N months
      for (int i = months - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final startDate = DateTime(monthDate.year, monthDate.month, 1);
        final endDate = DateTime(monthDate.year, monthDate.month + 1, 0);

        // Get income for this month
        final income = await _getMonthlyIncome(startDate, endDate);

        // Get expenses for this month
        final expenses = await _getMonthlyExpenses(startDate, endDate);

        flowData.add(MonthlyFlowData(
          month: monthDate,
          income: income,
          expenses: expenses,
        ));
      }

      return flowData;
    } catch (e) {
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
    } catch (e) {
      // Return empty list on error
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
