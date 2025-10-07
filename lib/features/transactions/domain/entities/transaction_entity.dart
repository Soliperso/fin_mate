import 'package:equatable/equatable.dart';

/// Transaction type enum
enum TransactionType {
  income,
  expense,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}

/// Transaction entity
class TransactionEntity extends Equatable {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final TransactionType type;
  final double amount;
  final String? description;
  final String? notes;
  final DateTime date;
  final bool isRecurring;
  final String? recurringInterval;
  final String? toAccountId; // For transfers
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated from joins
  final String? categoryName;
  final String? accountName;
  final String? toAccountName;

  const TransactionEntity({
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

  @override
  List<Object?> get props => [
        id,
        userId,
        accountId,
        categoryId,
        type,
        amount,
        description,
        notes,
        date,
        isRecurring,
        recurringInterval,
        toAccountId,
        tags,
        createdAt,
        updatedAt,
      ];

  TransactionEntity copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? description,
    String? notes,
    DateTime? date,
    bool? isRecurring,
    String? recurringInterval,
    String? toAccountId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? accountName,
    String? toAccountName,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      toAccountId: toAccountId ?? this.toAccountId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      accountName: accountName ?? this.accountName,
      toAccountName: toAccountName ?? this.toAccountName,
    );
  }
}
