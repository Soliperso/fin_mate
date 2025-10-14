import '../entities/savings_goal_entity.dart';
import '../entities/goal_contribution_entity.dart';

abstract class SavingsGoalRepository {
  // Goals
  Future<List<SavingsGoal>> getGoals();
  Future<SavingsGoal> getGoalById(String goalId);
  Future<SavingsGoal> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    String? color,
  });
  Future<void> updateGoal({
    required String goalId,
    String? name,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    String? color,
  });
  Future<void> deleteGoal(String goalId);
  Future<void> markGoalAsCompleted(String goalId);

  // Contributions
  Future<List<GoalContribution>> getGoalContributions(String goalId);
  Future<GoalContribution> addContribution({
    required String goalId,
    required double amount,
    String? notes,
    String? transactionId,
  });
  Future<void> deleteContribution(String contributionId);

  // Summary
  Future<Map<String, dynamic>> getGoalsSummary();
}
