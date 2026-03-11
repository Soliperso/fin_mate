import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_remote_datasource.dart';

class DebtRepositoryImpl implements DebtRepository {
  final DebtRemoteDatasource _datasource;

  DebtRepositoryImpl(this._datasource);

  @override
  Future<List<DebtEntity>> getDebts() => _datasource.getDebts();

  @override
  Future<DebtEntity> createDebt({
    required String name,
    required String debtType,
    required double balance,
    required double interestRate,
    required double minimumPayment,
    int? dueDay,
    String? notes,
  }) =>
      _datasource.createDebt(
        name: name,
        debtType: debtType,
        balance: balance,
        interestRate: interestRate,
        minimumPayment: minimumPayment,
        dueDay: dueDay,
        notes: notes,
      );

  @override
  Future<DebtEntity> updateDebt(String id, Map<String, dynamic> fields) =>
      _datasource.updateDebt(id, fields);

  @override
  Future<void> deleteDebt(String id) => _datasource.deleteDebt(id);

  @override
  Future<List<DebtPaymentEntity>> getPayments(String debtId) =>
      _datasource.getPayments(debtId);

  @override
  Future<DebtPaymentEntity> logPayment({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) =>
      _datasource.logPayment(
        debtId: debtId,
        amount: amount,
        paymentDate: paymentDate,
        notes: notes,
      );

  @override
  Future<Map<String, dynamic>> getDebtSummary() => _datasource.getDebtSummary();
}
