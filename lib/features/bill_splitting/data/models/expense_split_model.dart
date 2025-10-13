import '../../domain/entities/expense_split_entity.dart';

class ExpenseSplitModel extends ExpenseSplit {
  const ExpenseSplitModel({
    required super.id,
    required super.expenseId,
    required super.userId,
    super.userName,
    required super.amount,
    required super.isSettled,
    super.settledAt,
  });

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitModel(
      id: json['id'] as String,
      expenseId: json['expense_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      isSettled: json['is_settled'] as bool? ?? false,
      settledAt: json['settled_at'] != null
          ? DateTime.parse(json['settled_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'user_id': userId,
      'user_name': userName,
      'amount': amount,
      'is_settled': isSettled,
      'settled_at': settledAt?.toIso8601String(),
    };
  }
}
