import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/ads/ad_banner_widget.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh transactions when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionListProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider);
    final notifier = ref.read(transactionListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                    ),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color ?? AppColors.cardBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
                ),
                onChanged: (value) {
                  notifier.setSearchQuery(value);
                },
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? CupertinoIcons.xmark : CupertinoIcons.search,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  notifier.setSearchQuery('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 22,
              color: state.hasActiveFilters ? AppColors.brandTeal : null,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? ListView(
                    padding: const EdgeInsets.all(AppSizes.md),
                    children: const [
                      SkeletonCard(height: 72),
                      SizedBox(height: AppSizes.sm),
                      SkeletonCard(height: 72),
                      SizedBox(height: AppSizes.sm),
                      SkeletonCard(height: 72),
                      SizedBox(height: AppSizes.sm),
                      SkeletonCard(height: 72),
                      SizedBox(height: AppSizes.sm),
                      SkeletonCard(height: 72),
                    ],
                  )
                : state.transactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EmptyStateCard(
                              icon: CupertinoIcons.doc_text,
                              title: 'No Transactions Yet',
                              message:
                                  'Start by adding your first transaction to begin tracking your finances.',
                              backgroundColor: AppColors.brandTeal,
                            ),
                            const SizedBox(height: AppSizes.lg),
                            SizedBox(
                              width: double.infinity,
                              height: AppSizes.buttonHeightMd,
                              child: ElevatedButton.icon(
                                onPressed: () => context.go('/transactions/add'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                  ),
                                ),
                                icon: const Icon(CupertinoIcons.add, size: 20),
                                label: const Text(
                                  'Add Transaction',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Period selector
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSizes.md, AppSizes.sm, AppSizes.md, 0,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['All', 'Today', 'Week', 'Month', 'Year']
                                    .map((period) => _buildPeriodChip(
                                          context, period, state.selectedPeriod, notifier))
                                    .toList(),
                              ),
                            ),
                          ),

                          // Type filter chips
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                              vertical: AppSizes.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildFilterChip(context, 'All', state.selectedFilter, notifier)),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(child: _buildFilterChip(context, 'Income', state.selectedFilter, notifier)),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(child: _buildFilterChip(context, 'Expense', state.selectedFilter, notifier)),
                              ],
                            ),
                          ),

                          // Income / Expense summary row
                          _buildSummaryRow(context, state),

                          Divider(
                            height: 1,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.separatorDark
                                : AppColors.separator,
                          ),

                          // Transactions list
                          Expanded(
                            child: _buildTransactionsList(state, notifier),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String filter,
    String selectedFilter,
    TransactionListNotifier notifier,
  ) {
    final isSelected = filter == selectedFilter;
    return FilterChip(
      label: SizedBox(
        width: double.infinity,
        child: Text(filter, textAlign: TextAlign.center),
      ),
      selected: isSelected,
      onSelected: (selected) {
        notifier.setFilter(filter);
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.brandTeal.withValues(alpha: 0.2),
      checkmarkColor: Colors.transparent,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.brandTeal : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.brandTeal : Colors.transparent,
      ),
    );
  }

  Widget _buildPeriodChip(
    BuildContext context,
    String period,
    String selectedPeriod,
    TransactionListNotifier notifier,
  ) {
    final isSelected = period == selectedPeriod;
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: GestureDetector(
        onTap: () => notifier.setPeriod(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandTeal
                : AppColors.brandTeal.withValues(alpha: 0.0),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandTeal
                  : AppColors.textSecondary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            period,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  double _totalIncome(List<TransactionEntity> txns) =>
      txns.where((t) => t.type == TransactionType.income).fold(0.0, (s, t) => s + t.amount);

  double _totalExpense(List<TransactionEntity> txns) =>
      txns.where((t) => t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);

  Widget _buildSummaryRow(BuildContext context, TransactionListState state) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final income = _totalIncome(state.filteredTransactions);
    final expense = _totalExpense(state.filteredTransactions);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.sm),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: AppColors.cardShadow(isDark),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.systemGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(CupertinoIcons.arrow_up, size: 14, color: AppColors.systemGreen),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            fmt.format(income),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.systemGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 0.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.separatorDark
                  : AppColors.separator,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.systemRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(CupertinoIcons.arrow_down, size: 14, color: AppColors.systemRed),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          Text(
                            fmt.format(expense),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.systemRed,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    TransactionListState state,
    TransactionListNotifier notifier,
  ) {
    if (state.isLoading) {
      return ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: const [
          SkeletonCard(height: 72),
          SizedBox(height: AppSizes.sm),
          SkeletonCard(height: 72),
          SizedBox(height: AppSizes.sm),
          SkeletonCard(height: 72),
        ],
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Failed to load transactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: () => notifier.loadTransactions(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredTransactions.isEmpty) {
      final hasAnyFilter = state.hasActiveFilters ||
          state.searchQuery.isNotEmpty ||
          state.selectedFilter != 'All' ||
          state.selectedPeriod != 'All';
      return Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyStateCard(
              icon: CupertinoIcons.doc_text,
              title: 'No Transactions Found',
              message: hasAnyFilter
                  ? 'Try adjusting your filters or search query to find transactions.'
                  : 'No transactions found.',
              backgroundColor: AppColors.brandTeal,
            ),
            if (hasAnyFilter) ...[
              const SizedBox(height: AppSizes.lg),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeightMd,
                child: ElevatedButton.icon(
                  onPressed: () {
                    notifier.clearFilters();
                    notifier.setFilter('All');
                    notifier.setSearchQuery('');
                    _searchController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 20),
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group transactions by date
    final grouped = <String, List<TransactionEntity>>{};
    for (final tx in state.filteredTransactions) {
      final key = DateFormat('MMMM d, yyyy').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final groups = grouped.entries.toList();

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pagePadding,
          vertical: AppSizes.md,
        ),
        itemCount: groups.length + 1, // +1 for ad banner
        itemBuilder: (context, groupIndex) {
          if (groupIndex == groups.length) {
            return const Padding(
              padding: EdgeInsets.only(top: AppSizes.md),
              child: AdBannerWidget(),
            );
          }
          final entry = groups[groupIndex];
          final txList = entry.value;
          final cardBg = isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSizes.sm,
                  bottom: AppSizes.xs,
                ),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.systemGray,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                  boxShadow: AppColors.cardShadow(isDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < txList.length; i++) ...[
                      _buildTransactionCard(context, txList[i], notifier),
                      if (i < txList.length - 1)
                        Divider(
                          height: 0,
                          thickness: 0.5,
                          indent: 60,
                          color: isDark
                              ? AppColors.separatorDark
                              : AppColors.separator,
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionEntity transaction,
    TransactionListNotifier notifier,
  ) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final iconColor = isIncome
        ? AppColors.systemGreen
        : isTransfer
            ? AppColors.systemBlue
            : AppColors.systemRed;
    final amountPrefix = isIncome ? '+' : isTransfer ? '' : '-';

    return InkWell(
      onTap: () => _showTransactionDetails(context, transaction, notifier),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getTransactionIcon(transaction), color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? 'Transaction',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction.categoryName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.categoryName!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              '$amountPrefix${currencyFormat.format(transaction.amount.abs())}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(TransactionEntity transaction) {
    final cat = transaction.categoryName?.toLowerCase() ?? '';
    if (transaction.type == TransactionType.income) {
      if (cat.contains('salary')) return CupertinoIcons.briefcase;
      if (cat.contains('freelance')) return CupertinoIcons.desktopcomputer;
      if (cat.contains('investment')) return CupertinoIcons.graph_circle;
      if (cat.contains('gift')) return CupertinoIcons.gift;
      return CupertinoIcons.money_dollar_circle;
    }
    if (transaction.type == TransactionType.transfer) {
      return CupertinoIcons.arrow_right_arrow_left;
    }
    if (cat.contains('food') || cat.contains('dining')) return CupertinoIcons.cart;
    if (cat.contains('transport') || cat.contains('gas')) return CupertinoIcons.car;
    if (cat.contains('shopping')) return CupertinoIcons.bag;
    if (cat.contains('entertainment')) return CupertinoIcons.film;
    if (cat.contains('utilities') || cat.contains('bill')) return CupertinoIcons.doc_text;
    if (cat.contains('health')) return CupertinoIcons.heart;
    if (cat.contains('education')) return CupertinoIcons.book;
    if (cat.contains('housing')) return CupertinoIcons.house;
    return CupertinoIcons.creditcard;
  }

  void _showTransactionDetails(
    BuildContext context,
    TransactionEntity transaction,
    TransactionListNotifier notifier,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Amount
            Text(
              currencyFormat.format(transaction.amount.abs()),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: transaction.type == TransactionType.income
                        ? AppColors.success
                        : transaction.type == TransactionType.transfer
                            ? AppColors.slateBlue
                            : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              transaction.type.toString().split('.').last.toUpperCase(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),

            // Details
            _buildDetailRow('Title', transaction.description ?? 'N/A'),
            if (transaction.categoryName != null)
              _buildDetailRow('Category', transaction.categoryName!),
            _buildDetailRow('Date', dateFormat.format(transaction.date)),
            if (transaction.notes != null && transaction.notes!.isNotEmpty)
              _buildDetailRow('Notes', transaction.notes!),

            const SizedBox(height: AppSizes.lg),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await context.push('/transactions/add?id=${transaction.id}');
                      // Refresh after editing
                      if (context.mounted) {
                        notifier.refresh();
                      }
                    },
                    icon: const Icon(CupertinoIcons.pencil),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandTeal,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmDelete(context, transaction, notifier);
                    },
                    icon: const Icon(CupertinoIcons.trash),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    StateSetter setModalState,
    String? selectedCategory,
    Function(String?) onCategoryChanged,
  ) {
    // Combine all unique categories from transactions
    final allCategories = <String>{};
    final state = ref.read(transactionListProvider);
    for (final transaction in state.transactions) {
      if (transaction.categoryName != null) {
        allCategories.add(transaction.categoryName!);
      }
    }

    if (allCategories.isEmpty) {
      return Text(
        'No categories available',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final sortedCategories = allCategories.toList()..sort();
    return Wrap(
      spacing: AppSizes.sm,
      children: sortedCategories.map((category) {
        final isSelected = selectedCategory == category;
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setModalState(() {
              onCategoryChanged(selected ? category : null);
            });
          },
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.brandTeal.withValues(alpha: 0.2),
          checkmarkColor: AppColors.brandTeal,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.brandTeal : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.brandTeal : AppColors.borderLight,
          ),
        );
      }).toList(),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TransactionEntity transaction,
    TransactionListNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await notifier.deleteTransaction(transaction.id);

              // Invalidate dashboard and related providers to refresh cached data
              if (success) {
                unawaited(ref.read(analyticsServiceProvider).trackTransactionDeleted(
                  transactionId: transaction.id,
                ));
                ref.invalidate(dashboardNotifierProvider);
                ref.invalidate(recentTransactionsProvider);
                ref.invalidate(monthlyFlowDataProvider);
                ref.invalidate(netWorthSnapshotsProvider);
                ref.invalidate(budgetNotifierProvider); // Refresh budget spending calculations
              }

              if (context.mounted) {
                if (success) {
                  SuccessDialog.show(
                    context,
                    title: 'Deleted',
                    message: 'Transaction deleted successfully',
                    autoDismissDuration: const Duration(milliseconds: 800),
                  );
                } else {
                  showErrorDialog(context, 'Failed to delete transaction');
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final state = ref.read(transactionListProvider);
    final notifier = ref.read(transactionListProvider.notifier);

    // Local state for the modal
    String? selectedCategory = state.selectedCategory;
    DateTimeRange? dateRange = state.dateRange;
    double? minAmount = state.minAmount;
    double? maxAmount = state.maxAmount;
    bool hideFuture = state.hideFutureTransactions;

    _minAmountController.text = minAmount?.toString() ?? '';
    _maxAmountController.text = maxAmount?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Transactions',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              selectedCategory = null;
                              dateRange = null;
                              minAmount = null;
                              maxAmount = null;
                              hideFuture = false;
                              _minAmountController.clear();
                              _maxAmountController.clear();
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Category Filter
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    _buildCategoryFilter(setModalState, selectedCategory, (category) {
                      selectedCategory = category;
                    }),
                    const SizedBox(height: AppSizes.lg),

                    // Date Range Filter
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: dateRange,
                        );
                        if (picked != null) {
                          setModalState(() {
                            dateRange = picked;
                          });
                        }
                      },
                      icon: const Icon(CupertinoIcons.calendar),
                      label: Text(
                        dateRange == null
                            ? 'Select Date Range'
                            : '${DateFormat('MMM d').format(dateRange!.start)} - ${DateFormat('MMM d, y').format(dateRange!.end)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dateRange != null ? AppColors.brandTeal : null,
                        side: BorderSide(
                          color: dateRange != null ? AppColors.brandTeal : AppColors.borderLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Amount Range Filter
                    Text(
                      'Amount Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Min Amount',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setModalState(() {
                                minAmount = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Max Amount',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setModalState(() {
                                maxAmount = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Hide Future Transactions toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Hide Future Transactions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        'Only show transactions up to today',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      value: hideFuture,
                      activeThumbColor: AppColors.brandTeal,
                      onChanged: (val) => setModalState(() => hideFuture = val),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Apply Button
                    ElevatedButton(
                      onPressed: () {
                        notifier.setCategory(selectedCategory);
                        notifier.setDateRange(dateRange);
                        notifier.setAmountRange(minAmount, maxAmount);
                        notifier.setHideFutureTransactions(hideFuture);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandTeal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
