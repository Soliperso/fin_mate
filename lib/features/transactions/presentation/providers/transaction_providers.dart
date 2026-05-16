import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../data/datasources/transaction_remote_datasource.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// Data Source Provider
final transactionDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
  return TransactionRemoteDataSource();
});

// Repository Provider
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  ref.watch(userSessionProvider);
  return TransactionRepositoryImpl(ref.read(transactionDataSourceProvider));
});

// Transactions Provider (monthly)
final transactionsProvider =
    FutureProvider.family<List<TransactionEntity>, DateTime>(
        (ref, month) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final startDate = DateTime(month.year, month.month, 1);
  final endDate = DateTime(month.year, month.month + 1, 0);

  return await repository.getTransactions(
    startDate: startDate,
    endDate: endDate,
  );
});

// Recent Transactions Provider
final recentTransactionsProvider =
    FutureProvider<List<TransactionEntity>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getRecentTransactions(limit: 10);
});

// Accounts Provider
final accountsProvider = FutureProvider<List<AccountEntity>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getAccounts();
});

// Categories Provider
final categoriesProvider =
    FutureProvider.family<List<CategoryEntity>, String?>((ref, type) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getCategories(type: type);
});

// Transaction Monthly Stats Provider
final transactionMonthlyStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
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
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, type) async {
  final repository = ref.watch(transactionRepositoryProvider);
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
  final String selectedPeriod; // 'All', 'Today', 'Week', 'Month', 'Year'
  final bool hideFutureTransactions;
  final bool showNotes;

  final bool isLoadingMore;
  final bool hasMore;

  const TransactionListState({
    this.transactions = const [],
    this.filteredTransactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.selectedCategory,
    this.dateRange,
    this.minAmount,
    this.maxAmount,
    this.selectedPeriod = 'All',
    this.hideFutureTransactions = false,
    this.showNotes = false,
  });

  TransactionListState copyWith({
    List<TransactionEntity>? transactions,
    List<TransactionEntity>? filteredTransactions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? selectedFilter,
    String? searchQuery,
    String? selectedCategory,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    String? selectedPeriod,
    bool? hideFutureTransactions,
    bool? showNotes,
    bool clearCategory = false,
    bool clearDateRange = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      hideFutureTransactions:
          hideFutureTransactions ?? this.hideFutureTransactions,
      showNotes: showNotes ?? this.showNotes,
    );
  }

  /// Transactions grouped by date string, sorted newest-first.
  /// Computed once per state update — not on every build().
  Map<String, List<TransactionEntity>> get groupedByDate {
    final sorted = [...filteredTransactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final grouped = <String, List<TransactionEntity>>{};
    for (final tx in sorted) {
      final key = DateFormat(AppDateFormats.fullDate).format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  bool get hasActiveFilters =>
      selectedCategory != null ||
      dateRange != null ||
      minAmount != null ||
      maxAmount != null ||
      hideFutureTransactions ||
      selectedPeriod != 'All' ||
      selectedFilter != 'All';

  int get activeFilterCount =>
      (selectedCategory != null ? 1 : 0) +
      // Only count dateRange if it was set manually (not via a period chip)
      (dateRange != null && selectedPeriod == 'All' ? 1 : 0) +
      (minAmount != null || maxAmount != null ? 1 : 0) +
      (hideFutureTransactions ? 1 : 0) +
      (selectedPeriod != 'All' ? 1 : 0) +
      (selectedFilter != 'All' ? 1 : 0);
}

/// Transaction list notifier with filtering and search
class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final TransactionRepository _repository;

  static const _pageSize = 50;
  int _currentOffset = 0;

  TransactionListNotifier(this._repository)
      : super(const TransactionListState()) {
    loadTransactions();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 2, 1);
  }

  DateTime get _endDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  Future<void> loadTransactions() async {
    _currentOffset = 0;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transactions = await _repository.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
        limit: _pageSize,
        offset: 0,
      );
      _currentOffset = transactions.length;
      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        hasMore: transactions.length == _pageSize,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await _repository.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
        limit: _pageSize,
        offset: _currentOffset,
      );
      _currentOffset += more.length;
      state = state.copyWith(
        transactions: [...state.transactions, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      );
      _applyFilters();
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async => loadTransactions();

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    _applyFilters();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setCategory(String? category) {
    state = state.copyWith(
        selectedCategory: category, clearCategory: category == null);
    _applyFilters();
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: range, clearDateRange: range == null);
    _applyFilters();
  }

  void setAmountRange(double? min, double? max) {
    state = state.copyWith(
      minAmount: min,
      maxAmount: max,
      clearMinAmount: min == null,
      clearMaxAmount: max == null,
    );
    _applyFilters();
  }

  void setPeriod(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange? range;
    switch (period) {
      case 'Today':
        range = DateTimeRange(start: today, end: today);
        break;
      case 'Week':
        range = DateTimeRange(
          start: today.subtract(Duration(days: today.weekday - 1)),
          end: today,
        );
        break;
      case 'Month':
        range =
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
        break;
      case 'Year':
        range = DateTimeRange(start: DateTime(now.year, 1, 1), end: today);
        break;
      default:
        range = null;
    }
    state = state.copyWith(
      selectedPeriod: period,
      dateRange: range,
      clearDateRange: range == null,
    );
    _applyFilters();
  }

  void setHideFutureTransactions(bool hide) {
    state = state.copyWith(hideFutureTransactions: hide);
    _applyFilters();
  }

  void toggleShowNotes() {
    state = state.copyWith(showNotes: !state.showNotes);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      dateRange: null,
      minAmount: null,
      maxAmount: null,
      selectedPeriod: 'All',
      hideFutureTransactions: false,
      clearCategory: true,
      clearDateRange: true,
      clearMinAmount: true,
      clearMaxAmount: true,
    );
    _applyFilters();
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _repository.deleteTransaction(transactionId);
      final updated =
          state.transactions.where((t) => t.id != transactionId).toList();
      state = state.copyWith(transactions: updated);
      _applyFilters();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMultipleTransactions(List<String> ids) async {
    if (ids.isEmpty) return true;
    try {
      await _repository.deleteMultipleTransactions(ids);
      final idSet = ids.toSet();
      final updated =
          state.transactions.where((t) => !idSet.contains(t.id)).toList();
      state = state.copyWith(transactions: updated);
      _applyFilters();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _applyFilters() {
    var filtered = List<TransactionEntity>.from(state.transactions);

    if (state.hideFutureTransactions) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      filtered = filtered.where((t) {
        final txDate = DateTime(t.date.year, t.date.month, t.date.day);
        return !txDate.isAfter(todayDate);
      }).toList();
    }

    if (state.selectedFilter != 'All') {
      filtered = filtered.where((t) {
        if (state.selectedFilter == 'Income')
          return t.type == TransactionType.income;
        if (state.selectedFilter == 'Expense')
          return t.type == TransactionType.expense;
        if (state.selectedFilter == 'Transfer')
          return t.type == TransactionType.transfer;
        return true;
      }).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final description = (t.description ?? '').toLowerCase();
        final category = (t.categoryName ?? '').toLowerCase();
        return description.contains(query) || category.contains(query);
      }).toList();
    }

    if (state.selectedCategory != null) {
      filtered = filtered
          .where((t) => t.categoryName == state.selectedCategory)
          .toList();
    }

    if (state.dateRange != null) {
      filtered = filtered.where((t) {
        return t.date.isAfter(
                state.dateRange!.start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(state.dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

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
