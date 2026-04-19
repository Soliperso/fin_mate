import '../entities/debt_entity.dart';
import '../entities/debt_payment_entity.dart';

abstract class DebtRepository {
  Future<List<DebtEntity>> getDebts();
  Future<DebtEntity> createDebt({
    required String name,
    required String debtType,
    required double balance,
    required double interestRate,
    required double minimumPayment,
    double? originalBalance,
    int? dueDay,
    String? notes,
  });
  Future<DebtEntity> updateDebt(String id, Map<String, dynamic> fields);
  Future<void> deleteDebt(String id);
  Future<List<DebtPaymentEntity>> getPayments(String debtId);
  Future<DebtPaymentEntity> logPayment({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  });
  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  });
  Future<void> deletePayment({
    required String paymentId,
    required String debtId,
    required double amount,
  });
  Future<Map<String, dynamic>> getDebtSummary();
  Future<List<DebtPaymentEntity>> getAllPayments();
}
