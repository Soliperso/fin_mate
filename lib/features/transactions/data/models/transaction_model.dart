import '../../domain/entities/transaction_entity.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final String type;
  final double amount;
  final String? description;
  final String? notes;
  final DateTime date;
  final bool isRecurring;
  final String? recurringInterval;
  final String? toAccountId;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryName;
  final String? accountName;
  final String? toAccountName;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.accountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    this.notes,
    required this.date,
    this.isRecurring = false,
    this.recurringInterval,
    this.toAccountId,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.accountName,
    this.toAccountName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      accountId: json['account_id'],
      categoryId: json['category_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      notes: json['notes'],
      date: DateTime.parse(json['date']),
      isRecurring: json['is_recurring'] ?? false,
      recurringInterval: json['recurring_interval'],
      toAccountId: json['to_account_id'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      categoryName: json['category_name'],
      accountName: json['account_name'],
      toAccountName: json['to_account_name'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'to_account_id': toAccountId,
      'tags': tags,
    };

    // These columns don't exist in the current database schema
    // 'notes' field doesn't exist - using 'description' instead
    // 'recurring_interval' doesn't exist in transactions table (only in recurring_transactions)

    return json;
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      type: _parseType(type),
      amount: amount,
      description: description,
      notes: notes,
      date: date,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      toAccountId: toAccountId,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      categoryName: categoryName,
      accountName: accountName,
      toAccountName: toAccountName,
    );
  }

  static TransactionModel fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      accountId: entity.accountId,
      categoryId: entity.categoryId,
      type: entity.type.name,
      amount: entity.amount,
      description: entity.description,
      notes: entity.notes,
      date: entity.date,
      isRecurring: entity.isRecurring,
      recurringInterval: entity.recurringInterval,
      toAccountId: entity.toAccountId,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      categoryName: entity.categoryName,
      accountName: entity.accountName,
      toAccountName: entity.toAccountName,
    );
  }

  static TransactionType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }
}
