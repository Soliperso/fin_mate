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

  // Carry-over fields
  final bool carryOverEnabled;
  final double lastCarryOverAmount;

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
    this.carryOverEnabled = false,
    this.lastCarryOverAmount = 0,
    this.spent,
    this.remaining,
  });

  /// Effective budget = base amount + carry-over (positive = surplus, negative = deficit)
  double get effectiveAmount =>
      amount + (carryOverEnabled ? lastCarryOverAmount : 0);

  /// Get the percentage of budget spent (0-100+)
  double get spentPercentage {
    if (spent == null || effectiveAmount == 0) return 0;
    return (spent! / effectiveAmount) * 100;
  }

  /// Check if budget is exceeded
  bool get isExceeded {
    if (spent == null) return false;
    return spent! > effectiveAmount;
  }

  /// Check if budget is close to limit (>= 80%)
  bool get isNearLimit {
    return spentPercentage >= 80 && !isExceeded;
  }

  /// Get the current period end date based on period and start date
  /// For recurring budgets (weekly, monthly, yearly), ignores stored endDate
  /// and always calculates the CURRENT period based on today's date
  DateTime get currentPeriodEnd {
    final now = DateTime.now();

    // For recurring budgets, always calculate based on current date, not stored endDate
    switch (period) {
      case BudgetPeriod.weekly:
        // End of current week (7 days from start of week)
        final dayOfWeek = now.weekday;
        final daysUntilEndOfWeek = 7 - dayOfWeek;
        return now.add(Duration(days: daysUntilEndOfWeek));

      case BudgetPeriod.monthly:
        // Last day of current month
        return DateTime(
          now.year,
          now.month + 1,
          0,
        );

      case BudgetPeriod.yearly:
        // Last day of current year
        return DateTime(
          now.year,
          12,
          31,
        );
    }
  }

  /// Get the current period start date based on period and start date
  /// For recurring budgets, this aligns to the current period
  DateTime get currentPeriodStart {
    final now = DateTime.now();

    switch (period) {
      case BudgetPeriod.weekly:
        // Start of current week (previous Sunday or same day)
        final dayOfWeek = now.weekday;
        return now.subtract(Duration(days: dayOfWeek - 1));

      case BudgetPeriod.monthly:
        // First day of current month
        return DateTime(now.year, now.month, 1);

      case BudgetPeriod.yearly:
        // First day of current year
        return DateTime(now.year, 1, 1);
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
        carryOverEnabled,
        lastCarryOverAmount,
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
    bool? carryOverEnabled,
    double? lastCarryOverAmount,
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
      carryOverEnabled: carryOverEnabled ?? this.carryOverEnabled,
      lastCarryOverAmount: lastCarryOverAmount ?? this.lastCarryOverAmount,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
    );
  }
}
