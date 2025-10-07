import '../entities/transaction_entity.dart';
import '../entities/account_entity.dart';
import '../entities/category_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
    int? limit,
  });

  Future<TransactionEntity> createTransaction(TransactionEntity transaction);
  Future<TransactionEntity> updateTransaction(String id, TransactionEntity transaction);
  Future<void> deleteTransaction(String id);

  Future<List<AccountEntity>> getAccounts();
  Future<AccountEntity> createAccount(AccountEntity account);

  Future<List<CategoryEntity>> getCategories({String? type});

  Future<Map<String, dynamic>> getDashboardStats({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<Map<String, dynamic>>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
    required String type,
  });

  Future<List<TransactionEntity>> getRecentTransactions({int limit = 10});
  Future<List<TransactionEntity>> searchTransactions(String query);
}
