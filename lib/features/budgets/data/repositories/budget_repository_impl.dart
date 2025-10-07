import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_remote_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDataSource _remoteDataSource;

  BudgetRepositoryImpl({
    BudgetRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? BudgetRemoteDataSource();

  @override
  Future<List<BudgetEntity>> getBudgets({bool? isActive}) async {
    try {
      final budgets = await _remoteDataSource.getBudgets(isActive: isActive);
      return budgets.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> getBudgetById(String id) async {
    try {
      final budget = await _remoteDataSource.getBudgetById(id);
      return budget.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> createBudget(BudgetEntity budget) async {
    try {
      final model = BudgetModel.fromEntity(budget);
      final created = await _remoteDataSource.createBudget(model);
      return created.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<BudgetEntity> updateBudget(String id, BudgetEntity budget) async {
    try {
      final model = BudgetModel.fromEntity(budget);
      final updated = await _remoteDataSource.updateBudget(id, model);
      return updated.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _remoteDataSource.deleteBudget(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<BudgetEntity>> getBudgetsByCategory(String categoryId) async {
    try {
      final budgets = await _remoteDataSource.getBudgetsByCategory(categoryId);
      return budgets.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<double> calculateSpending(BudgetEntity budget) async {
    try {
      return await _remoteDataSource.calculateSpending(
        categoryId: budget.categoryId,
        startDate: budget.startDate,
        endDate: budget.currentPeriodEnd,
      );
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<List<BudgetEntity>> getBudgetsWithSpending() async {
    try {
      // Get all active budgets
      final budgets = await getBudgets(isActive: true);

      // Calculate spending for each budget
      final budgetsWithSpending = await Future.wait(
        budgets.map((budget) async {
          final spent = await calculateSpending(budget);
          final remaining = budget.amount - spent;

          return budget.copyWith(
            spent: spent,
            remaining: remaining,
          );
        }),
      );

      return budgetsWithSpending;
    } catch (e) {
      rethrow;
    }
  }
}
