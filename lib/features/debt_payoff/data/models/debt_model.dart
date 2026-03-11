import '../../domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.debtType,
    required super.balance,
    required super.interestRate,
    required super.minimumPayment,
    super.dueDay,
    super.isActive,
    super.notes,
    super.originalBalance,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      debtType: json['debt_type'] as String? ?? 'credit_card',
      balance: (json['balance'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      minimumPayment: (json['minimum_payment'] as num).toDouble(),
      dueDay: json['due_day'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      originalBalance: json['original_balance'] != null
          ? (json['original_balance'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
