import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';

class InsightsService {
  final SupabaseClient _supabase;

  InsightsService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Analyze spending patterns from transactions
  Future<Map<String, dynamic>> analyzeSpendingPatterns() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get last 90 days of transactions
      final startDate = DateTime.now().subtract(const Duration(days: 90));
      final transactions = await _supabase
          .from('transactions')
          .select('*, categories(name)')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      return _calculateSpendingPatterns(transactions as List);
    } catch (e) {
      throw Exception('Failed to analyze spending patterns: $e');
    }
  }

  /// Get category breakdown for spending
  Future<List<Map<String, dynamic>>> getCategoryBreakdown({int days = 30}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startDate = DateTime.now().subtract(Duration(days: days));

      final result = await _supabase.rpc('get_category_spending', params: {
        'user_id_param': userId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': DateTime.now().toIso8601String().split('T')[0],
      });

      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      // Fallback to manual calculation if RPC doesn't exist
      return _getCategoryBreakdownFallback(days);
    }
  }

  /// Generate cashflow forecast for next 3-6 months
  Future<List<Map<String, dynamic>>> generateCashflowForecast({int months = 3}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get historical data (last 6 months)
      final historicalData = await _getHistoricalCashflow(6);

      // Calculate averages and trends
      final forecast = _calculateForecast(historicalData, months);

      return forecast;
    } catch (e) {
      throw Exception('Failed to generate forecast: $e');
    }
  }

  /// Get spending insights and recommendations
  Future<List<Map<String, dynamic>>> getSpendingInsights() async {
    try {
      final patterns = await analyzeSpendingPatterns();
      final breakdown = await getCategoryBreakdown(days: 30);

      final insights = <Map<String, dynamic>>[];

      // Insight 1: Top spending category
      if (breakdown.isNotEmpty) {
        final topCategory = breakdown.first;
        insights.add({
          'type': 'top_spending',
          'title': 'Top Spending Category',
          'message': 'You spent \$${topCategory['total_amount']?.toStringAsFixed(2)} on ${topCategory['category_name']} this month',
          'icon': 'trending_up',
          'color': 'warning',
        });
      }

      // Insight 2: Spending trend
      final avgDaily = patterns['average_daily_spending'] as double? ?? 0;
      final trend = patterns['spending_trend'] as String? ?? 'stable';

      if (trend == 'increasing') {
        insights.add({
          'type': 'spending_trend',
          'title': 'Spending Increasing',
          'message': 'Your daily spending has increased. Average: \$${avgDaily.toStringAsFixed(2)}/day',
          'icon': 'warning',
          'color': 'error',
        });
      } else if (trend == 'decreasing') {
        insights.add({
          'type': 'spending_trend',
          'title': 'Great Progress!',
          'message': 'Your spending is decreasing. Keep it up!',
          'icon': 'check_circle',
          'color': 'success',
        });
      }

      // Insight 3: Unusual spending
      final unusualCategories = patterns['unusual_spending'] as List? ?? [];
      if (unusualCategories.isNotEmpty) {
        insights.add({
          'type': 'unusual_spending',
          'title': 'Unusual Activity',
          'message': 'Higher than usual spending detected in ${unusualCategories.length} categories',
          'icon': 'info',
          'color': 'info',
        });
      }

      // Insight 4: Savings opportunity
      final savingsOpportunity = _calculateSavingsOpportunity(breakdown);
      if (savingsOpportunity > 0) {
        insights.add({
          'type': 'savings_opportunity',
          'title': 'Savings Opportunity',
          'message': 'You could save up to \$${savingsOpportunity.toStringAsFixed(2)} by reducing non-essential spending',
          'icon': 'savings',
          'color': 'success',
        });
      }

      return insights;
    } catch (e) {
      throw Exception('Failed to get spending insights: $e');
    }
  }

  // Private helper methods

  Map<String, dynamic> _calculateSpendingPatterns(List transactions) {
    if (transactions.isEmpty) {
      return {
        'average_daily_spending': 0.0,
        'spending_trend': 'stable',
        'unusual_spending': [],
        'total_spending': 0.0,
      };
    }

    double totalSpending = 0;
    final categorySpending = <String, double>{};

    for (final tx in transactions) {
      if (tx['type'] == 'expense') {
        final amount = (tx['amount'] as num).toDouble();
        totalSpending += amount;

        final category = tx['categories']?['name'] as String? ?? 'Uncategorized';
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }
    }

    final avgDaily = totalSpending / 90;

    // Determine trend (simplified)
    final recentTotal = _calculateRecentSpending(transactions, 30);
    final olderTotal = _calculateRecentSpending(transactions.skip(30).toList(), 30);

    String trend = 'stable';
    if (recentTotal > olderTotal * 1.1) {
      trend = 'increasing';
    } else if (recentTotal < olderTotal * 0.9) {
      trend = 'decreasing';
    }

    return {
      'average_daily_spending': avgDaily,
      'spending_trend': trend,
      'unusual_spending': _findUnusualSpending(categorySpending),
      'total_spending': totalSpending,
      'category_breakdown': categorySpending,
    };
  }

  double _calculateRecentSpending(List transactions, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    double total = 0;

    for (final tx in transactions) {
      final date = DateTime.parse(tx['date'] as String);
      if (date.isAfter(cutoff) && tx['type'] == 'expense') {
        total += (tx['amount'] as num).toDouble();
      }
    }

    return total;
  }

  List<String> _findUnusualSpending(Map<String, double> categorySpending) {
    // Simplified: categories with spending > 30% of total
    final total = categorySpending.values.fold(0.0, (a, b) => a + b);
    final unusual = <String>[];

    categorySpending.forEach((category, amount) {
      if (amount > total * 0.3) {
        unusual.add(category);
      }
    });

    return unusual;
  }

  Future<List<Map<String, dynamic>>> _getCategoryBreakdownFallback(int days) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final startDate = DateTime.now().subtract(Duration(days: days));
    final transactions = await _supabase
        .from('transactions')
        .select('*, categories(name)')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String().split('T')[0]);

    final categoryTotals = <String, double>{};

    for (final tx in transactions as List) {
      final category = tx['categories']?['name'] as String? ?? 'Uncategorized';
      final amount = (tx['amount'] as num).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    final result = categoryTotals.entries
        .map((e) => {
              'category_name': e.key,
              'total_amount': e.value,
            })
        .toList()
      ..sort((a, b) => (b['total_amount'] as double).compareTo(a['total_amount'] as double));

    return result;
  }

  Future<List<Map<String, dynamic>>> _getHistoricalCashflow(int months) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final startDate = DateTime.now().subtract(Duration(days: months * 30));
    final transactions = await _supabase
        .from('transactions')
        .select('*')
        .eq('user_id', userId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .order('date', ascending: true);

    // Group by month
    final monthlyData = <String, Map<String, double>>{};

    for (final tx in transactions as List) {
      final date = DateTime.parse(tx['date'] as String);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      monthlyData[monthKey] ??= {'income': 0, 'expense': 0};

      final amount = (tx['amount'] as num).toDouble();
      if (tx['type'] == 'income') {
        monthlyData[monthKey]!['income'] = monthlyData[monthKey]!['income']! + amount;
      } else {
        monthlyData[monthKey]!['expense'] = monthlyData[monthKey]!['expense']! + amount;
      }
    }

    return monthlyData.entries
        .map((e) => {
              'month': e.key,
              'income': e.value['income'],
              'expense': e.value['expense'],
              'net': (e.value['income']! - e.value['expense']!),
            })
        .toList();
  }

  List<Map<String, dynamic>> _calculateForecast(List<Map<String, dynamic>> historical, int months) {
    if (historical.isEmpty) return [];

    // Calculate averages
    double avgIncome = 0;
    double avgExpense = 0;

    for (final month in historical) {
      avgIncome += month['income'] as double;
      avgExpense += month['expense'] as double;
    }

    avgIncome /= historical.length;
    avgExpense /= historical.length;

    // Generate forecast
    final forecast = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 1; i <= months; i++) {
      final forecastDate = DateTime(now.year, now.month + i, 1);
      final monthKey = '${forecastDate.year}-${forecastDate.month.toString().padLeft(2, '0')}';

      // Add some variance (±10%)
      final incomeVariance = (avgIncome * 0.1 * (i % 2 == 0 ? 1 : -1));
      final expenseVariance = (avgExpense * 0.1 * (i % 2 == 0 ? -1 : 1));

      forecast.add({
        'month': monthKey,
        'income': avgIncome + incomeVariance,
        'expense': avgExpense + expenseVariance,
        'net': (avgIncome + incomeVariance) - (avgExpense + expenseVariance),
        'is_forecast': true,
      });
    }

    return forecast;
  }

  double _calculateSavingsOpportunity(List<Map<String, dynamic>> breakdown) {
    // Categories considered non-essential
    const nonEssential = ['Entertainment', 'Shopping', 'Dining', 'Other'];

    double opportunity = 0;
    for (final category in breakdown) {
      if (nonEssential.contains(category['category_name'])) {
        opportunity += (category['total_amount'] as double) * 0.2; // 20% reduction potential
      }
    }

    return opportunity;
  }

  /// Get proactive alerts and notifications
  Future<List<Map<String, dynamic>>> getProactiveAlerts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final alerts = <Map<String, dynamic>>[];

      // Check for upcoming bills (next 7 days)
      final upcomingBills = await _getUpcomingBills(userId, 7);
      if (upcomingBills.isNotEmpty) {
        alerts.add({
          'type': 'bill_reminder',
          'severity': 'info',
          'title': 'Upcoming Bills',
          'message': 'You have ${upcomingBills.length} bills due in the next 7 days',
          'count': upcomingBills.length,
        });
      }

      // Check for spending increases
      final patterns = await analyzeSpendingPatterns();
      final trend = patterns['spending_trend'] as String;
      if (trend == 'increasing') {
        final avgDaily = patterns['average_daily_spending'] as double;
        alerts.add({
          'type': 'spending_increase',
          'severity': 'warning',
          'title': 'Spending Trending Up',
          'message': 'Your daily spending has increased to \$${avgDaily.toStringAsFixed(2)}/day',
        });
      }

      return alerts;
    } catch (e) {
      return [];
    }
  }

  /// Get upcoming bills
  Future<List<Map<String, dynamic>>> _getUpcomingBills(String userId, int days) async {
    final endDate = DateTime.now().add(Duration(days: days));
    final bills = await _supabase
        .from('transactions')
        .select('description, amount, date')
        .eq('user_id', userId)
        .eq('is_recurring', true)
        .eq('type', 'expense')
        .gte('date', DateTime.now().toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    return List<Map<String, dynamic>>.from(bills as List);
  }

  /// Detect subscription changes
  Future<List<Map<String, dynamic>>> detectSubscriptionChanges() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get recurring transactions from last 2 months
      final twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));
      final recurring = await _supabase
          .from('transactions')
          .select('description, amount, date')
          .eq('user_id', userId)
          .eq('is_recurring', true)
          .gte('date', twoMonthsAgo.toIso8601String().split('T')[0]);

      // Group by description and check for amount changes
      final subscriptionMap = <String, List<double>>{};
      for (final tx in recurring as List) {
        final desc = tx['description'] as String;
        final amount = (tx['amount'] as num).toDouble();
        subscriptionMap[desc] ??= [];
        subscriptionMap[desc]!.add(amount);
      }

      final changes = <Map<String, dynamic>>[];
      subscriptionMap.forEach((desc, amounts) {
        if (amounts.length > 1) {
          final firstAmount = amounts.first;
          final lastAmount = amounts.last;
          if ((lastAmount - firstAmount).abs() > 0.01) {
            changes.add({
              'description': desc,
              'old_amount': firstAmount,
              'new_amount': lastAmount,
              'change': lastAmount - firstAmount,
            });
          }
        }
      });

      return changes;
    } catch (e) {
      return [];
    }
  }
}
