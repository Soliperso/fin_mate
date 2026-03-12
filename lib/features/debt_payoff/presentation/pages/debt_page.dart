import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/services/payoff_calculator.dart' show DebtStrategy;
import '../providers/debt_providers.dart';
import '../widgets/add_debt_bottom_sheet.dart';
import '../widgets/debt_card.dart';
import '../widgets/debt_hero_card.dart';
import '../widgets/edit_debt_bottom_sheet.dart';
import '../widgets/extra_payment_card.dart';
import '../widgets/log_payment_bottom_sheet.dart';
import '../widgets/monthly_funding_card.dart';
import '../widgets/monthly_schedule_list.dart';
import '../widgets/payment_history_sheet.dart';
import '../widgets/payoff_timeline_chart.dart';
import '../widgets/strategy_comparison_sheet.dart';

export '../../domain/services/payoff_calculator.dart' show DebtStrategy;

class DebtPage extends ConsumerStatefulWidget {
  const DebtPage({super.key});

  @override
  ConsumerState<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends ConsumerState<DebtPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DebtEntity> _sortedDebts(List<DebtEntity> debts) {
    final strategy = ref.read(selectedStrategyProvider);
    final sorted = List<DebtEntity>.from(debts);
    sorted.sort(strategy == DebtStrategy.avalanche
        ? (a, b) => b.interestRate.compareTo(a.interestRate)
        : (a, b) => a.balance.compareTo(b.balance));
    return sorted;
  }

  Future<void> _refresh() async {
    ref.invalidate(debtsProvider);
    ref.invalidate(debtSummaryProvider);
  }

  void _showAddDebt() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => const AddDebtBottomSheet(),
    );
  }

  void _showLogPayment(DebtEntity debt) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => LogPaymentBottomSheet(debt: debt),
    );
  }

  void _showEditDebt(DebtEntity debt) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => EditDebtBottomSheet(debt: debt),
    );
  }

  void _showStrategyComparison() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => const StrategyComparisonSheet(),
    );
  }

  void _showPaymentHistory(DebtEntity debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => PaymentHistorySheet(debt: debt),
    );
  }

  Future<void> _deleteDebt(DebtEntity debt) async {
    final success =
        await ref.read(debtNotifierProvider.notifier).deleteDebt(debt.id);
    if (!mounted) return;
    if (success) {
      ref.invalidate(debtsProvider);
      ref.invalidate(debtSummaryProvider);
      SuccessDialog.show(
        context,
        title: 'Removed',
        message: '${debt.name} has been removed',
        autoDismissDuration: const Duration(milliseconds: 800),
      );
    } else {
      showErrorDialog(context, 'Failed to delete debt');
    }
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);
    final strategy = ref.watch(selectedStrategyProvider);
    final payoffResult = ref.watch(payoffResultProvider);
    final extra = ref.watch(extraPaymentProvider);
    final simResult = ref.watch(simulatedPayoffProvider);
    final activeResult =
        extra > 0 && simResult != null ? simResult : payoffResult;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Debt Payoff',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryTeal,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Plan'),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: debtsAsync.valueOrNull?.isNotEmpty == true
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showAddDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  icon: const Icon(CupertinoIcons.add, size: 20),
                  label: const Text(
                    'Add Debt',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
      body: debtsAsync.when(
        loading: () => _buildLoading(),
        error: (e, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyState(
              icon: CupertinoIcons.exclamationmark_circle,
              title: 'Could Not Load Debts',
              message: 'Pull down to refresh.',
            ),
            Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
        data: (debts) {
          if (debts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmptyStateCard(
                    icon: CupertinoIcons.creditcard,
                    title: 'No Debts Tracked',
                    message: 'Add your debts to start your payoff journey.',
                    backgroundColor: AppColors.primaryTeal,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showAddDebt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor:
                            AppColors.primaryTeal.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ),
                      icon: const Icon(CupertinoIcons.add, size: 20),
                      label: const Text(
                        'Add Debt',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final sorted = _sortedDebts(debts);
          final totalBalance =
              debts.fold<double>(0, (s, d) => s + d.balance);

          return TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // ── Tab 0: Overview ───────────────────────────────────────
              RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primaryTeal,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.md, AppSizes.md, 100,
                  ),
                  children: [
                    // Hero card
                    DebtHeroCard(
                      totalBalance: totalBalance,
                      debtCount: debts.length,
                      payoffResult: payoffResult,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Strategy picker
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<DebtStrategy>(
                            segments: const [
                              ButtonSegment(
                                value: DebtStrategy.avalanche,
                                label: Text('Avalanche'),
                                icon: Icon(CupertinoIcons.flame),
                              ),
                              ButtonSegment(
                                value: DebtStrategy.snowball,
                                label: Text('Snowball'),
                                icon: Icon(CupertinoIcons.snow),
                              ),
                            ],
                            selected: {strategy},
                            onSelectionChanged: (s) => ref
                                .read(selectedStrategyProvider.notifier)
                                .state = s.first,
                            style: ButtonStyle(
                              iconColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.primaryTeal;
                                }
                                return AppColors.textSecondary;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        IconButton(
                          icon: const Icon(CupertinoIcons.info_circle),
                          color: AppColors.textSecondary,
                          tooltip: 'Compare strategies',
                          onPressed: _showStrategyComparison,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      strategy == DebtStrategy.avalanche
                          ? 'Highest interest rate first — saves the most money'
                          : 'Lowest balance first — builds momentum faster',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Debt cards
                    ...sorted.map((debt) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSizes.sm),
                          child: DebtCard(
                            debt: debt,
                            onLogPayment: () => _showLogPayment(debt),
                            onEdit: () => _showEditDebt(debt),
                            onHistory: () => _showPaymentHistory(debt),
                            onDelete: () => _deleteDebt(debt),
                          ),
                        )),
                    const SizedBox(height: AppSizes.sm),
                    MonthlyFundingCard(debts: sorted),
                  ],
                ),
              ),

              // ── Tab 1: Plan ───────────────────────────────────────────
              payoffResult == null
                  ? const Center(
                      child: Text(
                        'Add debts to see your payoff plan.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.md, AppSizes.md, AppSizes.md, 100,
                      ),
                      children: [
                        PayoffTimelineChart(
                          result: activeResult ?? payoffResult,
                          debts: debts,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        MonthlyScheduleList(
                          result: activeResult ?? payoffResult,
                          debts: debts,
                          monthsToShow: 6,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        const ExtraPaymentCard(),
                      ],
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.md),
      children: const [
        SkeletonCard(height: 140),
        SizedBox(height: AppSizes.md),
        SkeletonCard(height: 44),
        SizedBox(height: AppSizes.md),
        SkeletonCard(),
        SizedBox(height: AppSizes.sm),
        SkeletonCard(),
        SizedBox(height: AppSizes.sm),
        SkeletonCard(),
      ],
    );
  }
}
