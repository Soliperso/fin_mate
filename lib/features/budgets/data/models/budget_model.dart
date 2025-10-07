import '../../domain/entities/budget_entity.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String? categoryId;
  final double amount;
  final String period;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final double? spent;
  final double? remaining;

  BudgetModel({
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

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: (json['amount'] as num).toDouble(),
      period: json['period'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      categoryName: json['category_name'],
      categoryIcon: json['category_icon'],
      categoryColor: json['category_color'],
      spent: json['spent'] != null ? (json['spent'] as num).toDouble() : null,
      remaining: json['remaining'] != null ? (json['remaining'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'is_active': isActive,
    };
  }

  BudgetEntity toEntity() {
    return BudgetEntity(
      id: id,
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      period: _parsePeriod(period),
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      spent: spent,
      remaining: remaining,
    );
  }

  static BudgetModel fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      userId: entity.userId,
      categoryId: entity.categoryId,
      amount: entity.amount,
      period: entity.period.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      categoryName: entity.categoryName,
      categoryIcon: entity.categoryIcon,
      categoryColor: entity.categoryColor,
      spent: entity.spent,
      remaining: entity.remaining,
    );
  }

  static BudgetPeriod _parsePeriod(String period) {
    switch (period.toLowerCase()) {
      case 'weekly':
        return BudgetPeriod.weekly;
      case 'monthly':
        return BudgetPeriod.monthly;
      case 'yearly':
        return BudgetPeriod.yearly;
      default:
        return BudgetPeriod.monthly;
    }
  }
}
