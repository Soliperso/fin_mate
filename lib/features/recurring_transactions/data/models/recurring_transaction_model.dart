import '../../domain/entities/recurring_transaction_entity.dart';

class RecurringTransactionModel extends RecurringTransactionEntity {
  const RecurringTransactionModel({
    required super.id,
    required super.userId,
    required super.accountId,
    super.categoryId,
    super.categoryName,
    required super.type,
    required super.amount,
    super.description,
    required super.frequency,
    required super.startDate,
    super.endDate,
    required super.nextOccurrence,
    required super.isActive,
    super.toAccountId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      frequency: _parseFrequency(json['frequency'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      nextOccurrence: DateTime.parse(json['next_occurrence'] as String),
      isActive: json['is_active'] as bool,
      toAccountId: json['to_account_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'next_occurrence': nextOccurrence.toIso8601String().split('T')[0],
      'is_active': isActive,
      'to_account_id': toAccountId,
    };
  }

  RecurringTransactionEntity toEntity() => this;

  static RecurringFrequency _parseFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return RecurringFrequency.daily;
      case 'weekly':
        return RecurringFrequency.weekly;
      case 'monthly':
        return RecurringFrequency.monthly;
      case 'yearly':
        return RecurringFrequency.yearly;
      default:
        return RecurringFrequency.monthly;
    }
  }
}
