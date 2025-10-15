import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../../domain/entities/balance_forecast.dart';

class BalanceForecastService {
  final SupabaseClient _supabase;

  // Thresholds for balance status
  static const double healthyThreshold = 500.0;
  static const double warningThreshold = 100.0;

  BalanceForecastService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Generate 30-day balance forecast
  Future<BalanceForecast> generate30DayForecast() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');


      // Get current total balance across all accounts
      final currentBalance = await _getCurrentBalance(userId);

      // Get historical daily spending average (last 90 days)
      final avgDailySpending = await _getAverageDailySpending(userId);

      // Get scheduled transactions (recurring + future one-time)
      final scheduledTransactions = await _getScheduledTransactions(userId);

      // Generate daily forecasts for next 30 days
      final dailyForecasts = _generateDailyForecasts(
        currentBalance,
        avgDailySpending,
        scheduledTransactions,
      );

      // Calculate safe to spend amount
      final safeToSpend = _calculateSafeToSpend(
        currentBalance,
        dailyForecasts,
      );

      // Generate warnings for low balance days
      final warnings = _generateWarnings(dailyForecasts);

      return BalanceForecast(
        currentBalance: currentBalance,
        safeToSpend: safeToSpend,
        dailyForecasts: dailyForecasts,
        generatedAt: DateTime.now(),
        warnings: warnings,
      );
    } catch (e) {
      throw Exception('Failed to generate forecast: $e');
    }
  }

  /// Get total current balance across all active accounts
  Future<double> _getCurrentBalance(String userId) async {
    try {
      final accounts = await _supabase
          .from('accounts')
          .select('balance')
          .eq('user_id', userId)
          .eq('is_active', true);

      double total = 0;
      for (final account in accounts as List) {
        total += (account['balance'] as num).toDouble();
      }

      return total;
    } catch (e) {
      // Return 0 if no accounts found or error occurs
      return 0.0;
    }
  }

  /// Calculate average daily spending from last 90 days
  Future<double> _getAverageDailySpending(String userId) async {
    final startDate = DateTime.now().subtract(const Duration(days: 90));
    final transactions = await _supabase
        .from('transactions')
        .select('amount, type')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String().split('T')[0]);

    if ((transactions as List).isEmpty) return 0;

    double totalSpending = 0;
    for (final tx in transactions) {
      totalSpending += (tx['amount'] as num).toDouble();
    }

    return totalSpending / 90;
  }

  /// Get scheduled transactions for next 30 days
  Future<List<Map<String, dynamic>>> _getScheduledTransactions(String userId) async {
    try {
      final endDate = DateTime.now().add(const Duration(days: 30));
      final scheduledTxs = <Map<String, dynamic>>[];

      // Get upcoming one-time transactions (future dated)
      try {
        final futureTransactions = await _supabase
            .from('transactions')
            .select('date, amount, type, description')
            .eq('user_id', userId)
            .gte('date', DateTime.now().toIso8601String().split('T')[0])
            .lte('date', endDate.toIso8601String().split('T')[0]);

        scheduledTxs.addAll((futureTransactions as List).cast<Map<String, dynamic>>());
      } catch (e) {
        // Silently ignore if future transactions not available
      }

      // Get recurring transactions from recurring_transactions table
      try {
        final recurringTxs = await _supabase
            .from('recurring_transactions')
            .select('amount, type, description, frequency, next_occurrence')
            .eq('user_id', userId)
            .eq('is_active', true)
            .lte('next_occurrence', endDate.toIso8601String().split('T')[0]);

        for (final recurring in recurringTxs as List) {
          final occurrences = _calculateRecurringOccurrences(
            recurring as Map<String, dynamic>,
            30,
          );
          scheduledTxs.addAll(occurrences);
        }
      } catch (e) {
        // Silently ignore if recurring transactions not available
      }

      return scheduledTxs;
    } catch (e) {
      return [];
    }
  }

  /// Calculate next occurrences of a recurring transaction
  List<Map<String, dynamic>> _calculateRecurringOccurrences(
    Map<String, dynamic> recurring,
    int days,
  ) {
    try {
      final occurrences = <Map<String, dynamic>>[];
      final frequency = recurring['frequency'] as String?;
      final nextOccurrence = recurring['next_occurrence'] as String?;

      if (frequency == null || nextOccurrence == null) return [];

      DateTime nextDate = DateTime.parse(nextOccurrence);
      final amount = (recurring['amount'] as num).toDouble();
      final type = recurring['type'] as String;
      final description = recurring['description'] as String? ?? 'Recurring transaction';
      final endDate = DateTime.now().add(Duration(days: days));

      while (nextDate.isBefore(endDate)) {
        occurrences.add({
          'date': nextDate.toIso8601String().split('T')[0],
          'amount': amount,
          'type': type,
          'description': description,
        });

        nextDate = _calculateNextOccurrence(nextDate, frequency);
      }

      return occurrences;
    } catch (e) {
      return [];
    }
  }

  /// Calculate next occurrence date based on frequency
  DateTime _calculateNextOccurrence(DateTime from, String? frequency) {
    switch (frequency) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return from.add(const Duration(days: 30)); // Default to monthly
    }
  }

  /// Generate daily balance forecasts
  List<DailyForecast> _generateDailyForecasts(
    double startingBalance,
    double avgDailySpending,
    List<Map<String, dynamic>> scheduledTransactions,
  ) {
    final forecasts = <DailyForecast>[];
    double runningBalance = startingBalance;

    for (int i = 0; i < 30; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];

      // Get scheduled transactions for this day
      final dayTransactions = scheduledTransactions
          .where((tx) => tx['date'] == dateStr)
          .toList();

      double dayIncome = 0;
      double dayExpenses = avgDailySpending; // Start with average
      final descriptions = <String>[];

      // Add scheduled transactions
      for (final tx in dayTransactions) {
        final amount = (tx['amount'] as num).toDouble();
        if (tx['type'] == 'income') {
          dayIncome += amount;
          descriptions.add('+ ${tx['description']} (\$${amount.toStringAsFixed(0)})');
        } else if (tx['type'] == 'expense') {
          dayExpenses += amount;
          descriptions.add('- ${tx['description']} (\$${amount.toStringAsFixed(0)})');
        }
      }

      // Update running balance
      runningBalance = runningBalance + dayIncome - dayExpenses;

      // Determine status
      final status = _determineBalanceStatus(runningBalance);

      forecasts.add(DailyForecast(
        date: date,
        projectedBalance: runningBalance,
        income: dayIncome,
        expenses: dayExpenses,
        status: status,
        scheduledTransactions: descriptions,
      ));
    }

    return forecasts;
  }

  /// Determine balance status based on threshold
  BalanceStatus _determineBalanceStatus(double balance) {
    if (balance >= healthyThreshold) {
      return BalanceStatus.healthy;
    } else if (balance >= warningThreshold) {
      return BalanceStatus.warning;
    } else {
      return BalanceStatus.critical;
    }
  }

  /// Calculate safe to spend amount
  double _calculateSafeToSpend(
    double currentBalance,
    List<DailyForecast> forecasts,
  ) {
    if (forecasts.isEmpty) return currentBalance;

    // Find the lowest projected balance in next 30 days
    double minBalance = forecasts
        .map((f) => f.projectedBalance)
        .reduce((a, b) => a < b ? a : b);

    // Safe to spend is current minus what we need to maintain min balance + buffer
    final buffer = warningThreshold;
    final safeAmount = currentBalance - (currentBalance - minBalance) - buffer;

    return safeAmount > 0 ? safeAmount : 0;
  }

  /// Generate warnings for low balance days
  List<String> _generateWarnings(List<DailyForecast> forecasts) {
    final warnings = <String>[];

    for (final forecast in forecasts) {
      if (forecast.status == BalanceStatus.critical) {
        final daysFromNow = forecast.date.difference(DateTime.now()).inDays;
        final dateStr = _formatDate(forecast.date);

        if (forecast.projectedBalance < 0) {
          warnings.add(
            'Your balance may go negative on $dateStr ($daysFromNow days from now)',
          );
        } else {
          warnings.add(
            'Low balance warning: \$${forecast.projectedBalance.toStringAsFixed(0)} on $dateStr',
          );
        }
      }
    }

    return warnings;
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monthNames[date.month - 1]} ${date.day}';
  }
}
