import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/goal_contribution_entity.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../datasources/savings_goal_remote_datasource.dart';

class SavingsGoalRepositoryImpl implements SavingsGoalRepository {
  final SavingsGoalRemoteDatasource remoteDatasource;

  SavingsGoalRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<SavingsGoal>> getGoals() async {
    return await remoteDatasource.getGoals();
  }

  @override
  Future<SavingsGoal> getGoalById(String goalId) async {
    return await remoteDatasource.getGoalById(goalId);
  }

  @override
  Future<SavingsGoal> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    String? color,
  }) async {
    return await remoteDatasource.createGoal(
      name: name,
      description: description,
      targetAmount: targetAmount,
      deadline: deadline,
      category: category,
      icon: icon,
      color: color,
    );
  }

  @override
  Future<void> updateGoal({
    required String goalId,
    String? name,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    String? color,
  }) async {
    return await remoteDatasource.updateGoal(
      goalId: goalId,
      name: name,
      description: description,
      targetAmount: targetAmount,
      deadline: deadline,
      category: category,
      icon: icon,
      color: color,
    );
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    return await remoteDatasource.deleteGoal(goalId);
  }

  @override
  Future<void> markGoalAsCompleted(String goalId) async {
    return await remoteDatasource.markGoalAsCompleted(goalId);
  }

  @override
  Future<List<GoalContribution>> getGoalContributions(String goalId) async {
    return await remoteDatasource.getGoalContributions(goalId);
  }

  @override
  Future<GoalContribution> addContribution({
    required String goalId,
    required double amount,
    String? notes,
    String? transactionId,
  }) async {
    return await remoteDatasource.addContribution(
      goalId: goalId,
      amount: amount,
      notes: notes,
      transactionId: transactionId,
    );
  }

  @override
  Future<void> deleteContribution(String contributionId) async {
    return await remoteDatasource.deleteContribution(contributionId);
  }

  @override
  Future<Map<String, dynamic>> getGoalsSummary() async {
    return await remoteDatasource.getGoalsSummary();
  }
}
