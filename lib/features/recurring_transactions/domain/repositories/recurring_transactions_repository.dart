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
}
