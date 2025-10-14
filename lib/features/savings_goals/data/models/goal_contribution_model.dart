import '../../domain/entities/goal_contribution_entity.dart';

class GoalContributionModel extends GoalContribution {
  const GoalContributionModel({
    required super.id,
    required super.goalId,
    super.transactionId,
    required super.amount,
    super.notes,
    required super.contributedAt,
    required super.createdAt,
  });

  factory GoalContributionModel.fromJson(Map<String, dynamic> json) {
    return GoalContributionModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      transactionId: json['transaction_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      contributedAt: DateTime.parse(json['contributed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'transaction_id': transactionId,
      'amount': amount,
      'notes': notes,
      'contributed_at': contributedAt.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}
