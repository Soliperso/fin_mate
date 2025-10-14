import 'package:equatable/equatable.dart';

class SavingsGoal extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? category;
  final String? icon;
  final String? color;
  final bool isShared;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.category,
    this.icon,
    this.color,
    this.isShared = false,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get remainingAmount => (targetAmount - currentAmount).clamp(0, double.infinity);

  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    final difference = deadline!.difference(now).inDays;
    return difference >= 0 ? difference : 0;
  }

  bool get isOverdue {
    if (deadline == null || isCompleted) return false;
    return DateTime.now().isAfter(deadline!);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        targetAmount,
        currentAmount,
        deadline,
        category,
        icon,
        color,
        isShared,
        isCompleted,
        completedAt,
        createdAt,
        updatedAt,
      ];
}
