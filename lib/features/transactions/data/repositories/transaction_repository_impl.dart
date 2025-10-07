import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _dataSource;

  TransactionRepositoryImpl(this._dataSource);

  @override
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
    int? limit,
  }) async {
    final models = await _dataSource.getTransactions(
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      type: type,
      limit: limit,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TransactionEntity> createTransaction(TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    final result = await _dataSource.createTransaction(model);
    return result.toEntity();
  }

  @override
  Future<TransactionEntity> updateTransaction(String id, TransactionEntity transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    final result = await _dataSource.updateTransaction(id, model);
    return result.toEntity();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _dataSource.deleteTransaction(id);
  }

  @override
  Future<List<AccountEntity>> getAccounts() async {
    final models = await _dataSource.getAccounts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<AccountEntity> createAccount(AccountEntity account) async {
    final model = AccountModel.fromEntity(account);
    final result = await _dataSource.createAccount(model);
    return result.toEntity();
  }

  @override
  Future<List<CategoryEntity>> getCategories({String? type}) async {
    final models = await _dataSource.getCategories(type: type);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _dataSource.getDashboardStats(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
    required String type,
  }) async {
    return await _dataSource.getCategoryBreakdown(
      startDate: startDate,
      endDate: endDate,
      type: type,
    );
  }

  @override
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 10}) async {
    final models = await _dataSource.getRecentTransactions(limit: limit);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<TransactionEntity>> searchTransactions(String query) async {
    final models = await _dataSource.searchTransactions(query);
    return models.map((m) => m.toEntity()).toList();
  }
}
