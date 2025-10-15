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
      if (_containsAny(lowerQuery, ['category', 'categories', 'breakdown'])) {
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

  // Query handlers

  Future<String> _handleBillsQuery(String userId, String query) async {
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
      return 'You have no upcoming bills scheduled in the next 30 days.';
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final buffer = StringBuffer('Here are your upcoming bills:\n\n');

    for (final tx in transactions) {
      final date = DateTime.parse(tx['date'] as String);
      final daysUntil = date.difference(DateTime.now()).inDays;
      buffer.writeln(
        '• ${tx['description']}: ${currencyFormat.format(tx['amount'])} (in $daysUntil days)',
      );
    }

    return buffer.toString().trim();
  }

  Future<String> _handleBalanceQuery(String userId, String query) async {
    // Check if asking about forecast
    if (query.contains('next') || query.contains('will') || query.contains('future')) {
      return await _handleForecastQuery(userId, query);
    }

    final accounts = await _supabase
        .from('accounts')
        .select('name, balance, type')
        .eq('user_id', userId)
        .eq('is_active', true);

    if ((accounts as List).isEmpty) {
      return 'You don\'t have any accounts set up yet.';
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

    return buffer.toString().trim();
  }

  Future<String> _handleSpendingQuery(String userId, String query) async {
    // Extract category if mentioned
    final category = _extractCategory(query);

    // Extract time period (default to current month)
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
      return 'No spending found for the specified period.';
    }

    // Filter by category if specified
    List filteredTxs = transactions;
    if (category != null) {
      filteredTxs = transactions.where((tx) {
        final catName = tx['categories']?['name'] as String?;
        return catName?.toLowerCase().contains(category.toLowerCase()) ?? false;
      }).toList();
    }

    if (filteredTxs.isEmpty) {
      return 'No spending found${category != null ? ' in $category' : ''} for the specified period.';
    }

    double total = 0;
    for (final tx in filteredTxs) {
      total += (tx['amount'] as num).toDouble();
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final periodStr = period['label'] as String;

    if (category != null) {
      return 'You spent ${currencyFormat.format(total)} on $category $periodStr (${filteredTxs.length} transactions).';
    } else {
      return 'You spent ${currencyFormat.format(total)} $periodStr across ${filteredTxs.length} transactions.';
    }
  }

  Future<String> _handleAffordabilityQuery(String userId, String query) async {
    // Extract amount from query
    final amount = _extractAmount(query);
    if (amount == null) {
      return 'Please specify an amount. For example: "Can I afford \$500?"';
    }

    final forecast = await _forecastService.generate30DayForecast();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (forecast.safeToSpend >= amount) {
      final remaining = forecast.safeToSpend - amount;
      return 'Yes! You can afford ${currencyFormat.format(amount)}. '
          'You\'ll still have ${currencyFormat.format(remaining)} safe to spend after this purchase.';
    } else {
      final shortage = amount - forecast.safeToSpend;
      return 'It might be tight. This purchase would exceed your safe spending amount by ${currencyFormat.format(shortage)}. '
          'Consider waiting for your next paycheck or adjusting other expenses.';
    }
  }

  Future<String> _handleForecastQuery(String userId, String query) async {
    final forecast = await _forecastService.generate30DayForecast();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    // Check if asking about specific time
    int days = 7; // Default to next week
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

    return buffer.toString().trim();
  }

  Future<String> _handleIncomeQuery(String userId, String query) async {
    final period = _extractTimePeriod(query);
    final startDate = period['start'] as DateTime;
    final endDate = period['end'] as DateTime;

    final transactions = await _supabase
        .from('transactions')
        .select('amount, description, date')
        .eq('user_id', userId)
        .eq('type', 'income')
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    if ((transactions as List).isEmpty) {
      return 'No income recorded for the specified period.';
    }

    double total = 0;
    for (final tx in transactions) {
      total += (tx['amount'] as num).toDouble();
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final periodStr = period['label'] as String;

    return 'You earned ${currencyFormat.format(total)} $periodStr from ${transactions.length} income sources.';
  }

  Future<String> _handleCategoryQuery(String userId, String query) async {
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
      return 'No expenses found for the specified period.';
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
    final buffer = StringBuffer('Spending by category:\n\n');

    for (final entry in sorted.take(5)) {
      buffer.writeln('• ${entry.key}: ${currencyFormat.format(entry.value)}');
    }

    return buffer.toString().trim();
  }

  Future<String> _handleSavingsQuery(String userId, String query) async {
    // Get income vs expenses for current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final transactions = await _supabase
        .from('transactions')
        .select('amount, type')
        .eq('user_id', userId)
        .gte('date', startOfMonth.toIso8601String().split('T')[0])
        .lte('date', endOfMonth.toIso8601String().split('T')[0]);

    double income = 0;
    double expenses = 0;

    for (final tx in (transactions as List)) {
      final amount = (tx['amount'] as num).toDouble();
      if (tx['type'] == 'income') {
        income += amount;
      } else if (tx['type'] == 'expense') {
        expenses += amount;
      }
    }

    final netSavings = income - expenses;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (netSavings > 0) {
      final savingsRate = (netSavings / income * 100).toStringAsFixed(1);
      return 'Great job! You\'re saving ${currencyFormat.format(netSavings)} this month. '
          'That\'s a $savingsRate% savings rate.';
    } else {
      return 'Your expenses exceed your income by ${currencyFormat.format(netSavings.abs())} this month. '
          'Consider reviewing your budget to identify areas to cut back.';
    }
  }

  Future<String> _handleGeneralQuery(String userId, String query) async {
    // Try to provide a helpful response
    if (query.contains('transaction') || query.contains('recent')) {
      final transactions = await _supabase
          .from('transactions')
          .select('amount, description, date, type')
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(5);

      if ((transactions as List).isEmpty) {
        return 'You have no recent transactions.';
      }

      final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
      final buffer = StringBuffer('Your recent transactions:\n\n');

      for (final tx in transactions) {
        final date = DateTime.parse(tx['date'] as String);
        final dateStr = DateFormat('MMM d').format(date);
        final type = tx['type'] == 'income' ? '+' : '-';
        buffer.writeln('$type${currencyFormat.format(tx['amount'])} - ${tx['description']} ($dateStr)');
      }

      return buffer.toString().trim();
    }

    return 'I\'m not sure how to help with that. Try asking about your balance, spending, bills, or forecast. '
        'Type "help" to see what I can do!';
  }

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

    if (query.contains('today')) {
      return {
        'start': DateTime(now.year, now.month, now.day),
        'end': now,
        'label': 'today',
      };
    } else if (query.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return {
        'start': DateTime(yesterday.year, yesterday.month, yesterday.day),
        'end': DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
        'label': 'yesterday',
      };
    } else if (query.contains('week')) {
      final weekAgo = now.subtract(const Duration(days: 7));
      return {
        'start': weekAgo,
        'end': now,
        'label': 'this week',
      };
    } else if (query.contains('last month')) {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      return {
        'start': lastMonth,
        'end': lastMonthEnd,
        'label': 'last month',
      };
    } else {
      // Default to current month
      final startOfMonth = DateTime(now.year, now.month, 1);
      return {
        'start': startOfMonth,
        'end': now,
        'label': 'this month',
      };
    }
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
}
