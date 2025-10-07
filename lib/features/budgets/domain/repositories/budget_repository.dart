import '../entities/budget_entity.dart';

/// Repository interface for budget operations
abstract class BudgetRepository {
  /// Get all budgets for the current user
  ///
  /// Optionally filter by [isActive] status
  /// Returns budgets with calculated spending data
  Future<List<BudgetEntity>> getBudgets({bool? isActive});

  /// Get a specific budget by ID
  Future<BudgetEntity> getBudgetById(String id);

  /// Create a new budget
  Future<BudgetEntity> createBudget(BudgetEntity budget);

  /// Update an existing budget
  Future<BudgetEntity> updateBudget(String id, BudgetEntity budget);

  /// Delete a budget
  Future<void> deleteBudget(String id);

  /// Get budgets for a specific category
  Future<List<BudgetEntity>> getBudgetsByCategory(String categoryId);

  /// Calculate spending for a budget within its current period
  ///
  /// Returns the total amount spent in the budget's category
  /// during the current budget period
  Future<double> calculateSpending(BudgetEntity budget);

  /// Get all budgets with spending calculations
  ///
  /// This is the main method for displaying budgets in the UI
  /// as it includes real-time spending data
  Future<List<BudgetEntity>> getBudgetsWithSpending();
}
