import '../../domain/entities/debt_payment_entity.dart';

class DebtPaymentModel extends DebtPaymentEntity {
  const DebtPaymentModel({
    required super.id,
    required super.debtId,
    required super.userId,
    required super.amount,
    required super.paymentDate,
    super.notes,
    required super.createdAt,
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtPaymentModel(
      id: json['id'] as String,
      debtId: json['debt_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
