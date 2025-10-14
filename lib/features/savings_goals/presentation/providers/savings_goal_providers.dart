import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/savings_goal_remote_datasource.dart';
import '../../data/repositories/savings_goal_repository_impl.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/goal_contribution_entity.dart';
import '../../domain/repositories/savings_goal_repository.dart';

// Repository provider
final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepositoryImpl(
    remoteDatasource: SavingsGoalRemoteDatasource(),
  );
});

// Goals list provider
final savingsGoalsProvider = FutureProvider<List<SavingsGoal>>((ref) async {
  final repository = ref.watch(savingsGoalRepositoryProvider);
  return await repository.getGoals();
});

// Single goal provider
final goalProvider = FutureProvider.family<SavingsGoal, String>((ref, goalId) async {
  final repository = ref.watch(savingsGoalRepositoryProvider);
  return await repository.getGoalById(goalId);
});

// Goal contributions provider
final goalContributionsProvider = FutureProvider.family<List<GoalContribution>, String>((ref, goalId) async {
  final repository = ref.watch(savingsGoalRepositoryProvider);
  return await repository.getGoalContributions(goalId);
});

// Goals summary provider
final goalsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(savingsGoalRepositoryProvider);
  return await repository.getGoalsSummary();
});

// Goal operations notifier
class GoalOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final SavingsGoalRepository repository;

  GoalOperationsNotifier(this.repository) : super(const AsyncValue.data(null));

  Future<SavingsGoal?> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    String? color,
  }) async {
    state = const AsyncValue.loading();
    try {
      final goal = await repository.createGoal(
        name: name,
        description: description,
        targetAmount: targetAmount,
        deadline: deadline,
        category: category,
        icon: icon,
        color: color,
      );
      state = const AsyncValue.data(null);
      return goal;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> updateGoal({
    required String goalId,
    String? name,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    String? color,
  }) async {
    state = const AsyncValue.loading();
    try {
      await repository.updateGoal(
        goalId: goalId,
        name: name,
        description: description,
        targetAmount: targetAmount,
        deadline: deadline,
        category: category,
        icon: icon,
        color: color,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    state = const AsyncValue.loading();
    try {
      await repository.deleteGoal(goalId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> markGoalAsCompleted(String goalId) async {
    state = const AsyncValue.loading();
    try {
      await repository.markGoalAsCompleted(goalId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<GoalContribution?> addContribution({
    required String goalId,
    required double amount,
    String? notes,
    String? transactionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final contribution = await repository.addContribution(
        goalId: goalId,
        amount: amount,
        notes: notes,
        transactionId: transactionId,
      );
      state = const AsyncValue.data(null);
      return contribution;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> deleteContribution(String contributionId) async {
    state = const AsyncValue.loading();
    try {
      await repository.deleteContribution(contributionId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final goalOperationsProvider = StateNotifierProvider<GoalOperationsNotifier, AsyncValue<void>>((ref) {
  return GoalOperationsNotifier(ref.watch(savingsGoalRepositoryProvider));
});
