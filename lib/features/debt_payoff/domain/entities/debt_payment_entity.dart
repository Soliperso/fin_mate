import 'package:equatable/equatable.dart';

class DebtPaymentEntity extends Equatable {
  final String id;
  final String debtId;
  final String userId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;

  const DebtPaymentEntity({
    required this.id,
    required this.debtId,
    required this.userId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, debtId, userId, amount, paymentDate, notes, createdAt];
}
