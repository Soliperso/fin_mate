# Backend Integration Implementation Guide

This guide provides a comprehensive plan to replace all hardcoded data with real Supabase backend integration.

## ✅ What's Been Completed

1. **Database Schema Created** - `supabase/migrations/create_financial_tables.sql`
   - ✅ Transactions table with automatic balance updates
   - ✅ Categories with default seed data
   - ✅ Accounts (cash, checking, savings, credit cards, etc.)
   - ✅ Budgets tracking
   - ✅ Recurring transactions
   - ✅ Row Level Security (RLS) policies
   - ✅ Triggers for auto-initialization on user signup
   - ✅ Views for common queries

2. **Domain Entities Created**
   - ✅ `TransactionEntity` - Complete transaction model
   - ✅ `CategoryEntity` - Transaction categories
   - ✅ `AccountEntity` - Financial accounts

3. **Navigation Fixed**
   - ✅ Added Budgets tab to bottom navigation bar

## 📋 Implementation Steps

### Step 1: Apply Database Migrations

```bash
# Using Supabase Dashboard (Easiest)
# 1. Go to https://app.supabase.com
# 2. Select your project
# 3. Click SQL Editor → New Query
# 4. Copy contents of supabase/migrations/create_financial_tables.sql
# 5. Click Run

# OR using Supabase CLI
cd /Users/ahmedchebli/Desktop/fin_mate
supabase db push
```

### Step 2: Create Data Models

Create these files in `lib/features/transactions/data/models/`:

#### `transaction_model.dart`
```dart
import '../../domain/entities/transaction_entity.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final String type;
  final double amount;
  final String? description;
  final String? notes;
  final DateTime date;
  final bool isRecurring;
  final String? recurringInterval;
  final String? toAccountId;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Joined data
  final String? categoryName;
  final String? accountName;
  final String? toAccountName;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      accountId: json['account_id'],
      categoryId: json['category_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      notes: json['notes'],
      date: DateTime.parse(json['date']),
      isRecurring: json['is_recurring'] ?? false,
      recurringInterval: json['recurring_interval'],
      toAccountId: json['to_account_id'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      categoryName: json['category_name'],
      accountName: json['account_name'],
      toAccountName: json['to_account_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'notes': notes,
      'date': date.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'recurring_interval': recurringInterval,
      'to_account_id': toAccountId,
      'tags': tags,
    };
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      type: _parseType(type),
      amount: amount,
      description: description,
      notes: notes,
      date: date,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      toAccountId: toAccountId,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      categoryName: categoryName,
      accountName: accountName,
      toAccountName: toAccountName,
    );
  }

  static TransactionType _parseType(String type) {
    switch (type) {
      case 'income': return TransactionType.income;
      case 'expense': return TransactionType.expense;
      case 'transfer': return TransactionType.transfer;
      default: return TransactionType.expense;
    }
  }
}
```

### Step 3: Create Data Sources

Create `lib/features/transactions/data/datasources/transaction_remote_datasource.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class TransactionRemoteDataSource {
  final SupabaseClient _supabase;

  TransactionRemoteDataSource({SupabaseClient? supabase})
      : _supabase = supabase ?? supabase;

  /// Get all transactions for current user
  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
  }) async {
    var query = _supabase
        .from('transactions')
        .select('''
          *,
          categories(name),
          accounts!transactions_account_id_fkey(name),
          to_account:accounts!transactions_to_account_id_fkey(name)
        ''')
        .order('date', ascending: false);

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

    final response = await query;
    
    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      // Flatten joined data
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

  /// Get all accounts
  Future<List<AccountModel>> getAccounts() async {
    final response = await _supabase
        .from('accounts')
        .select()
        .eq('is_active', true)
        .order('created_at');

    return (response as List).map((json) => AccountModel.fromJson(json)).toList();
  }

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .order('name');

    return (response as List).map((json) => CategoryModel.fromJson(json)).toList();
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get total income
    final incomeResult = await _supabase
        .rpc('get_total_by_type', params: {
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'transaction_type': 'income',
        });

    // Get total expenses
    final expenseResult = await _supabase
        .rpc('get_total_by_type', params: {
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

    return {
      'total_income': incomeResult ?? 0.0,
      'total_expense': expenseResult ?? 0.0,
      'net_worth': totalBalance,
      'cash_flow': (incomeResult ?? 0.0) - (expenseResult ?? 0.0),
    };
  }
}
```

### Step 4: Add Database Functions

Add to your migration SQL:

```sql
-- Function to get totals by transaction type
CREATE OR REPLACE FUNCTION get_total_by_type(
  start_date DATE,
  end_date DATE,
  transaction_type TEXT
)
RETURNS DECIMAL AS $$
  SELECT COALESCE(SUM(amount), 0)
  FROM transactions
  WHERE user_id = auth.uid()
    AND date >= start_date
    AND date <= end_date
    AND type = transaction_type;
$$ LANGUAGE SQL SECURITY DEFINER;

-- Function to calculate money health score
CREATE OR REPLACE FUNCTION calculate_money_health_score()
RETURNS INTEGER AS $$
DECLARE
  income DECIMAL;
  expense DECIMAL;
  savings_rate DECIMAL;
  score INTEGER := 50;
BEGIN
  -- Get last 30 days data
  SELECT COALESCE(SUM(amount), 0) INTO income
  FROM transactions
  WHERE user_id = auth.uid()
    AND type = 'income'
    AND date >= CURRENT_DATE - INTERVAL '30 days';

  SELECT COALESCE(SUM(amount), 0) INTO expense
  FROM transactions
  WHERE user_id = auth.uid()
    AND type = 'expense'
    AND date >= CURRENT_DATE - INTERVAL '30 days';

  -- Calculate savings rate
  IF income > 0 THEN
    savings_rate := ((income - expense) / income) * 100;
    
    -- Score based on savings rate
    IF savings_rate >= 20 THEN score := 100;
    ELSIF savings_rate >= 15 THEN score := 85;
    ELSIF savings_rate >= 10 THEN score := 70;
    ELSIF savings_rate >= 5 THEN score := 55;
    ELSIF savings_rate >= 0 THEN score := 40;
    ELSE score := 20;
    END IF;
  END IF;

  RETURN score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Step 5: Create Repositories

Create `lib/features/transactions/data/repositories/transaction_repository_impl.dart`:

```dart
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _dataSource;

  TransactionRepositoryImpl(this._dataSource);

  @override
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
  }) async {
    final models = await _dataSource.getTransactions(
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      type: type,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TransactionEntity> createTransaction(TransactionEntity transaction) async {
    // Convert entity to model
    final model = TransactionModel.fromEntity(transaction);
    final result = await _dataSource.createTransaction(model);
    return result.toEntity();
  }
}
```

### Step 6: Create Providers

Create `lib/features/transactions/presentation/providers/transaction_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';

final transactionDataSourceProvider = Provider((ref) {
  return TransactionRemoteDataSource();
});

final transactionRepositoryProvider = Provider((ref) {
  return TransactionRepositoryImpl(ref.read(transactionDataSourceProvider));
});

final transactionsProvider = FutureProvider.family<List<TransactionEntity>, DateTime>((ref, month) async {
  final repository = ref.read(transactionRepositoryProvider);
  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0);
  
  return await repository.getTransactions(
    startDate: startDate,
    endDate: endDate,
  );
});

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dataSource = ref.read(transactionDataSourceProvider);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0);
  
  return await dataSource.getDashboardStats(
    startDate: startDate,
    endDate: endDate,
  );
});
```

### Step 7: Update Dashboard Page

Replace hardcoded data in `dashboard_page.dart`:

```dart
// Instead of hardcoded stats:
final stats = ref.watch(dashboardStatsProvider);

return stats.when(
  data: (data) => Column(
    children: [
      NetWorthCard(netWorth: data['net_worth']),
      MoneyHealthCard(score: data['health_score']),
      CashFlowCard(
        income: data['total_income'],
        expense: data['total_expense'],
      ),
    ],
  ),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

## 🎯 Key Features Implemented

1. **Automatic Balance Updates** - Triggers handle account balance changes
2. **Default Categories** - Auto-created on user signup
3. **Real-time Calculations** - Database functions for stats
4. **Row Level Security** - Users can only see their own data
5. **Money Health Score** - Calculated from actual spending patterns
6. **Transaction Filtering** - By date, category, type
7. **Budget Tracking** - Compare spending vs budgets

## 📝 Next Steps

1. Apply database migration
2. Create all model files
3. Create data source files
4. Create repository implementations
5. Update providers
6. Replace hardcoded data in UI
7. Test thoroughly

## 🔍 Testing Checklist

- [ ] Create test account
- [ ] Add sample transactions
- [ ] Verify dashboard shows real data
- [ ] Test transaction filtering
- [ ] Verify budget calculations
- [ ] Check money health score
- [ ] Test account balance updates
- [ ] Verify RLS policies work

## 📚 Files to Create

1. `lib/features/transactions/data/models/transaction_model.dart`
2. `lib/features/transactions/data/models/account_model.dart`
3. `lib/features/transactions/data/models/category_model.dart`
4. `lib/features/transactions/data/datasources/transaction_remote_datasource.dart`
5. `lib/features/transactions/data/repositories/transaction_repository_impl.dart`
6. `lib/features/transactions/domain/repositories/transaction_repository.dart`
7. `lib/features/transactions/presentation/providers/transaction_providers.dart`

This is a comprehensive implementation. Would you like me to generate all the files or focus on a specific part first?
