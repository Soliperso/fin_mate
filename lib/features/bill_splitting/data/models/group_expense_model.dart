import '../../domain/entities/group_expense_entity.dart';

class GroupExpenseModel extends GroupExpense {
  const GroupExpenseModel({
    required super.id,
    required super.groupId,
    required super.description,
    required super.amount,
    required super.paidBy,
    super.paidByName,
    required super.date,
    super.category,
    super.notes,
    required super.splitType,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GroupExpenseModel.fromJson(Map<String, dynamic> json) {
    return GroupExpenseModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paid_by'] as String,
      paidByName: json['paid_by_name'] as String?,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      splitType: SplitType.fromString(json['split_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'description': description,
      'amount': amount,
      'paid_by': paidBy,
      'paid_by_name': paidByName,
      'date': date.toIso8601String().split('T')[0],
      'category': category,
      'notes': notes,
      'split_type': splitType.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
