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
}
