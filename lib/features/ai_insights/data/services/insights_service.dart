import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../domain/entities/recurring_expense_pattern.dart';
import '../../domain/entities/spending_anomaly.dart';
import '../../domain/entities/merchant_insight.dart';

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

  /// Detect recurring expenses (subscriptions, regular bills)
  Future<List<RecurringExpensePattern>> detectRecurringExpenses({int daysToAnalyze = 180}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startDate = DateTime.now().subtract(Duration(days: daysToAnalyze));
      final transactions = await _supabase
          .from('transactions')
          .select('amount, description, date, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      if ((transactions as List).isEmpty) return [];

      // Group transactions by normalized merchant name
      final merchantGroups = <String, List<Map<String, dynamic>>>{};

      for (final tx in transactions) {
        final merchant = _normalizeMerchantName(tx['description'] as String? ?? 'Unknown');
        merchantGroups[merchant] ??= [];
        merchantGroups[merchant]!.add(tx);
      }

      final patterns = <RecurringExpensePattern>[];

      // Analyze each merchant group
      for (final entry in merchantGroups.entries) {
        final merchant = entry.key;
        final txs = entry.value;

        // Only consider merchants with 2+ transactions
        if (txs.length < 2) continue;

        final pattern = _analyzeRecurringPattern(merchant, txs);
        if (pattern != null) {
          patterns.add(pattern);
        }
      }

      // Sort by average amount (highest first)
      patterns.sort((a, b) => b.averageAmount.compareTo(a.averageAmount));

      return patterns;
    } catch (e) {
      return [];
    }
  }

  /// Detect spending anomalies
  Future<List<SpendingAnomaly>> detectSpendingAnomalies({int daysToAnalyze = 90}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startDate = DateTime.now().subtract(Duration(days: daysToAnalyze));
      final transactions = await _supabase
          .from('transactions')
          .select('id, amount, description, date, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      if ((transactions as List).isEmpty) return [];

      // Calculate category averages
      final categoryStats = <String, Map<String, dynamic>>{};

      for (final tx in transactions) {
        final category = tx['categories']?['name'] as String? ?? 'Uncategorized';
        final amount = (tx['amount'] as num).toDouble();

        categoryStats[category] ??= {
          'amounts': <double>[],
          'total': 0.0,
          'count': 0,
        };

        categoryStats[category]!['amounts'].add(amount);
        categoryStats[category]!['total'] += amount;
        categoryStats[category]!['count'] += 1;
      }

      // Calculate averages and detect anomalies
      final anomalies = <SpendingAnomaly>[];

      for (final tx in transactions) {
        final category = tx['categories']?['name'] as String? ?? 'Uncategorized';
        final amount = (tx['amount'] as num).toDouble();
        final stats = categoryStats[category]!;
        final average = (stats['total'] as double) / (stats['count'] as int);

        final deviation = ((amount - average) / average * 100).abs();

        // Flag transactions 2x+ the average
        if (amount > average * 2) {
          anomalies.add(SpendingAnomaly(
            id: '${tx['id']}_anomaly',
            transactionId: tx['id'] as String,
            type: AnomalyType.unusualAmount,
            severity: deviation > 300 ? AnomalySeverity.high : AnomalySeverity.medium,
            title: 'Unusual $category Spending',
            description: 'You spent \$${amount.toStringAsFixed(2)}, which is ${deviation.toStringAsFixed(0)}% higher than your average of \$${average.toStringAsFixed(2)}',
            transactionAmount: amount,
            categoryAverage: average,
            deviationPercentage: deviation,
            category: category,
            merchant: tx['description'] as String? ?? 'Unknown',
            transactionDate: DateTime.parse(tx['date'] as String),
          ));
        }
      }

      return anomalies;
    } catch (e) {
      return [];
    }
  }

  /// Analyze merchant frequency and spending
  Future<List<MerchantInsight>> analyzeMerchantFrequency({int daysToAnalyze = 90}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startDate = DateTime.now().subtract(Duration(days: daysToAnalyze));
      final transactions = await _supabase
          .from('transactions')
          .select('amount, description, date, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      if ((transactions as List).isEmpty) return [];

      // Group by merchant
      final merchantData = <String, Map<String, dynamic>>{};

      for (final tx in transactions) {
        final merchant = tx['description'] as String? ?? 'Unknown';
        final category = tx['categories']?['name'] as String? ?? 'Uncategorized';
        final amount = (tx['amount'] as num).toDouble();
        final date = DateTime.parse(tx['date'] as String);

        merchantData[merchant] ??= {
          'category': category,
          'amounts': <double>[],
          'dates': <DateTime>[],
          'total': 0.0,
        };

        merchantData[merchant]!['amounts'].add(amount);
        merchantData[merchant]!['dates'].add(date);
        merchantData[merchant]!['total'] += amount;
      }

      // Calculate category totals for percentage
      final categoryTotals = <String, double>{};
      for (final stat in merchantData.values) {
        final category = stat['category'] as String;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + (stat['total'] as double);
      }

      // Create insights
      final insights = <MerchantInsight>[];

      for (final entry in merchantData.entries) {
        final merchant = entry.key;
        final data = entry.value;
        final category = data['category'] as String;
        final amounts = data['amounts'] as List<double>;
        final dates = data['dates'] as List<DateTime>;
        final total = data['total'] as double;

        final daysDiff = DateTime.now().difference(dates.first).inDays;
        final monthlyFreq = (amounts.length / (daysDiff / 30)).toDouble();

        final categoryTotal = categoryTotals[category] ?? 1;
        final percentage = (total / categoryTotal * 100);

        insights.add(MerchantInsight(
          id: merchant.hashCode.toString(),
          merchantName: merchant,
          category: category,
          visitCount: amounts.length,
          totalSpent: total,
          averagePerVisit: total / amounts.length,
          firstTransaction: dates.first,
          lastTransaction: dates.last,
          monthlyFrequency: monthlyFreq,
          transactionDates: dates,
          percentageOfCategorySpending: percentage,
        ));
      }

      // Sort by visit count and mark top merchants
      insights.sort((a, b) => b.visitCount.compareTo(a.visitCount));
      for (int i = 0; i < 5 && i < insights.length; i++) {
        insights[i] = insights[i].copyWith(isTopMerchant: true);
      }

      return insights;
    } catch (e) {
      return [];
    }
  }

  /// Analyze weekend vs weekday spending
  Future<Map<String, dynamic>> getWeekendVsWeekdaySpending({int daysToAnalyze = 90}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startDate = DateTime.now().subtract(Duration(days: daysToAnalyze));
      final transactions = await _supabase
          .from('transactions')
          .select('amount, date, type')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      double weekdayExpense = 0;
      double weekendExpense = 0;
      int weekdayCount = 0;
      int weekendCount = 0;

      for (final tx in transactions as List) {
        if (tx['type'] != 'expense') continue;

        final date = DateTime.parse(tx['date'] as String);
        final amount = (tx['amount'] as num).toDouble();

        // weekday = 1-5 (Mon-Fri), weekend = 6-7 (Sat-Sun)
        if (date.weekday >= 1 && date.weekday <= 5) {
          weekdayExpense += amount;
          weekdayCount++;
        } else {
          weekendExpense += amount;
          weekendCount++;
        }
      }

      final weekdayAvg = weekdayCount > 0 ? weekdayExpense / weekdayCount : 0;
      final weekendAvg = weekendCount > 0 ? weekendExpense / weekendCount : 0;

      final difference = ((weekendAvg - weekdayAvg) / weekdayAvg * 100).abs();
      final isWeekendHigher = weekendAvg > weekdayAvg;

      return {
        'weekday_total': weekdayExpense,
        'weekend_total': weekendExpense,
        'weekday_average': weekdayAvg,
        'weekend_average': weekendAvg,
        'difference_percentage': difference,
        'is_weekend_higher': isWeekendHigher,
        'insight': isWeekendHigher
            ? 'Weekend spending is ${difference.toStringAsFixed(0)}% higher than weekdays'
            : 'Weekday spending is ${difference.toStringAsFixed(0)}% higher than weekends',
      };
    } catch (e) {
      return {
        'weekday_total': 0,
        'weekend_total': 0,
        'weekday_average': 0,
        'weekend_average': 0,
        'difference_percentage': 0,
        'is_weekend_higher': false,
        'insight': 'Unable to analyze patterns',
      };
    }
  }

  // Helper methods

  String _normalizeMerchantName(String name) {
    // Remove common suffixes and normalize
    var normalized = name.toLowerCase().trim();
    const suffixes = [' inc', ' ltd', ' co', ' corp', ' llc', ' store', ' shop'];
    for (final suffix in suffixes) {
      if (normalized.endsWith(suffix)) {
        normalized = normalized.substring(0, normalized.length - suffix.length).trim();
      }
    }
    return normalized;
  }

  RecurringExpensePattern? _analyzeRecurringPattern(String merchant, List<Map<String, dynamic>> transactions) {
    if (transactions.length < 2) return null;

    // Extract amounts and dates
    final amounts = <double>[];
    final dates = <DateTime>[];

    for (final tx in transactions) {
      amounts.add((tx['amount'] as num).toDouble());
      dates.add(DateTime.parse(tx['date'] as String));
    }

    // Check amount consistency (±5%)
    final avgAmount = amounts.fold<double>(0, (a, b) => a + b) / amounts.length;
    final variance = amounts.where((a) => (a - avgAmount).abs() / avgAmount <= 0.05).length;

    if (variance < amounts.length * 0.7) return null; // Less than 70% consistent

    // Detect interval pattern
    final intervals = <int>[];
    for (int i = 1; i < dates.length; i++) {
      intervals.add(dates[i].difference(dates[i - 1]).inDays);
    }

    if (intervals.isEmpty) return null;

    final avgInterval = intervals.fold<int>(0, (a, b) => a + b) ~/ intervals.length;
    final interval = _detectInterval(avgInterval);

    if (interval == RecurringInterval.unknown) return null;

    // Check for price changes
    bool isPriceIncreased = false;
    double? priceChangePercent;

    if (amounts.length >= 2) {
      final recentAvg = amounts.sublist((amounts.length / 2).toInt()).fold<double>(0, (a, b) => a + b) / (amounts.length / 2).toInt();
      final oldAvg = amounts.sublist(0, (amounts.length / 2).toInt()).fold<double>(0, (a, b) => a + b) / (amounts.length / 2).toInt();

      priceChangePercent = ((recentAvg - oldAvg) / oldAvg * 100).abs();
      isPriceIncreased = recentAvg > oldAvg && priceChangePercent > 5;
    }

    // Calculate next expected date
    final lastDate = dates.last;
    final nextExpectedDate = lastDate.add(Duration(days: avgInterval));

    final category = transactions.first['categories']?['name'] as String? ?? 'Uncategorized';

    return RecurringExpensePattern(
      id: merchant.hashCode.toString(),
      merchantName: merchant,
      averageAmount: avgAmount,
      previousAmount: amounts.length >= 2 ? amounts[amounts.length - 2] : null,
      interval: interval,
      lastOccurrence: lastDate,
      nextExpectedDate: nextExpectedDate,
      occurrenceCount: amounts.length,
      category: category,
      isPriceIncreased: isPriceIncreased,
      priceChangePercentage: priceChangePercent,
      transactionDates: dates,
    );
  }

  RecurringInterval _detectInterval(int avgDays) {
    if (avgDays >= 6 && avgDays <= 8) return RecurringInterval.weekly;
    if (avgDays >= 13 && avgDays <= 15) return RecurringInterval.biweekly;
    if (avgDays >= 28 && avgDays <= 31) return RecurringInterval.monthly;
    if (avgDays >= 88 && avgDays <= 92) return RecurringInterval.quarterly;
    if (avgDays >= 360 && avgDays <= 370) return RecurringInterval.yearly;
    return RecurringInterval.unknown;
  }
}
