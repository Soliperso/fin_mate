import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/supabase_client.dart';
import 'balance_forecast_service.dart';
import '../../domain/entities/query_response.dart';
import '../../domain/entities/chat_message.dart';

class QueryProcessorService {
  final SupabaseClient _supabase;
  final BalanceForecastService _forecastService;

  QueryProcessorService({
    SupabaseClient? supabaseClient,
    BalanceForecastService? forecastService,
  })  : _supabase = supabaseClient ?? supabase,
        _forecastService = forecastService ?? BalanceForecastService();

  /// Process user query and generate rich response
  Future<QueryResponse> processQueryRich(String query) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return const QueryResponse(
          content: 'Please log in to access your financial data.',
          type: MessageType.error,
        );
      }

      final lowerQuery = query.toLowerCase().trim();

      // Intent detection based on keywords
      // Comparison queries (highest priority)
      if (_containsAny(lowerQuery, ['compare', 'vs', 'versus', 'last month', 'last year', 'compared to'])) {
        return await _handleComparisonQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['trend', 'trending', 'increased', 'decreased', 'pattern'])) {
        return await _handleTrendQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['average', 'typical', 'usual', 'normal'])) {
        return await _handleAverageQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['income', 'earn', 'earned', 'paycheck'])) {
        return await _handleIncomeQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['save', 'savings', 'could i save'])) {
        return await _handleSavingsQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['category', 'categories', 'breakdown'])) {
        return await _handleCategoryQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['balance', 'how much', 'account'])) {
        return await _handleBalanceQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['spend', 'spent', 'spending'])) {
        return await _handleSpendingQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['afford', 'can i buy', 'purchase'])) {
        return await _handleAffordabilityQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['bill', 'due', 'payment', 'pay'])) {
        return await _handleBillsQueryRich(userId, lowerQuery);
      } else if (_containsAny(lowerQuery, ['help', 'what can', 'how do'])) {
        return QueryResponse(
          content: _getHelpMessage(),
          followUpSuggestions: getSuggestedPrompts(),
        );
      } else {
        return await _handleGeneralQueryRich(userId, lowerQuery);
      }
    } catch (e) {
      return const QueryResponse(
        content: 'Sorry, I encountered an error processing your request. Please try again.',
        type: MessageType.error,
      );
    }
  }

  /// Legacy method for backwards compatibility
  Future<String> processQuery(String query) async {
    final response = await processQueryRich(query);
    return response.content;
  }

  /// Get suggested prompts for the user
  List<String> getSuggestedPrompts() {
    return [
      'What\'s my current balance?',
      'What bills are due soon?',
      'How much did I spend this month?',
      'Can I afford a \$500 purchase?',
      'Show my spending by category',
      'What\'s my balance forecast?',
    ];
  }

  // Rich query handlers (actively used)

  String _getHelpMessage() {
    return 'I can help you with:\n\n'
        '• Check your account balances\n'
        '• View upcoming bills and due dates\n'
        '• Analyze your spending patterns\n'
        '• Forecast your future balance\n'
        '• Check if you can afford purchases\n'
        '• Break down spending by category\n\n'
        'Just ask me a question in plain English!';
  }

  // Helper methods

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  String? _extractCategory(String query) {
    const categories = [
      'groceries', 'grocery', 'food',
      'dining', 'restaurant', 'eating',
      'shopping', 'clothes', 'clothing',
      'entertainment', 'movies', 'fun',
      'transport', 'uber', 'lyft', 'gas',
      'utilities', 'bills', 'electric',
      'health', 'medical', 'doctor',
    ];

    for (final cat in categories) {
      if (query.contains(cat)) return cat;
    }

    return null;
  }

  Map<String, dynamic> _extractTimePeriod(String query) {
    final now = DateTime.now();
    final lower = query.toLowerCase();

    // Today
    if (lower.contains('today')) {
      return {
        'start': DateTime(now.year, now.month, now.day),
        'end': now,
        'label': 'today',
      };
    }

    // Yesterday
    if (lower.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return {
        'start': DateTime(yesterday.year, yesterday.month, yesterday.day),
        'end': DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
        'label': 'yesterday',
      };
    }

    // Last 7 days / this week
    if (lower.contains('week') || lower.contains('7 days') || lower.contains('seven days')) {
      final weekAgo = now.subtract(const Duration(days: 7));
      return {
        'start': weekAgo,
        'end': now,
        'label': 'this week',
      };
    }

    // Last 30 days / this month
    if (lower.contains('month') && !lower.contains('last month')) {
      final startOfMonth = DateTime(now.year, now.month, 1);
      return {
        'start': startOfMonth,
        'end': now,
        'label': 'this month',
      };
    }

    // Last month
    if (lower.contains('last month')) {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      return {
        'start': lastMonth,
        'end': lastMonthEnd,
        'label': 'last month',
      };
    }

    // Last quarter (90 days)
    if (lower.contains('quarter') || lower.contains('3 months') || lower.contains('90 days')) {
      final threeMonthsAgo = now.subtract(const Duration(days: 90));
      return {
        'start': threeMonthsAgo,
        'end': now,
        'label': 'last quarter',
      };
    }

    // Last year / this year / year to date
    if (lower.contains('year') || lower.contains('ytd') || lower.contains('12 months')) {
      if (lower.contains('last year')) {
        return {
          'start': DateTime(now.year - 1, 1, 1),
          'end': DateTime(now.year - 1, 12, 31),
          'label': 'last year',
        };
      } else {
        // Year to date
        return {
          'start': DateTime(now.year, 1, 1),
          'end': now,
          'label': 'year to date',
        };
      }
    }

    // Default to current month
    final startOfMonth = DateTime(now.year, now.month, 1);
    return {
      'start': startOfMonth,
      'end': now,
      'label': 'this month',
    };
  }

  double? _extractAmount(String query) {
    // Look for dollar amounts like $500 or 500
    final regex = RegExp(r'\$?(\d+(?:\.\d{2})?)');
    final match = regex.firstMatch(query);

    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }

    return null;
  }

  // Rich query handlers with metadata and follow-up suggestions

  Future<QueryResponse> _handleCategoryQueryRich(String userId, String query) async {
    final period = _extractTimePeriod(query);
    final startDate = period['start'] as DateTime;
    final endDate = period['end'] as DateTime;

    final transactions = await _supabase
        .from('transactions')
        .select('amount, categories(name)')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    if ((transactions as List).isEmpty) {
      return QueryResponse(
        content: 'No expenses found for the specified period.',
        followUpSuggestions: [
          'What\'s my current balance?',
          'Show my income this month',
        ],
      );
    }

    // Group by category
    final categoryTotals = <String, double>{};
    for (final tx in transactions) {
      final category = tx['categories']?['name'] as String? ?? 'Uncategorized';
      final amount = (tx['amount'] as num).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    // Sort by amount
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final buffer = StringBuffer('Here\'s your spending breakdown:\n\n');

    final total = sorted.fold<double>(0, (sum, e) => sum + e.value);
    buffer.writeln('Total: ${currencyFormat.format(total)}\n');

    // Prepare chart data
    final chartData = sorted.take(5).map((entry) => {
      'category': entry.key,
      'amount': entry.value,
    }).toList();

    return QueryResponse(
      content: buffer.toString().trim(),
      type: MessageType.textWithChart,
      data: {
        'chartType': 'category',
        'categoryData': chartData,
      },
      followUpSuggestions: [
        'How can I reduce my ${sorted.first.key.toLowerCase()} spending?',
        'What did I spend on ${sorted.first.key.toLowerCase()} last month?',
        'Show my spending trend',
      ],
    );
  }

  Future<QueryResponse> _handleBalanceQueryRich(String userId, String query) async {
    if (query.contains('next') || query.contains('will') || query.contains('future')) {
      return await _handleForecastQueryRich(userId, query);
    }

    final accounts = await _supabase
        .from('accounts')
        .select('name, balance, type')
        .eq('user_id', userId)
        .eq('is_active', true);

    if ((accounts as List).isEmpty) {
      return QueryResponse(
        content: 'You don\'t have any accounts set up yet.',
        followUpSuggestions: [
          'How do I add an account?',
          'Show my recent transactions',
        ],
      );
    }

    double totalBalance = 0;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final buffer = StringBuffer('Your current balances:\n\n');

    for (final account in accounts) {
      final balance = (account['balance'] as num).toDouble();
      totalBalance += balance;
      buffer.writeln('• ${account['name']}: ${currencyFormat.format(balance)}');
    }

    buffer.writeln('\nTotal: ${currencyFormat.format(totalBalance)}');

    return QueryResponse(
      content: buffer.toString().trim(),
      type: MessageType.textWithActions,
      data: {
        'actions': [
          {'type': 'view_accounts', 'label': 'View All Accounts'},
          {'type': 'add_transaction', 'label': 'Add Transaction'},
        ],
      },
      followUpSuggestions: [
        'What bills are due soon?',
        'How much did I spend this month?',
        'Can I afford a \$500 purchase?',
      ],
    );
  }

  Future<QueryResponse> _handleSpendingQueryRich(String userId, String query) async {
    final category = _extractCategory(query);
    final period = _extractTimePeriod(query);
    final startDate = period['start'] as DateTime;
    final endDate = period['end'] as DateTime;

    var transactionQuery = _supabase
        .from('transactions')
        .select('amount, description, date, categories(name)')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    final transactions = await transactionQuery;

    if ((transactions as List).isEmpty) {
      return QueryResponse(
        content: 'No spending found for the specified period.',
        followUpSuggestions: [
          'What\'s my income this month?',
          'Show my account balances',
        ],
      );
    }

    List filteredTxs = transactions;
    if (category != null) {
      filteredTxs = transactions.where((tx) {
        final catName = tx['categories']?['name'] as String?;
        return catName?.toLowerCase().contains(category.toLowerCase()) ?? false;
      }).toList();
    }

    if (filteredTxs.isEmpty) {
      return QueryResponse(
        content: 'No spending found${category != null ? ' in $category' : ''} for the specified period.',
        followUpSuggestions: [
          'Show spending by category',
          'What\'s my total spending this month?',
        ],
      );
    }

    double total = 0;
    for (final tx in filteredTxs) {
      total += (tx['amount'] as num).toDouble();
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final periodStr = period['label'] as String;

    final content = category != null
        ? 'You spent ${currencyFormat.format(total)} on $category $periodStr (${filteredTxs.length} transactions).'
        : 'You spent ${currencyFormat.format(total)} $periodStr across ${filteredTxs.length} transactions.';

    return QueryResponse(
      content: content,
      followUpSuggestions: [
        'Show my spending by category',
        'How does this compare to last month?',
        'What\'s my budget for ${category ?? 'this month'}?',
      ],
    );
  }

  Future<QueryResponse> _handleAffordabilityQueryRich(String userId, String query) async {
    final amount = _extractAmount(query);
    if (amount == null) {
      return QueryResponse(
        content: 'Please specify an amount. For example: "Can I afford \$500?"',
        followUpSuggestions: [
          'Can I afford \$100?',
          'Can I afford \$500?',
          'What\'s my safe to spend amount?',
        ],
      );
    }

    final forecast = await _forecastService.generate30DayForecast();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    String content;
    List<String> suggestions;

    if (forecast.safeToSpend >= amount) {
      final remaining = forecast.safeToSpend - amount;
      content = 'Yes! You can afford ${currencyFormat.format(amount)}. '
          'You\'ll still have ${currencyFormat.format(remaining)} safe to spend after this purchase.';
      suggestions = [
        'Show my upcoming bills',
        'What\'s my balance forecast?',
        'Track this as a budget',
      ];
    } else {
      final shortage = amount - forecast.safeToSpend;
      content = 'It might be tight. This purchase would exceed your safe spending amount by ${currencyFormat.format(shortage)}. '
          'Consider waiting for your next paycheck or adjusting other expenses.';
      suggestions = [
        'How can I save more money?',
        'Show my spending by category',
        'When is my next paycheck?',
      ];
    }

    return QueryResponse(
      content: content,
      followUpSuggestions: suggestions,
    );
  }

  Future<QueryResponse> _handleBillsQueryRich(String userId, String query) async {
    final transactions = await _supabase
        .from('transactions')
        .select('description, amount, date')
        .eq('user_id', userId)
        .eq('is_recurring', true)
        .eq('type', 'expense')
        .gte('date', DateTime.now().toIso8601String().split('T')[0])
        .order('date', ascending: true)
        .limit(5);

    if ((transactions as List).isEmpty) {
      return QueryResponse(
        content: 'You have no upcoming bills scheduled in the next 30 days.',
        followUpSuggestions: [
          'Add a recurring bill',
          'What\'s my balance forecast?',
          'Show my current balance',
        ],
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final buffer = StringBuffer('Here are your upcoming bills:\n\n');

    double totalBills = 0;
    for (final tx in transactions) {
      final date = DateTime.parse(tx['date'] as String);
      final daysUntil = date.difference(DateTime.now()).inDays;
      final amount = (tx['amount'] as num).toDouble();
      totalBills += amount;
      buffer.writeln(
        '• ${tx['description']}: ${currencyFormat.format(amount)} (in $daysUntil days)',
      );
    }

    buffer.writeln('\nTotal due: ${currencyFormat.format(totalBills)}');

    return QueryResponse(
      content: buffer.toString().trim(),
      followUpSuggestions: [
        'Can I afford these bills?',
        'What\'s my balance after bills?',
        'Set up bill payment reminders',
      ],
    );
  }

  Future<QueryResponse> _handleForecastQueryRich(String userId, String query) async {
    final forecast = await _forecastService.generate30DayForecast();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    int days = 7;
    if (query.contains('month')) {
      days = 30;
    } else if (query.contains('week')) {
      days = 7;
    } else if (query.contains('tomorrow')) {
      days = 1;
    }

    if (days >= forecast.dailyForecasts.length) {
      days = forecast.dailyForecasts.length - 1;
    }

    final targetForecast = forecast.dailyForecasts[days];
    final buffer = StringBuffer();

    if (days == 1) {
      buffer.writeln('Tomorrow\'s projected balance: ${currencyFormat.format(targetForecast.projectedBalance)}');
    } else if (days == 7) {
      buffer.writeln('Next week\'s projected balance: ${currencyFormat.format(targetForecast.projectedBalance)}');
    } else {
      buffer.writeln('In $days days, your projected balance: ${currencyFormat.format(targetForecast.projectedBalance)}');
    }

    buffer.writeln('\nCurrent balance: ${currencyFormat.format(forecast.currentBalance)}');
    buffer.writeln('Safe to spend: ${currencyFormat.format(forecast.safeToSpend)}');

    if (forecast.warnings.isNotEmpty) {
      buffer.writeln('\n⚠️ ${forecast.warnings.first}');
    }

    return QueryResponse(
      content: buffer.toString().trim(),
      followUpSuggestions: [
        'How can I improve my forecast?',
        'What bills are coming up?',
        'Show me ways to save money',
      ],
    );
  }

  Future<QueryResponse> _handleGeneralQueryRich(String userId, String query) async {
    if (query.contains('transaction') || query.contains('recent')) {
      final transactions = await _supabase
          .from('transactions')
          .select('amount, description, date, type')
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(5);

      if ((transactions as List).isEmpty) {
        return QueryResponse(
          content: 'You have no recent transactions.',
          followUpSuggestions: [
            'Add a transaction',
            'What\'s my current balance?',
          ],
        );
      }

      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
      final buffer = StringBuffer('Your recent transactions:\n\n');

      for (final tx in transactions) {
        final date = DateTime.parse(tx['date'] as String);
        final dateStr = DateFormat('MMM d').format(date);
        final type = tx['type'] == 'income' ? '+' : '-';
        buffer.writeln('$type${currencyFormat.format(tx['amount'])} - ${tx['description']} ($dateStr)');
      }

      return QueryResponse(
        content: buffer.toString().trim(),
        followUpSuggestions: [
          'Show my spending by category',
          'What\'s my balance?',
          'Add a new transaction',
        ],
      );
    }

    return QueryResponse(
      content: 'I\'m not sure how to help with that. Try asking about your balance, spending, bills, or forecast.',
      followUpSuggestions: getSuggestedPrompts(),
    );
  }

  // Phase 2: Enhanced Query Handlers

  /// Handle comparison queries (month-to-month, year-to-year, etc.)
  Future<QueryResponse> _handleComparisonQueryRich(String userId, String query) async {
    try {
      final category = _extractCategory(query);
      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      // Determine what to compare
      final isLastYear = query.contains('last year');
      final isLastQuarter = query.contains('last quarter');

      DateTime currentStart, currentEnd, previousStart, previousEnd;
      String comparisonLabel;

      if (isLastYear) {
        // Current year vs last year
        final now = DateTime.now();
        currentStart = DateTime(now.year, 1, 1);
        currentEnd = now;
        previousStart = DateTime(now.year - 1, 1, 1);
        previousEnd = DateTime(now.year - 1, 12, 31);
        comparisonLabel = 'This year so far vs last year';
      } else if (isLastQuarter) {
        // Current quarter vs last quarter
        final now = DateTime.now();
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        currentStart = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
        currentEnd = now;
        previousStart = currentStart.subtract(const Duration(days: 90));
        previousEnd = DateTime(previousStart.year, previousStart.month, previousStart.day).add(const Duration(days: 89));
        comparisonLabel = 'This quarter vs last quarter';
      } else {
        // Current month vs last month (default)
        final now = DateTime.now();
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = now;
        previousStart = DateTime(now.year, now.month - 1, 1);
        previousEnd = DateTime(now.year, now.month, 0);
        comparisonLabel = 'This month vs last month';
      }

      // Get current period transactions
      var currentQuery = _supabase
          .from('transactions')
          .select('amount, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', currentStart.toIso8601String().split('T')[0])
          .lte('date', currentEnd.toIso8601String().split('T')[0]);

      if (category != null) {
        // Will filter in code
      }

      final currentTxs = await currentQuery;

      // Get previous period transactions
      var previousQuery = _supabase
          .from('transactions')
          .select('amount, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', previousStart.toIso8601String().split('T')[0])
          .lte('date', previousEnd.toIso8601String().split('T')[0]);

      final previousTxs = await previousQuery;

      double currentTotal = 0;
      double previousTotal = 0;

      for (final tx in currentTxs as List) {
        if (category == null || (tx['categories']?['name'] as String?)?.toLowerCase().contains(category.toLowerCase()) == true) {
          currentTotal += (tx['amount'] as num).toDouble();
        }
      }

      for (final tx in previousTxs as List) {
        if (category == null || (tx['categories']?['name'] as String?)?.toLowerCase().contains(category.toLowerCase()) == true) {
          previousTotal += (tx['amount'] as num).toDouble();
        }
      }

      final difference = currentTotal - previousTotal;
      final percentChange = previousTotal > 0 ? ((difference / previousTotal) * 100) : 0.0;
      final isIncrease = difference > 0;

      final categoryText = category != null ? ' on $category' : '';
      final buffer = StringBuffer();
      buffer.writeln('$comparisonLabel$categoryText:\n');
      buffer.writeln('Current: ${currencyFormat.format(currentTotal)}');
      buffer.writeln('Previous: ${currencyFormat.format(previousTotal)}');
      buffer.writeln('Change: ${isIncrease ? '+' : ''}${currencyFormat.format(difference)} (${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%)');

      if (isIncrease) {
        buffer.writeln('\n📈 Your spending increased by ${percentChange.toStringAsFixed(1)}%');
      } else {
        buffer.writeln('\n📉 Great! Your spending decreased by ${percentChange.abs().toStringAsFixed(1)}%');
      }

      return QueryResponse(
        content: buffer.toString().trim(),
        followUpSuggestions: [
          'What caused this change?',
          'Show my spending breakdown',
          'How can I reduce this?',
        ],
      );
    } catch (e) {
      return QueryResponse(
        content: 'Unable to compare periods. Please try again.',
        followUpSuggestions: getSuggestedPrompts(),
      );
    }
  }

  /// Handle trend analysis queries
  Future<QueryResponse> _handleTrendQueryRich(String userId, String query) async {
    try {
      final category = _extractCategory(query);
      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      // Get last 3 months of data
      final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
      final transactions = await _supabase
          .from('transactions')
          .select('amount, date, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', threeMonthsAgo.toIso8601String().split('T')[0])
          .order('date', ascending: true);

      if ((transactions as List).isEmpty) {
        return QueryResponse(
          content: 'Not enough transaction data to analyze trends.',
          followUpSuggestions: getSuggestedPrompts(),
        );
      }

      // Calculate monthly totals
      final monthlyData = <String, double>{};
      for (final tx in transactions) {
        final date = DateTime.parse(tx['date'] as String);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        if (category == null || (tx['categories']?['name'] as String?)?.toLowerCase().contains(category.toLowerCase()) == true) {
          final amount = (tx['amount'] as num).toDouble();
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + amount;
        }
      }

      if (monthlyData.length < 2) {
        return QueryResponse(
          content: 'Need at least 2 months of data to identify trends.',
          followUpSuggestions: getSuggestedPrompts(),
        );
      }

      final months = monthlyData.entries.toList();
      final firstMonth = months.first.value;
      final lastMonth = months.last.value;
      final trendDirection = lastMonth > firstMonth ? 'up' : 'down';
      final percentChange = ((lastMonth - firstMonth) / firstMonth * 100).abs();

      final categoryText = category != null ? ' on $category' : '';
      final buffer = StringBuffer('Your spending trend is trending $trendDirection$categoryText:\n\n');

      for (final entry in months) {
        buffer.writeln('${entry.key}: ${currencyFormat.format(entry.value)}');
      }

      buffer.writeln('\nTrend: ${trendDirection.toUpperCase()} by ${percentChange.toStringAsFixed(1)}%');

      if (trendDirection == 'up') {
        buffer.writeln('\n📈 Consider reviewing your expenses to control the increase.');
      } else {
        buffer.writeln('\n📉 Great job! Your spending is decreasing.');
      }

      return QueryResponse(
        content: buffer.toString().trim(),
        followUpSuggestions: [
          'What categories are driving this trend?',
          'How can I reverse this trend?',
          'Show me anomalies',
        ],
      );
    } catch (e) {
      return QueryResponse(
        content: 'Unable to analyze trends. Please try again.',
        followUpSuggestions: getSuggestedPrompts(),
      );
    }
  }

  /// Handle average spending queries
  Future<QueryResponse> _handleAverageQueryRich(String userId, String query) async {
    try {
      final category = _extractCategory(query);
      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      // Get last 90 days
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      final transactions = await _supabase
          .from('transactions')
          .select('amount, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', ninetyDaysAgo.toIso8601String().split('T')[0]);

      if ((transactions as List).isEmpty) {
        return QueryResponse(
          content: 'No transaction data available.',
          followUpSuggestions: getSuggestedPrompts(),
        );
      }

      double total = 0;
      int count = 0;

      for (final tx in transactions) {
        if (category == null || (tx['categories']?['name'] as String?)?.toLowerCase().contains(category.toLowerCase()) == true) {
          total += (tx['amount'] as num).toDouble();
          count++;
        }
      }

      if (count == 0) {
        return QueryResponse(
          content: 'No transactions found in this category.',
          followUpSuggestions: getSuggestedPrompts(),
        );
      }

      final average = total / count;
      final daily = total / 90;
      final monthly = daily * 30;

      final categoryText = category != null ? ' on $category' : '';
      final buffer = StringBuffer('Your average spending$categoryText (last 90 days):\n\n');
      buffer.writeln('Per transaction: ${currencyFormat.format(average)}');
      buffer.writeln('Daily average: ${currencyFormat.format(daily)}');
      buffer.writeln('Monthly average: ${currencyFormat.format(monthly)}');
      buffer.writeln('Total: ${currencyFormat.format(total)} ($count transactions)');

      return QueryResponse(
        content: buffer.toString().trim(),
        followUpSuggestions: [
          'Is this higher or lower than expected?',
          'Show my spending breakdown',
          'Compare to last period',
        ],
      );
    } catch (e) {
      return QueryResponse(
        content: 'Unable to calculate averages. Please try again.',
        followUpSuggestions: getSuggestedPrompts(),
      );
    }
  }

  /// Handle income-related queries
  Future<QueryResponse> _handleIncomeQueryRich(String userId, String query) async {
    try {
      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
      final period = _extractTimePeriod(query);
      final startDate = period['start'] as DateTime;
      final endDate = period['end'] as DateTime;

      final transactions = await _supabase
          .from('transactions')
          .select('amount, date, description')
          .eq('user_id', userId)
          .eq('type', 'income')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      if ((transactions as List).isEmpty) {
        return QueryResponse(
          content: 'No income recorded for this period.',
          followUpSuggestions: getSuggestedPrompts(),
        );
      }

      double total = 0;
      for (final tx in transactions) {
        total += (tx['amount'] as num).toDouble();
      }

      final periodLabel = period['label'] as String;
      final average = total / transactions.length;

      final buffer = StringBuffer('Your income $periodLabel:\n\n');
      buffer.writeln('Total: ${currencyFormat.format(total)}');
      buffer.writeln('Transactions: ${transactions.length}');
      buffer.writeln('Average per transaction: ${currencyFormat.format(average)}');

      return QueryResponse(
        content: buffer.toString().trim(),
        followUpSuggestions: [
          'How much did I spend?',
          'What\'s my savings rate?',
          'Compare to last period',
        ],
      );
    } catch (e) {
      return QueryResponse(
        content: 'Unable to analyze income. Please try again.',
        followUpSuggestions: getSuggestedPrompts(),
      );
    }
  }

  /// Handle savings potential queries
  Future<QueryResponse> _handleSavingsQueryRich(String userId, String query) async {
    try {
      final category = _extractCategory(query);
      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

      // Get last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final transactions = await _supabase
          .from('transactions')
          .select('amount, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', thirtyDaysAgo.toIso8601String().split('T')[0]);

      if ((transactions as List).isEmpty) {
        return QueryResponse(
          content: 'No spending data available.',
          followUpSuggestions: getSuggestedPrompts(),
        );
      }

      double total = 0;
      int count = 0;

      for (final tx in transactions) {
        final txCategory = tx['categories']?['name'] as String? ?? 'Uncategorized';
        if (category == null || txCategory.toLowerCase().contains(category.toLowerCase())) {
          total += (tx['amount'] as num).toDouble();
          count++;
        }
      }

      if (count == 0) {
        return QueryResponse(
          content: 'No spending found in this category.',
          followUpSuggestions: getSuggestedPrompts(),
        );
      }

      // Calculate savings potential (20% reduction)
      final savingsPotential = total * 0.2;
      final annualSavings = savingsPotential * 12;

      final categoryText = category != null ? ' on $category' : '';
      final buffer = StringBuffer('Savings potential$categoryText:\n\n');
      buffer.writeln('Current monthly spending: ${currencyFormat.format(total)}');
      buffer.writeln('Potential monthly savings (20% reduction): ${currencyFormat.format(savingsPotential)}');
      buffer.writeln('Potential annual savings: ${currencyFormat.format(annualSavings)}');

      return QueryResponse(
        content: buffer.toString().trim(),
        followUpSuggestions: [
          'What are my top spending categories?',
          'Show me subscription opportunities',
          'Compare my spending',
        ],
      );
    } catch (e) {
      return QueryResponse(
        content: 'Unable to calculate savings potential. Please try again.',
        followUpSuggestions: getSuggestedPrompts(),
      );
    }
  }
}
