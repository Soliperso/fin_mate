import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class TransactionRemoteDataSource {
  final SupabaseClient _supabase;

  TransactionRemoteDataSource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Get all transactions for current user
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
    int? limit,
  }) async {
    var query = _supabase.from('transactions').select('''
          *,
          categories(name),
          accounts!transactions_account_id_fkey(name),
          to_account:accounts!transactions_to_account_id_fkey(name)
        ''');

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String().split('T')[0]);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (type != null) {
      query = query.eq('type', type);
    }

    var orderedQuery = query.order('date', ascending: false);

    final response = limit != null
        ? await orderedQuery.limit(limit)
        : await orderedQuery;

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      data['account_name'] = json['accounts']?['name'];
      data['to_account_name'] = json['to_account']?['name'];
      return TransactionModel.fromJson(data);
    }).toList();
  }

  /// Create new transaction
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final response = await _supabase
        .from('transactions')
        .insert(transaction.toJson())
        .select()
        .single();

    return TransactionModel.fromJson(response);
  }

  /// Update transaction
  Future<TransactionModel> updateTransaction(String id, TransactionModel transaction) async {
    final response = await _supabase
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', id)
        .select()
        .single();

    return TransactionModel.fromJson(response);
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }

  /// Get all accounts
  Future<List<AccountModel>> getAccounts() async {
    final response = await _supabase
        .from('accounts')
        .select()
        .eq('is_active', true)
        .order('created_at');

    return (response as List).map((json) => AccountModel.fromJson(json)).toList();
  }

  /// Create account
  Future<AccountModel> createAccount(AccountModel account) async {
    final response = await _supabase
        .from('accounts')
        .insert(account.toJson())
        .select()
        .single();

    return AccountModel.fromJson(response);
  }

  /// Get all categories
  Future<List<CategoryModel>> getCategories({String? type}) async {
    var query = _supabase.from('categories').select();

    if (type != null) {
      query = query.eq('type', type);
    }

    final response = await query.order('name');
    return (response as List).map((json) => CategoryModel.fromJson(json)).toList();
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get total income
      final incomeResult = await _supabase.rpc('get_total_by_type', params: {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'transaction_type': 'income',
      });

      // Get total expenses
      final expenseResult = await _supabase.rpc('get_total_by_type', params: {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'transaction_type': 'expense',
      });

      // Get account balances
      final accounts = await getAccounts();
      final totalBalance = accounts.fold<double>(
        0,
        (sum, account) => sum + account.balance,
      );

      // Get money health score
      int healthScore = 50;
      try {
        healthScore = await _supabase.rpc('calculate_money_health_score');
      } catch (e) {
        // Use default score if function not available
        healthScore = 50;
      }

      final totalIncome = (incomeResult as num?)?.toDouble() ?? 0.0;
      final totalExpense = (expenseResult as num?)?.toDouble() ?? 0.0;

      return {
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'net_worth': totalBalance,
        'cash_flow': totalIncome - totalExpense,
        'health_score': healthScore,
      };
    } catch (e) {
      // Return empty stats on error
      return {
        'total_income': 0.0,
        'total_expense': 0.0,
        'net_worth': 0.0,
        'cash_flow': 0.0,
        'health_score': 50,
      };
    }
  }

  /// Get category breakdown
  Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
    required String type,
  }) async {
    final response = await _supabase
        .from('transactions')
        .select('category_id, categories(name, color), amount')
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .eq('type', type);

    final Map<String, Map<String, dynamic>> categoryMap = {};

    for (final item in response as List) {
      final categoryId = item['category_id'] as String?;
      final categoryName = item['categories']?['name'] ?? 'Uncategorized';
      final categoryColor = item['categories']?['color'];
      final amount = (item['amount'] as num).toDouble();

      if (categoryMap.containsKey(categoryId)) {
        categoryMap[categoryId]!['amount'] += amount;
      } else {
        categoryMap[categoryId ?? 'uncategorized'] = {
          'category': categoryName,
          'amount': amount,
          'color': categoryColor,
        };
      }
    }

    return categoryMap.values.toList();
  }

  /// Get recent transactions
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    return getTransactions(limit: limit);
  }

  /// Search transactions
  Future<List<TransactionModel>> searchTransactions(String query) async {
    final response = await _supabase
        .from('transactions')
        .select('''
          *,
          categories(name),
          accounts!transactions_account_id_fkey(name)
        ''')
        .or('description.ilike.%$query%,notes.ilike.%$query%')
        .order('date', ascending: false)
        .limit(50);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      data['account_name'] = json['accounts']?['name'];
      return TransactionModel.fromJson(data);
    }).toList();
  }
}
