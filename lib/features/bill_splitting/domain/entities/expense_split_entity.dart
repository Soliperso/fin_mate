import 'package:equatable/equatable.dart';

class ExpenseSplit extends Equatable {
  final String id;
  final String expenseId;
  final String userId;
  final String? userName;
  final double amount;
  final bool isSettled;
  final DateTime? settledAt;

  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.userId,
    this.userName,
    required this.amount,
    required this.isSettled,
    this.settledAt,
  });

  @override
  List<Object?> get props => [id, expenseId, userId, userName, amount, isSettled, settledAt];
}
