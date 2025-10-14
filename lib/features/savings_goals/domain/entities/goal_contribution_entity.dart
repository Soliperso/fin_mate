import 'package:equatable/equatable.dart';

class GoalContribution extends Equatable {
  final String id;
  final String goalId;
  final String? transactionId;
  final double amount;
  final String? notes;
  final DateTime contributedAt;
  final DateTime createdAt;

  const GoalContribution({
    required this.id,
    required this.goalId,
    this.transactionId,
    required this.amount,
    this.notes,
    required this.contributedAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        goalId,
        transactionId,
        amount,
        notes,
        contributedAt,
        createdAt,
      ];
}
