import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_client.dart';
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
    String>((ref, id) async {
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

  /// Auto-generates transactions for all overdue active recurring entries.
  /// Safe to call on every page load — advances next_occurrence so it's idempotent.
  Future<void> processOverdue(String userId) async {
    try {
      final all = await _repository.getActiveRecurringTransactions();
      final now = DateTime.now();
      final overdue = all.where((t) => t.nextOccurrence.isBefore(now)).toList();
      if (overdue.isEmpty) return;

      for (final t in overdue) {
        try {
          await supabase.from('transactions').insert({
            'user_id': userId,
            'account_id': t.accountId,
            if (t.categoryId != null) 'category_id': t.categoryId,
            'type': t.type,
            'amount': t.amount,
            if (t.description != null) 'description': t.description,
            'date': t.nextOccurrence.toIso8601String().split('T')[0],
            'is_recurring': true,
            if (t.toAccountId != null) 'to_account_id': t.toAccountId,
          });

          // Advance next_occurrence past now
          var next = t.nextOccurrence;
          while (!next.isAfter(now)) {
            next = _advance(next, t.frequency);
          }
          await _repository.updateRecurringTransaction(
            id: t.id,
            nextOccurrence: next,
          );
        } catch (_) {
          // Don't abort the loop for one failed entry
        }
      }

      _ref.invalidate(recurringTransactionsProvider);
      _ref.invalidate(activeRecurringTransactionsProvider);
      _ref.invalidate(upcomingRecurringTransactionsProvider);
    } catch (_) {
      // Silent — auto-gen is best-effort
    }
  }

  static DateTime _advance(DateTime from, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        final newMonth = from.month + 1;
        return DateTime(
          from.year + (newMonth > 12 ? 1 : 0),
          newMonth > 12 ? newMonth - 12 : newMonth,
          from.day,
        );
      case RecurringFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

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
