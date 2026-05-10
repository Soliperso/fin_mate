import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for budget repository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  ref.watch(userSessionProvider);
  return BudgetRepositoryImpl();
});

/// Provider for budgets with spending data
///
/// This is the main provider for displaying budgets in the UI
/// as it includes real-time spending calculations
final budgetsWithSpendingProvider =
    FutureProvider<List<BudgetEntity>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getBudgetsWithSpending();
});

/// State notifier for budget management
class BudgetNotifier extends StateNotifier<AsyncValue<List<BudgetEntity>>> {
  final BudgetRepository _repository;
  final AnalyticsService _analytics;
  final Ref _ref;

  BudgetNotifier(this._repository, this._analytics, this._ref)
      : super(const AsyncValue.loading()) {
    loadBudgets();
  }

  /// Load all budgets with spending data
  Future<void> loadBudgets() async {
    state = const AsyncValue.loading();
    try {
      final budgets = await _repository.getBudgetsWithSpending();
      state = AsyncValue.data(budgets);
      _ref.invalidate(budgetsWithSpendingProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh budgets
  Future<void> refresh() async {
    await loadBudgets();
  }

  /// Create a new budget
  Future<void> createBudget(BudgetEntity budget) async {
    try {
      final created = await _repository.createBudget(budget);
      unawaited(_analytics.trackBudgetCreated(
        budgetId: created.id,
        amount: created.amount,
        category: created.categoryName,
      ));
      await loadBudgets();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Update an existing budget
  Future<void> updateBudget(String id, BudgetEntity budget) async {
    try {
      await _repository.updateBudget(id, budget);
      unawaited(_analytics.trackBudgetUpdated(budgetId: id));
      await loadBudgets();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Delete a budget
  Future<void> deleteBudget(String id) async {
    try {
      await _repository.deleteBudget(id);
      unawaited(_analytics.trackBudgetDeleted(budgetId: id));
      await loadBudgets();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

/// Provider for budget notifier
final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<List<BudgetEntity>>>(
        (ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return BudgetNotifier(repository, analytics, ref);
});
