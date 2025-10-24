import 'package:equatable/equatable.dart';

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }
}

class RecurringTransactionEntity extends Equatable {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final String? categoryName;
  final String type; // 'income', 'expense', 'transfer'
  final double amount;
  final String? description;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextOccurrence;
  final bool isActive;
  final String? toAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RecurringTransactionEntity({
    required this.id,
    required this.userId,
    required this.accountId,
    this.categoryId,
    this.categoryName,
    required this.type,
    required this.amount,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextOccurrence,
    required this.isActive,
    this.toAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Days until next occurrence
  int get daysUntilDue => nextOccurrence.difference(DateTime.now()).inDays;

  /// Whether this recurring transaction is overdue
  bool get isOverdue => nextOccurrence.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        userId,
        accountId,
        categoryId,
        categoryName,
        type,
        amount,
        description,
        frequency,
        startDate,
        endDate,
        nextOccurrence,
        isActive,
        toAccountId,
        createdAt,
        updatedAt,
      ];
}
