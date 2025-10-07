import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/transaction_repository.dart';

// Data Source Provider
final transactionDataSourceProvider = Provider<TransactionRemoteDataSource>((ref) {
  return TransactionRemoteDataSource();
});

// Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.read(transactionDataSourceProvider));
});

// Transactions Provider (monthly)
final transactionsProvider =
    FutureProvider.family<List<TransactionEntity>, DateTime>((ref, month) async {
  final repository = ref.read(transactionRepositoryProvider);
  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0);

  return await repository.getTransactions(
    startDate: startDate,
    endDate: endDate,
  );
});

// Recent Transactions Provider
final recentTransactionsProvider = FutureProvider<List<TransactionEntity>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getRecentTransactions(limit: 10);
});

// Accounts Provider
final accountsProvider = FutureProvider<List<AccountEntity>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getAccounts();
});

// Categories Provider
final categoriesProvider = FutureProvider.family<List<CategoryEntity>, String?>((ref, type) async {
  final repository = ref.read(transactionRepositoryProvider);
  return await repository.getCategories(type: type);
});

// Dashboard Stats Provider
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(transactionRepositoryProvider);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0);

  return await repository.getDashboardStats(
    startDate: startDate,
    endDate: endDate,
  );
});

// Category Breakdown Provider (for charts)
final categoryBreakdownProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, type) async {
  final repository = ref.read(transactionRepositoryProvider);
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0);

  return await repository.getCategoryBreakdown(
    startDate: startDate,
    endDate: endDate,
    type: type,
  );
});

/// Transaction list state with filters
class TransactionListState {
  final List<TransactionEntity> transactions;
  final List<TransactionEntity> filteredTransactions;
  final bool isLoading;
  final String? error;
  final String selectedFilter; // 'All', 'Income', 'Expense', 'Transfer'
  final String searchQuery;
  final String? selectedCategory;
  final DateTimeRange? dateRange;
  final double? minAmount;
  final double? maxAmount;

  const TransactionListState({
    this.transactions = const [],
    this.filteredTransactions = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.selectedCategory,
    this.dateRange,
    this.minAmount,
    this.maxAmount,
  });

  TransactionListState copyWith({
    List<TransactionEntity>? transactions,
    List<TransactionEntity>? filteredTransactions,
    bool? isLoading,
    String? error,
    String? selectedFilter,
    String? searchQuery,
    String? selectedCategory,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    bool clearCategory = false,
    bool clearDateRange = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  bool get hasActiveFilters =>
      selectedCategory != null ||
      dateRange != null ||
      minAmount != null ||
      maxAmount != null;
}

/// Transaction list notifier with filtering and search
class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final TransactionRepository _repository;

  TransactionListNotifier(this._repository) : super(const TransactionListState()) {
    loadTransactions();
  }

  /// Load all transactions (last 3 months)
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - 2, 1); // Last 3 months
      final endDate = DateTime(now.year, now.month + 1, 0);

      final transactions = await _repository.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
      );

      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh transactions
  Future<void> refresh() async {
    await loadTransactions();
  }

  /// Update filter type (All, Income, Expense, Transfer)
  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    _applyFilters();
  }

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Update category filter
  void setCategory(String? category) {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
    _applyFilters();
  }

  /// Update date range filter
  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(
      dateRange: range,
      clearDateRange: range == null,
    );
    _applyFilters();
  }

  /// Update amount range filter
  void setAmountRange(double? min, double? max) {
    state = state.copyWith(
      minAmount: min,
      maxAmount: max,
      clearMinAmount: min == null,
      clearMaxAmount: max == null,
    );
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      dateRange: null,
      minAmount: null,
      maxAmount: null,
      clearCategory: true,
      clearDateRange: true,
      clearMinAmount: true,
      clearMaxAmount: true,
    );
    _applyFilters();
  }

  /// Delete a transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _repository.deleteTransaction(transactionId);

      // Remove from local state
      final updatedTransactions = state.transactions
          .where((t) => t.id != transactionId)
          .toList();

      state = state.copyWith(transactions: updatedTransactions);
      _applyFilters();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Apply all active filters
  void _applyFilters() {
    var filtered = List<TransactionEntity>.from(state.transactions);

    // Filter by type
    if (state.selectedFilter != 'All') {
      filtered = filtered.where((t) {
        if (state.selectedFilter == 'Income') return t.type == TransactionType.income;
        if (state.selectedFilter == 'Expense') return t.type == TransactionType.expense;
        if (state.selectedFilter == 'Transfer') return t.type == TransactionType.transfer;
        return true;
      }).toList();
    }

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final description = (t.description ?? '').toLowerCase();
        final category = (t.categoryName ?? '').toLowerCase();
        return description.contains(query) || category.contains(query);
      }).toList();
    }

    // Filter by category
    if (state.selectedCategory != null) {
      filtered = filtered.where((t) => t.categoryName == state.selectedCategory).toList();
    }

    // Filter by date range
    if (state.dateRange != null) {
      filtered = filtered.where((t) {
        return t.date.isAfter(state.dateRange!.start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(state.dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by amount range
    if (state.minAmount != null || state.maxAmount != null) {
      filtered = filtered.where((t) {
        final amount = t.amount.abs();
        if (state.minAmount != null && amount < state.minAmount!) return false;
        if (state.maxAmount != null && amount > state.maxAmount!) return false;
        return true;
      }).toList();
    }

    state = state.copyWith(filteredTransactions: filtered);
  }
}

/// Provider for transaction list with filtering
final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionListNotifier(repository);
});
