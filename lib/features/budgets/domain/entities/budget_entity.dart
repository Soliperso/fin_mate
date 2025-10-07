import 'package:equatable/equatable.dart';

/// Budget period enum
enum BudgetPeriod {
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
    }
  }
}

/// Budget entity
class BudgetEntity extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated from joins
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  // Calculated fields (not from database)
  final double? spent;
  final double? remaining;

  const BudgetEntity({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.spent,
    this.remaining,
  });

  /// Get the percentage of budget spent (0-100+)
  double get spentPercentage {
    if (spent == null || amount == 0) return 0;
    return (spent! / amount) * 100;
  }

  /// Check if budget is exceeded
  bool get isExceeded {
    if (spent == null) return false;
    return spent! > amount;
  }

  /// Check if budget is close to limit (>= 80%)
  bool get isNearLimit {
    return spentPercentage >= 80 && !isExceeded;
  }

  /// Get the current period end date based on period and start date
  DateTime get currentPeriodEnd {
    if (endDate != null && endDate!.isBefore(DateTime.now())) {
      return endDate!;
    }

    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.weekly:
        return DateTime(
          startDate.year,
          startDate.month,
          startDate.day + 7,
        );
      case BudgetPeriod.monthly:
        return DateTime(
          now.year,
          now.month + 1,
          0,
        );
      case BudgetPeriod.yearly:
        return DateTime(
          now.year,
          12,
          31,
        );
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        amount,
        period,
        startDate,
        endDate,
        isActive,
        createdAt,
        updatedAt,
        categoryName,
        categoryIcon,
        categoryColor,
        spent,
        remaining,
      ];

  BudgetEntity copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    double? spent,
    double? remaining,
  }) {
    return BudgetEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
    );
  }
}
