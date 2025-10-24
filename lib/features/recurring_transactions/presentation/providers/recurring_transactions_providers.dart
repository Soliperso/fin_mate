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
