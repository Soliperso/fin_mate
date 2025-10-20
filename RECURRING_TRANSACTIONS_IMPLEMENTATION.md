# Recurring Transactions Feature - Implementation Guide

## Overview

This document provides a complete guide for implementing the recurring transactions management UI in FinMate. The database infrastructure already exists, so this focuses on building the frontend layer.

## Current Status

### ✅ Already Implemented
- Database table: `recurring_transactions` with all necessary fields
- Row Level Security (RLS) policies for user data isolation
- Dashboard integration: displays upcoming bills (top 3)
- Empty state handling in dashboard

### ❌ To Be Implemented
- Full recurring transactions list page
- Create recurring transaction form
- Edit recurring transaction functionality
- Delete recurring transaction functionality
- Automatic transaction generation from recurring templates

## Architecture Overview

Following FinMate's feature-first architecture:

```
lib/features/recurring_transactions/
├── data/
│   ├── datasources/
│   │   └── recurring_transactions_remote_datasource.dart
│   ├── models/
│   │   └── recurring_transaction_model.dart
│   └── repositories/
│       └── recurring_transactions_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── recurring_transaction_entity.dart
│   └── repositories/
│       └── recurring_transactions_repository.dart
└── presentation/
    ├── pages/
    │   ├── recurring_transactions_page.dart
    │   └── recurring_transaction_detail_page.dart
    ├── widgets/
    │   ├── add_recurring_transaction_bottom_sheet.dart
    │   ├── edit_recurring_transaction_bottom_sheet.dart
    │   └── recurring_transaction_list_item.dart
    └── providers/
        └── recurring_transactions_providers.dart
```

## Implementation Steps

### Phase 1: Domain Layer (Entities & Repository Interfaces)

#### 1.1 Create Entity

**File**: `lib/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart`

```dart
import 'package:equatable/equatable.dart';

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }
}

class RecurringTransactionEntity extends Equatable {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final String? categoryName;
  final String type; // 'income', 'expense', 'transfer'
  final double amount;
  final String? description;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextOccurrence;
  final bool isActive;
  final String? toAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringTransactionEntity({
    required this.id,
    required this.userId,
    required this.accountId,
    this.categoryId,
    this.categoryName,
    required this.type,
    required this.amount,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextOccurrence,
    required this.isActive,
    this.toAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Days until next occurrence
  int get daysUntilDue => nextOccurrence.difference(DateTime.now()).inDays;

  /// Whether this recurring transaction is overdue
  bool get isOverdue => nextOccurrence.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        userId,
        accountId,
        categoryId,
        categoryName,
        type,
        amount,
        description,
        frequency,
        startDate,
        endDate,
        nextOccurrence,
        isActive,
        toAccountId,
        createdAt,
        updatedAt,
      ];
}
```

#### 1.2 Create Repository Interface

**File**: `lib/features/recurring_transactions/domain/repositories/recurring_transactions_repository.dart`

```dart
import '../entities/recurring_transaction_entity.dart';

abstract class RecurringTransactionsRepository {
  /// Get all recurring transactions for the current user
  Future<List<RecurringTransactionEntity>> getAllRecurringTransactions();

  /// Get active recurring transactions only
  Future<List<RecurringTransactionEntity>> getActiveRecurringTransactions();

  /// Get upcoming recurring transactions (within next N days)
  Future<List<RecurringTransactionEntity>> getUpcomingRecurringTransactions({
    int daysAhead = 30,
  });

  /// Get a single recurring transaction by ID
  Future<RecurringTransactionEntity> getRecurringTransactionById(String id);

  /// Create a new recurring transaction
  Future<RecurringTransactionEntity> createRecurringTransaction({
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime nextOccurrence,
    String? toAccountId,
  });

  /// Update an existing recurring transaction
  Future<RecurringTransactionEntity> updateRecurringTransaction({
    required String id,
    String? accountId,
    String? categoryId,
    String? type,
    double? amount,
    String? description,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextOccurrence,
    bool? isActive,
    String? toAccountId,
  });

  /// Delete a recurring transaction
  Future<void> deleteRecurringTransaction(String id);

  /// Toggle active status
  Future<void> toggleActiveStatus(String id, bool isActive);

  /// Process a recurring transaction (create actual transaction and update next occurrence)
  Future<void> processRecurringTransaction(String id);
}
```

### Phase 2: Data Layer (Models, Datasources, Repository Implementation)

#### 2.1 Create Model

**File**: `lib/features/recurring_transactions/data/models/recurring_transaction_model.dart`

```dart
import '../../domain/entities/recurring_transaction_entity.dart';

class RecurringTransactionModel extends RecurringTransactionEntity {
  const RecurringTransactionModel({
    required super.id,
    required super.userId,
    required super.accountId,
    super.categoryId,
    super.categoryName,
    required super.type,
    required super.amount,
    super.description,
    required super.frequency,
    required super.startDate,
    super.endDate,
    required super.nextOccurrence,
    required super.isActive,
    super.toAccountId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      frequency: _parseFrequency(json['frequency'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      nextOccurrence: DateTime.parse(json['next_occurrence'] as String),
      isActive: json['is_active'] as bool,
      toAccountId: json['to_account_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'next_occurrence': nextOccurrence.toIso8601String().split('T')[0],
      'is_active': isActive,
      'to_account_id': toAccountId,
    };
  }

  RecurringTransactionEntity toEntity() => this;

  static RecurringFrequency _parseFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return RecurringFrequency.daily;
      case 'weekly':
        return RecurringFrequency.weekly;
      case 'monthly':
        return RecurringFrequency.monthly;
      case 'yearly':
        return RecurringFrequency.yearly;
      default:
        return RecurringFrequency.monthly;
    }
  }
}
```

#### 2.2 Create Remote Datasource

**File**: `lib/features/recurring_transactions/data/datasources/recurring_transactions_remote_datasource.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/recurring_transaction_model.dart';

class RecurringTransactionsRemoteDatasource {
  final SupabaseClient _supabase;

  RecurringTransactionsRemoteDatasource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  Future<List<RecurringTransactionModel>> getAllRecurringTransactions() async {
    final response = await _supabase
        .from('recurring_transactions')
        .select('''
          *,
          categories(name)
        ''')
        .order('next_occurrence', ascending: true);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      return RecurringTransactionModel.fromJson(data);
    }).toList();
  }

  Future<List<RecurringTransactionModel>> getActiveRecurringTransactions() async {
    final response = await _supabase
        .from('recurring_transactions')
        .select('''
          *,
          categories(name)
        ''')
        .eq('is_active', true)
        .order('next_occurrence', ascending: true);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      return RecurringTransactionModel.fromJson(data);
    }).toList();
  }

  Future<List<RecurringTransactionModel>> getUpcomingRecurringTransactions({
    int daysAhead = 30,
  }) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));

    final response = await _supabase
        .from('recurring_transactions')
        .select('''
          *,
          categories(name)
        ''')
        .eq('is_active', true)
        .gte('next_occurrence', now.toIso8601String().split('T')[0])
        .lte('next_occurrence', futureDate.toIso8601String().split('T')[0])
        .order('next_occurrence', ascending: true);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      return RecurringTransactionModel.fromJson(data);
    }).toList();
  }

  Future<RecurringTransactionModel> getRecurringTransactionById(String id) async {
    final response = await _supabase
        .from('recurring_transactions')
        .select('''
          *,
          categories(name)
        ''')
        .eq('id', id)
        .single();

    final data = Map<String, dynamic>.from(response);
    data['category_name'] = response['categories']?['name'];
    return RecurringTransactionModel.fromJson(data);
  }

  Future<RecurringTransactionModel> createRecurringTransaction(
    Map<String, dynamic> data,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    data['user_id'] = userId;

    final response = await _supabase
        .from('recurring_transactions')
        .insert(data)
        .select('''
          *,
          categories(name)
        ''')
        .single();

    final responseData = Map<String, dynamic>.from(response);
    responseData['category_name'] = response['categories']?['name'];
    return RecurringTransactionModel.fromJson(responseData);
  }

  Future<RecurringTransactionModel> updateRecurringTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _supabase
        .from('recurring_transactions')
        .update(data)
        .eq('id', id)
        .select('''
          *,
          categories(name)
        ''')
        .single();

    final responseData = Map<String, dynamic>.from(response);
    responseData['category_name'] = response['categories']?['name'];
    return RecurringTransactionModel.fromJson(responseData);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _supabase
        .from('recurring_transactions')
        .delete()
        .eq('id', id);
  }
}
```

#### 2.3 Create Repository Implementation

**File**: `lib/features/recurring_transactions/data/repositories/recurring_transactions_repository_impl.dart`

```dart
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/repositories/recurring_transactions_repository.dart';
import '../datasources/recurring_transactions_remote_datasource.dart';

class RecurringTransactionsRepositoryImpl
    implements RecurringTransactionsRepository {
  final RecurringTransactionsRemoteDatasource _remoteDatasource;

  RecurringTransactionsRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<RecurringTransactionEntity>> getAllRecurringTransactions() async {
    final models = await _remoteDatasource.getAllRecurringTransactions();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<RecurringTransactionEntity>> getActiveRecurringTransactions() async {
    final models = await _remoteDatasource.getActiveRecurringTransactions();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<RecurringTransactionEntity>> getUpcomingRecurringTransactions({
    int daysAhead = 30,
  }) async {
    final models = await _remoteDatasource.getUpcomingRecurringTransactions(
      daysAhead: daysAhead,
    );
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<RecurringTransactionEntity> getRecurringTransactionById(String id) async {
    final model = await _remoteDatasource.getRecurringTransactionById(id);
    return model.toEntity();
  }

  @override
  Future<RecurringTransactionEntity> createRecurringTransaction({
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime nextOccurrence,
    String? toAccountId,
  }) async {
    final data = {
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'frequency': frequency,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'next_occurrence': nextOccurrence.toIso8601String().split('T')[0],
      'is_active': true,
      'to_account_id': toAccountId,
    };

    final model = await _remoteDatasource.createRecurringTransaction(data);
    return model.toEntity();
  }

  @override
  Future<RecurringTransactionEntity> updateRecurringTransaction({
    required String id,
    String? accountId,
    String? categoryId,
    String? type,
    double? amount,
    String? description,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextOccurrence,
    bool? isActive,
    String? toAccountId,
  }) async {
    final data = <String, dynamic>{};
    if (accountId != null) data['account_id'] = accountId;
    if (categoryId != null) data['category_id'] = categoryId;
    if (type != null) data['type'] = type;
    if (amount != null) data['amount'] = amount;
    if (description != null) data['description'] = description;
    if (frequency != null) data['frequency'] = frequency;
    if (startDate != null) {
      data['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      data['end_date'] = endDate.toIso8601String().split('T')[0];
    }
    if (nextOccurrence != null) {
      data['next_occurrence'] = nextOccurrence.toIso8601String().split('T')[0];
    }
    if (isActive != null) data['is_active'] = isActive;
    if (toAccountId != null) data['to_account_id'] = toAccountId;

    final model = await _remoteDatasource.updateRecurringTransaction(id, data);
    return model.toEntity();
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    await _remoteDatasource.deleteRecurringTransaction(id);
  }

  @override
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    await _remoteDatasource.updateRecurringTransaction(id, {
      'is_active': isActive,
    });
  }

  @override
  Future<void> processRecurringTransaction(String id) async {
    // TODO: Implement automatic transaction creation
    // This would:
    // 1. Get the recurring transaction details
    // 2. Create a new transaction in the transactions table
    // 3. Update next_occurrence based on frequency
    throw UnimplementedError('processRecurringTransaction not yet implemented');
  }
}
```

### Phase 3: Presentation Layer (Providers, Pages, Widgets)

#### 3.1 Create Providers

**File**: `lib/features/recurring_transactions/presentation/providers/recurring_transactions_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/recurring_transactions_remote_datasource.dart';
import '../../data/repositories/recurring_transactions_repository_impl.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/repositories/recurring_transactions_repository.dart';

// Repository provider
final recurringTransactionsRepositoryProvider =
    Provider<RecurringTransactionsRepository>((ref) {
  return RecurringTransactionsRepositoryImpl(
    RecurringTransactionsRemoteDatasource(),
  );
});

// All recurring transactions provider
final recurringTransactionsProvider =
    FutureProvider<List<RecurringTransactionEntity>>((ref) async {
  final repository = ref.watch(recurringTransactionsRepositoryProvider);
  return await repository.getAllRecurringTransactions();
});

// Active recurring transactions only
final activeRecurringTransactionsProvider =
    FutureProvider<List<RecurringTransactionEntity>>((ref) async {
  final repository = ref.watch(recurringTransactionsRepositoryProvider);
  return await repository.getActiveRecurringTransactions();
});

// Upcoming recurring transactions (next 30 days)
final upcomingRecurringTransactionsProvider =
    FutureProvider<List<RecurringTransactionEntity>>((ref) async {
  final repository = ref.watch(recurringTransactionsRepositoryProvider);
  return await repository.getUpcomingRecurringTransactions(daysAhead: 30);
});

// Single recurring transaction by ID
final recurringTransactionByIdProvider = FutureProvider.family<
    RecurringTransactionEntity,
    String
>((ref, id) async {
  final repository = ref.watch(recurringTransactionsRepositoryProvider);
  return await repository.getRecurringTransactionById(id);
});

// Operations provider for CRUD operations
final recurringTransactionsOperationsProvider =
    StateNotifierProvider<RecurringTransactionsOperationsNotifier, AsyncValue<void>>(
  (ref) => RecurringTransactionsOperationsNotifier(
    ref.watch(recurringTransactionsRepositoryProvider),
    ref,
  ),
);

class RecurringTransactionsOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final RecurringTransactionsRepository _repository;
  final Ref _ref;

  RecurringTransactionsOperationsNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> createRecurringTransaction({
    required String accountId,
    String? categoryId,
    required String type,
    required double amount,
    String? description,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    required DateTime nextOccurrence,
    String? toAccountId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createRecurringTransaction(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        nextOccurrence: nextOccurrence,
        toAccountId: toAccountId,
      );

      // Invalidate providers to refresh data
      _ref.invalidate(recurringTransactionsProvider);
      _ref.invalidate(activeRecurringTransactionsProvider);
      _ref.invalidate(upcomingRecurringTransactionsProvider);
    });
  }

  Future<void> updateRecurringTransaction({
    required String id,
    String? accountId,
    String? categoryId,
    String? type,
    double? amount,
    String? description,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextOccurrence,
    bool? isActive,
    String? toAccountId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateRecurringTransaction(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        nextOccurrence: nextOccurrence,
        isActive: isActive,
        toAccountId: toAccountId,
      );

      // Invalidate providers to refresh data
      _ref.invalidate(recurringTransactionsProvider);
      _ref.invalidate(activeRecurringTransactionsProvider);
      _ref.invalidate(upcomingRecurringTransactionsProvider);
      _ref.invalidate(recurringTransactionByIdProvider(id));
    });
  }

  Future<void> deleteRecurringTransaction(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteRecurringTransaction(id);

      // Invalidate providers to refresh data
      _ref.invalidate(recurringTransactionsProvider);
      _ref.invalidate(activeRecurringTransactionsProvider);
      _ref.invalidate(upcomingRecurringTransactionsProvider);
    });
  }

  Future<void> toggleActiveStatus(String id, bool isActive) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.toggleActiveStatus(id, isActive);

      // Invalidate providers to refresh data
      _ref.invalidate(recurringTransactionsProvider);
      _ref.invalidate(activeRecurringTransactionsProvider);
      _ref.invalidate(upcomingRecurringTransactionsProvider);
      _ref.invalidate(recurringTransactionByIdProvider(id));
    });
  }
}
```

### Phase 4: UI Implementation

Due to the length of this document, detailed UI implementations for pages and widgets would follow the same patterns used in existing features like:

- [lib/features/bill_splitting/presentation/pages/group_detail_page.dart](lib/features/bill_splitting/presentation/pages/group_detail_page.dart)
- [lib/features/bill_splitting/presentation/widgets/add_expense_bottom_sheet.dart](lib/features/bill_splitting/presentation/widgets/add_expense_bottom_sheet.dart)
- [lib/features/transactions/presentation/pages/add_transaction_page.dart](lib/features/transactions/presentation/pages/add_transaction_page.dart)

Key UI components needed:
1. **RecurringTransactionsPage** - List view showing all recurring transactions
2. **AddRecurringTransactionBottomSheet** - Form to create new recurring transaction
3. **EditRecurringTransactionBottomSheet** - Form to edit existing recurring transaction
4. **RecurringTransactionListItem** - Widget for list item display

### Phase 5: Router Integration

Update [lib/core/config/router.dart](lib/core/config/router.dart):

```dart
GoRoute(
  path: '/recurring-transactions',
  builder: (context, state) => const RecurringTransactionsPage(),
),
```

Update [lib/features/dashboard/presentation/widgets/upcoming_bills_card.dart:34](lib/features/dashboard/presentation/widgets/upcoming_bills_card.dart#L34):

```dart
TextButton(
  onPressed: () {
    context.go('/recurring-transactions');
  },
  child: const Text('View All'),
),
```

## Testing Strategy

### Unit Tests
- Test repository methods
- Test provider logic
- Test entity/model conversions

### Integration Tests
- Test CRUD operations end-to-end
- Test provider invalidation
- Test navigation flows

### Manual Testing
1. Create recurring transactions with different frequencies
2. Verify they appear in dashboard "Upcoming Bills"
3. Edit recurring transactions and verify updates
4. Toggle active status and verify filtering
5. Delete recurring transactions and verify removal

## Future Enhancements

1. **Automatic Transaction Generation**
   - Implement `processRecurringTransaction()` method
   - Create background service or scheduled job
   - Generate actual transactions when `next_occurrence` is reached
   - Update `next_occurrence` based on frequency

2. **Notifications**
   - Remind users of upcoming bills (3 days, 1 day, day of)
   - Notify when recurring transaction is processed

3. **Analytics**
   - Show total recurring expenses per month
   - Compare recurring vs one-time expenses
   - Forecast future expenses based on recurring transactions

4. **Templates**
   - Allow users to create templates from existing transactions
   - Quick setup for common bills (rent, utilities, subscriptions)

## References

### Key Files to Reference
- Transaction implementation: [lib/features/transactions/](lib/features/transactions/)
- Bill splitting patterns: [lib/features/bill_splitting/](lib/features/bill_splitting/)
- Database schema: [supabase/migrations/00_create_core_schema.sql:197-238](supabase/migrations/00_create_core_schema.sql#L197-L238)
- Dashboard integration: [lib/features/dashboard/data/repositories/dashboard_repository_impl.dart:163-198](lib/features/dashboard/data/repositories/dashboard_repository_impl.dart#L163-L198)

### Design System References
- Material 3 theme: [lib/core/theme/](lib/core/theme/)
- Shared widgets: [lib/shared/widgets/](lib/shared/widgets/)
- App colors: [lib/core/constants/app_colors.dart](lib/core/constants/app_colors.dart)
- App sizes: [lib/core/constants/app_sizes.dart](lib/core/constants/app_sizes.dart)
