import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/supabase_client.dart';
import '../../data/services/csv_export_service.dart';
import '../../data/services/csv_import_service.dart';
import '../widgets/import_preview_bottom_sheet.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../shared/utils/category_icon_utils.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/services/search_history_service.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/instant_fab_animator.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/ads/ad_banner_widget.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_providers.dart';
import '../../../../core/providers/feature_flag_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  final bool openSearch;
  const TransactionsPage({super.key, this.openSearch = false});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  final _searchHistory = SearchHistoryService();
  List<String> _recentSearches = [];
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchHistory.load().then((h) => setState(() => _recentSearches = h));
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        ref.read(transactionListProvider.notifier).loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionListProvider.notifier).refresh();
      if (widget.openSearch) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider);
    final notifier = ref.read(transactionListProvider.notifier);
    final featureFlags = ref.watch(appFeatureFlagsProvider).valueOrNull;

    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelecting) _exitSelectionMode();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          leadingWidth: _isSelecting ? 84 : 0,
          titleSpacing: _isSelecting ? 0 : 16,
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _isSelecting
                ? TextButton(
                    key: const ValueKey('cancel'),
                    onPressed: _exitSelectionMode,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandTeal,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('common.cancel'.tr()),
                  )
                : const SizedBox.shrink(key: ValueKey('leading-empty')),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _isSelecting
                ? Text(
                    key: const ValueKey('selection-title'),
                    _selectedIds.isEmpty
                        ? 'Select Items'
                        : '${_selectedIds.length} Selected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  )
                : Text('nav.transactions'.tr(), key: const ValueKey('title')),
          ),
          actions: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _isSelecting
                  ? Row(
                      key: const ValueKey('selection-actions'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _toggleSelectAll,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandTeal,
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: Text(
                            _selectedIds.length ==
                                    state.filteredTransactions.length
                                ? 'transactions.deselectAll'.tr()
                                : 'transactions.selectAll'.tr(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: AppSizes.sm),
                          child: IconButton(
                            icon: Icon(
                              _selectedIds.isNotEmpty
                                  ? CupertinoIcons.trash_fill
                                  : CupertinoIcons.trash,
                              size: 20,
                            ),
                            color: _selectedIds.isNotEmpty
                                ? AppColors.error
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.4),
                            onPressed: _selectedIds.isNotEmpty
                                ? () => _confirmBulkDelete(context, notifier)
                                : null,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('normal-actions'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (featureEnabled(featureFlags, 'csv_export'))
                          Padding(
                            padding: const EdgeInsets.only(right: AppSizes.sm),
                            child: CircularIconButton(
                              icon: CupertinoIcons.arrow_down_to_line,
                              onTap: () => _showCsvOptions(context),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: AppSizes.sm),
                          child: Badge(
                            isLabelVisible: state.activeFilterCount > 0,
                            label: Text('${state.activeFilterCount}'),
                            child: CircularIconButton(
                              icon: CupertinoIcons.slider_horizontal_3,
                              onTap: () => _showFilterBottomSheet(context),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButtonAnimator: const InstantFabAnimator(),
        floatingActionButton: state.transactions.isNotEmpty &&
                state.filteredTransactions.isNotEmpty &&
                !_isSelecting
            ? FloatingActionButton(
                onPressed: () => context.go('/transactions/add'),
                backgroundColor: AppColors.brandTeal,
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(CupertinoIcons.add, size: 24),
              )
            : null,
        body: Column(
          children: [
            if (!_isSelecting) _buildSearchBar(context, notifier),
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
                      ? LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSizes.md),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    EmptyStateCard(
                                      icon: CupertinoIcons.doc_text,
                                      title: 'transactions.noTransactions'.tr(),
                                      message:
                                          'transactions.noTransactionsMessage'
                                              .tr(),
                                      backgroundColor: AppColors.brandTeal,
                                    ),
                                    const SizedBox(height: AppSizes.lg),
                                    SizedBox(
                                      height: AppSizes.buttonHeightMd,
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            context.go('/transactions/add'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.brandTeal,
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shadowColor: AppColors.brandTeal
                                              .withValues(alpha: 0.4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppSizes.radiusFull),
                                          ),
                                        ),
                                        icon: const Icon(CupertinoIcons.add,
                                            size: 20),
                                        label: Text(
                                          'addTransaction.newTitle'.tr(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // Period selector
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSizes.md,
                                AppSizes.sm,
                                AppSizes.md,
                                0,
                              ),
                              child: Row(
                                children: [
                                  'All',
                                  'Today',
                                  'Week',
                                  'Month',
                                  'Year',
                                ]
                                    .expand((period) => [
                                          Expanded(
                                            child: _buildPeriodChip(
                                              context,
                                              period,
                                              state.selectedPeriod,
                                              notifier,
                                            ),
                                          ),
                                          if (period != 'Year')
                                            const SizedBox(width: AppSizes.xs),
                                        ])
                                    .toList(),
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
                                  Expanded(
                                      child: _buildFilterChip(
                                          context,
                                          'All',
                                          'transactions.filterAll'.tr(),
                                          state.selectedFilter,
                                          notifier)),
                                  const SizedBox(width: AppSizes.sm),
                                  Expanded(
                                      child: _buildFilterChip(
                                          context,
                                          'Income',
                                          'transactions.filterIncome'.tr(),
                                          state.selectedFilter,
                                          notifier)),
                                  const SizedBox(width: AppSizes.sm),
                                  Expanded(
                                      child: _buildFilterChip(
                                          context,
                                          'Expense',
                                          'transactions.filterExpense'.tr(),
                                          state.selectedFilter,
                                          notifier)),
                                ],
                              ),
                            ),

                            // Income / Expense summary row
                            _buildSummaryRow(context, state, ref),

                            Divider(
                              height: 1,
                              color: Theme.of(context).dividerColor,
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
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context, TransactionListNotifier notifier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showHistory = _searchFocused &&
        _searchController.text.isEmpty &&
        _recentSearches.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.pagePadding, AppSizes.sm, AppSizes.pagePadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'transactions.searchHint'.tr(),
              hintStyle:
                  TextStyle(fontSize: 14, color: AppColors.textSecondary),
              prefixIcon: const Icon(CupertinoIcons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _debounceTimer?.cancel();
                        notifier.setSearchQuery('');
                        setState(() {});
                      },
                      child: const Icon(CupertinoIcons.xmark_circle_fill,
                          size: 18, color: AppColors.systemGray3),
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? AppColors.secondarySystemBackgroundDark
                  : AppColors.systemGray6,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: 10),
            ),
            onChanged: (value) {
              setState(() {});
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                notifier.setSearchQuery(value);
              });
            },
            onSubmitted: (value) {
              final q = value.trim();
              if (q.length >= 2) {
                _searchHistory.add(q).then((_) {
                  _searchHistory
                      .load()
                      .then((h) => setState(() => _recentSearches = h));
                });
              }
            },
          ),
          if (showHistory) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    _searchHistory.clear();
                    setState(() => _recentSearches = []);
                  },
                  child: Text(
                    'common.cancel'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _recentSearches
                    .map((query) => Padding(
                          padding: const EdgeInsets.only(right: AppSizes.xs),
                          child: GestureDetector(
                            onTap: () {
                              _searchController.text = query;
                              _searchController.selection =
                                  TextSelection.collapsed(offset: query.length);
                              notifier.setSearchQuery(query);
                              _searchFocusNode.unfocus();
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.sm, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.secondarySystemBackgroundDark
                                    : AppColors.systemGray6,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.clock,
                                      size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    query,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String filter,
    String label,
    String selectedFilter,
    TransactionListNotifier notifier,
  ) {
    final isSelected = filter == selectedFilter;
    return GestureDetector(
      onTap: () => notifier.setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.brandTeal
                : AppColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
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
    return GestureDetector(
      onTap: () => notifier.setPeriod(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 7),
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
          'transactions.period$period'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  double _totalIncome(List<TransactionEntity> txns) => txns
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double _totalExpense(List<TransactionEntity> txns) => txns
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  Widget _buildSummaryRow(
      BuildContext context, TransactionListState state, WidgetRef ref) {
    final fmt = ref.watch(currencyFormat2Provider);
    final convFactor = ref.watch(conversionFactorProvider);

    // Use all historical transactions for accurate summary when period is specified
    final useAllTransactions = state.selectedPeriod != 'All' || state.selectedFilter == 'All';
    final allHistoricalTxns = useAllTransactions ? ref.watch(allHistoricalTransactionsProvider) : null;

    if (allHistoricalTxns is AsyncValue<List<TransactionEntity>>) {
      return allHistoricalTxns.when(
        data: (allTxns) => _buildSummaryRowContent(
          context, state, ref, allTxns, fmt, convFactor),
        loading: () => _buildSummaryRowSkeleton(context),
        error: (err, stack) => _buildSummaryRowContent(
          context, state, ref, state.transactions, fmt, convFactor),
      );
    }

    return _buildSummaryRowContent(
      context, state, ref, state.transactions, fmt, convFactor);
  }

  Widget _buildSummaryRowContent(
      BuildContext context,
      TransactionListState state,
      WidgetRef ref,
      List<TransactionEntity> txnsSource,
      dynamic fmt,
      double convFactor) {
    // Apply filtering based on state
    var periodTxns = List<TransactionEntity>.from(txnsSource);

    if (state.hideFutureTransactions) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      periodTxns = periodTxns.where((t) {
        final txDate = DateTime(t.date.year, t.date.month, t.date.day);
        return !txDate.isAfter(todayDate);
      }).toList();
    }
    if (state.dateRange != null) {
      periodTxns = periodTxns.where((t) {
        return t.date.isAfter(
                state.dateRange!.start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(state.dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (state.selectedCategory != null) {
      periodTxns = periodTxns
          .where((t) => t.categoryName == state.selectedCategory)
          .toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      periodTxns = periodTxns.where((t) {
        return (t.description ?? '').toLowerCase().contains(q) ||
            (t.categoryName ?? '').toLowerCase().contains(q);
      }).toList();
    }

    if (state.minAmount != null || state.maxAmount != null) {
      periodTxns = periodTxns.where((t) {
        final amt = t.amount.abs();
        if (state.minAmount != null && amt < state.minAmount!) return false;
        if (state.maxAmount != null && amt > state.maxAmount!) return false;
        return true;
      }).toList();
    }

    // Apply type filter (Income/Expense) to make summary accurate to filtered view
    if (state.selectedFilter != 'All') {
      periodTxns = periodTxns.where((t) {
        if (state.selectedFilter == 'Income')
          return t.type == TransactionType.income;
        if (state.selectedFilter == 'Expense')
          return t.type == TransactionType.expense;
        return true;
      }).toList();
    }

    final income = _totalIncome(periodTxns);
    final expense = _totalExpense(periodTxns);
    final remaining = income - expense;
    final remainingColor =
        remaining >= 0 ? AppColors.systemGreen : AppColors.systemRed;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final isFiltered = state.selectedCategory != null ||
        state.searchQuery.isNotEmpty ||
        state.minAmount != null ||
        state.maxAmount != null;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.sm),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (state.selectedFilter == 'Income')
                Expanded(
                  child: _buildSummaryCell(
                    context: context,
                    icon: CupertinoIcons.arrow_up,
                    color: AppColors.systemGreen,
                    label: 'transactions.filterIncome'.tr(),
                    amount: fmt.format(income * convFactor),
                    horizontal: isFiltered,
                  ),
                )
              else if (state.selectedFilter == 'Expense')
                Expanded(
                  child: _buildSummaryCell(
                    context: context,
                    icon: CupertinoIcons.arrow_down,
                    color: AppColors.systemRed,
                    label: 'transactions.filterExpense'.tr(),
                    amount: fmt.format(expense * convFactor),
                    horizontal: isFiltered,
                  ),
                )
              else ...[
                _buildSummaryCell(
                  context: context,
                  icon: CupertinoIcons.arrow_up,
                  color: AppColors.systemGreen,
                  label: 'transactions.filterIncome'.tr(),
                  amount: fmt.format(income * convFactor),
                  horizontal: isFiltered,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  indent: 10,
                  endIndent: 10,
                  color: Theme.of(context).dividerColor,
                ),
                _buildSummaryCell(
                  context: context,
                  icon: CupertinoIcons.arrow_down,
                  color: AppColors.systemRed,
                  label: 'transactions.filterExpense'.tr(),
                  amount: fmt.format(expense * convFactor),
                  horizontal: isFiltered,
                ),
                if (!isFiltered) ...[
                  VerticalDivider(
                    width: 1,
                    thickness: 0.5,
                    indent: 10,
                    endIndent: 10,
                    color: Theme.of(context).dividerColor,
                  ),
                  _buildSummaryCell(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    color: remainingColor,
                    label: 'Remaining',
                    amount: '${remaining >= 0 ? '+' : '-'}${fmt.format(remaining.abs() * convFactor)}',
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCell({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String amount,
    bool horizontal = false,
  }) {
    final iconBox = Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 13, color: color),
    );

    final textCol = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: horizontal
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconBox,
                  const SizedBox(width: 8),
                  textCol,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconBox,
                  const SizedBox(height: 5),
                  textCol,
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryRowSkeleton(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, AppSizes.sm),
      child: SkeletonCard(height: 80),
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
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyStateCard(
              icon: CupertinoIcons.doc_text,
              title: 'transactions.noTransactionsFound'.tr(),
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
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise,
                      size: 20),
                  label: Text(
                    'common.cancel'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
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
                  label: Text(
                    'addTransaction.newTitle'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group transactions by date, newest first (computed in provider state)
    final groups = state.groupedByDate.entries.toList();

    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          left: AppSizes.pagePadding,
          right: AppSizes.pagePadding,
          top: AppSizes.md,
          bottom: 96, // clears the FAB + its margin
        ),
        itemCount: groups.length +
            1 +
            (state.isLoadingMore ? 1 : 0), // +1 banner, +1 when loading more
        itemBuilder: (context, groupIndex) {
          if (groupIndex == groups.length) {
            return const Padding(
              padding: EdgeInsets.only(top: AppSizes.md),
              child: AdBannerWidget(),
            );
          }
          if (groupIndex == groups.length + 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
              child: Center(child: LoadingIndicator(size: 24)),
            );
          }
          final entry = groups[groupIndex];
          final txList = entry.value;
          final cardBg = isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground;

          final groupFmt = ref.watch(currencyFormat2Provider);
          final groupConv = ref.watch(conversionFactorProvider);

          // Daily net for this date group (income − expense for that day only)
          final groupIncome = txList
              .where((t) => t.type == TransactionType.income)
              .fold(0.0, (s, t) => s + t.amount);
          final groupExpense = txList
              .where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);
          final groupBalance = groupIncome - groupExpense;

          final groupBalanceColor =
              groupBalance >= 0 ? AppColors.systemGreen : AppColors.systemRed;
          final groupBalanceText =
              '${groupBalance >= 0 ? '+' : '-'}${groupFmt.format(groupBalance.abs() * groupConv)}';

          final groupCard = TweenAnimationBuilder<double>(
            key: ValueKey(entry.key),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.sm,
                    bottom: AppSizes.xs,
                    right: AppSizes.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: AppColors.systemGray,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        groupBalanceText,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: groupBalanceColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (int i = 0; i < txList.length; i++) ...[
                        _buildTransactionCard(
                            context, txList[i], notifier, ref),
                        if (i < txList.length - 1)
                          Divider(
                            height: 0,
                            thickness: 0.5,
                            indent: 60,
                            endIndent: AppSizes.md,
                            color: Theme.of(context).dividerColor,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
              ],
            ),
          );

          return groupCard;
        },
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionEntity transaction,
    TransactionListNotifier notifier,
    WidgetRef ref,
  ) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final convFactor = ref.watch(conversionFactorProvider);

    final defaultIconColor = isIncome
        ? AppColors.systemGreen
        : isTransfer
            ? AppColors.systemBlue
            : AppColors.systemRed;
    final iconColor = transaction.categoryColor != null
        ? _parseHexColor(transaction.categoryColor!)
        : defaultIconColor;
    final amountPrefix = isIncome
        ? '+'
        : isTransfer
            ? ''
            : '-';

    final isSelected = _selectedIds.contains(transaction.id);
    final today = DateTime.now();
    final isProjected = transaction.date.isAfter(
      DateTime(today.year, today.month, today.day),
    );

    return Dismissible(
      key: ValueKey(transaction.id),
      direction:
          _isSelecting ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.lg),
        child: const Icon(CupertinoIcons.trash_fill,
            color: Colors.white, size: 20),
      ),
      onDismissed: (_) async {
        final success = await notifier.deleteTransaction(transaction.id);
        if (success) {
          unawaited(ref.read(analyticsServiceProvider).trackTransactionDeleted(
                transactionId: transaction.id,
              ));
          ref.invalidate(dashboardNotifierProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(monthlyFlowDataProvider);
          ref.invalidate(netWorthSnapshotsProvider);
          ref.invalidate(budgetNotifierProvider);
          ref.invalidate(categoryBreakdownProvider);
        }
        if (context.mounted) {
          if (success) {
            SuccessSnackbar.show(context, message: 'transactions.deleted'.tr());
          } else {
            ErrorSnackbar.show(context,
                message: 'transactions.failedToDelete'.tr());
          }
        }
      },
      child: InkWell(
        onLongPress: () {
          if (!_isSelecting) {
            setState(() {
              _isSelecting = true;
              _selectedIds.add(transaction.id);
            });
          }
        },
        onTap: () {
          if (_isSelecting) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(transaction.id);
              } else {
                _selectedIds.add(transaction.id);
              }
            });
          } else {
            context.push('/transactions/${transaction.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (_isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: isSelected
                        ? AppColors.brandTeal
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(_getTransactionIcon(transaction),
                    color: iconColor, size: 20),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix${currencyFormat.format(transaction.amount.abs() * convFactor)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  if (ref.watch(
                          usdEquivalentProvider(transaction.amount.abs())) !=
                      null)
                    Text(
                      ref.watch(
                          usdEquivalentProvider(transaction.amount.abs()))!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    )
                  else
                    Text(
                      DateFormat(AppDateFormats.timeOnly)
                          .format(transaction.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  if (isProjected) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.systemBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Projected',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.systemBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(TransactionEntity transaction) {
    return getCategoryIcon(
      transaction.categoryName,
      type: transaction.type.name,
      iconKey: transaction.categoryIcon,
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.brandTeal;
    }
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

  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectAll() {
    final filtered = ref.read(transactionListProvider).filteredTransactions;
    setState(() {
      if (_selectedIds.length == filtered.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(filtered.map((t) => t.id));
      }
    });
  }

  void _confirmBulkDelete(
      BuildContext context, TransactionListNotifier notifier) {
    final count = _selectedIds.length;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(CupertinoIcons.trash_fill,
            color: AppColors.error, size: 28),
        title: Text('Delete $count Transaction${count == 1 ? '' : 's'}'),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        content: Text(
          'This will permanently delete $count transaction${count == 1 ? '' : 's'}. This cannot be undone.',
          textAlign: TextAlign.center,
        ),
        contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final ids = List<String>.from(_selectedIds);
              Navigator.pop(dialogContext);
              final success = await notifier.deleteMultipleTransactions(ids);
              if (success) {
                unawaited(
                    ref.read(analyticsServiceProvider).trackTransactionDeleted(
                          transactionId: ids.first,
                        ));
                ref.invalidate(dashboardNotifierProvider);
                ref.invalidate(recentTransactionsProvider);
                ref.invalidate(monthlyFlowDataProvider);
                ref.invalidate(netWorthSnapshotsProvider);
                ref.invalidate(budgetNotifierProvider);
                ref.invalidate(categoryBreakdownProvider);
              }
              if (context.mounted) {
                _exitSelectionMode();
                if (success) {
                  SuccessSnackbar.show(
                    context,
                    message: 'transactions.deleted'.tr(),
                  );
                } else {
                  ErrorSnackbar.show(
                    context,
                    message: 'transactions.failedToDeleteMultiple'.tr(),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCsvOptions(BuildContext context) {
    GlassBottomSheet.show(
      context: context,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.md,
            AppSizes.sm,
            AppSizes.md,
            AppSizes.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'CSV OPTIONS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(height: AppSizes.xs),
              _CsvOptionTile(
                icon: CupertinoIcons.arrow_up_to_line,
                title: 'Export CSV',
                subtitle: 'Share filtered transactions as a spreadsheet',
                onTap: () {
                  Navigator.pop(context);
                  _exportCsv(context);
                },
              ),
              Divider(
                height: 1,
                indent: 40,
                color: AppColors.separator.withValues(alpha: 0.5),
              ),
              _CsvOptionTile(
                icon: CupertinoIcons.arrow_down_to_line,
                title: 'Import CSV',
                subtitle: 'Add transactions from a CSV file',
                onTap: () {
                  Navigator.pop(context);
                  _importCsv(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final transactions = ref.read(transactionListProvider).filteredTransactions;

    if (transactions.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final csv = CsvExportService().export(transactions);
    final dir = await getTemporaryDirectory();
    final stamp =
        DateFormat(AppDateFormats.exportTimestamp).format(DateTime.now());
    final file = File('${dir.path}/finmate_transactions_$stamp.csv');
    await file.writeAsString(csv);

    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Finmate transactions export',
      sharePositionOrigin: origin,
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    // 1. Pick CSV file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    // 2. Read content
    final content = await File(result.files.single.path!).readAsString();

    // 3. Load accounts + categories
    final repo = ref.read(transactionRepositoryProvider);
    final accounts = await repo.getAccounts();
    final categories = await repo.getCategories();
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // 4. Parse
    CsvImportResult importResult;
    try {
      importResult =
          CsvImportService().parse(content, accounts, categories, userId);
    } on FormatException catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Invalid File'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (importResult.transactions.isEmpty && importResult.errors.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid transactions found in the file.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 5. Show preview sheet
    if (!context.mounted) return;
    await ImportPreviewBottomSheet.show(context, ref, importResult);
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

    GlassBottomSheet.show(
      context: context,
      child: StatefulBuilder(
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSizes.md),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'transactions.filterTitle'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            notifier.setCategory(null);
                            notifier.setDateRange(null);
                            notifier.setAmountRange(null, null);
                            notifier.setHideFutureTransactions(false);
                            Navigator.pop(context);
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
                    _buildCategoryFilter(setModalState, selectedCategory,
                        (category) {
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
                            : '${DateFormat(AppDateFormats.shortDate).format(dateRange!.start)} - ${DateFormat('MMM d, y').format(dateRange!.end)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            dateRange != null ? AppColors.brandTeal : null,
                        side: BorderSide(
                          color: dateRange != null
                              ? AppColors.brandTeal
                              : AppColors.borderLight,
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
                            decoration: InputDecoration(
                              labelText: 'transactions.minAmount'.tr(),
                              prefixText:
                                  '${ref.watch(currencySymbolProvider)} ',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
                              ),
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
                            decoration: InputDecoration(
                              labelText: 'transactions.maxAmount'.tr(),
                              prefixText:
                                  '${ref.watch(currencySymbolProvider)} ',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusMd),
                              ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hide Future Transactions',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              'Only show transactions up to today',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: hideFuture,
                            onChanged: (val) {
                              setModalState(() => hideFuture = val);
                              notifier.setHideFutureTransactions(val);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
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
                        minimumSize:
                            const Size.fromHeight(AppSizes.buttonHeightMd),
                        shape: const StadiumBorder(),
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

class _CsvOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CsvOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandTeal, size: 18),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 12,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
