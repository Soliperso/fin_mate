import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/instant_fab_animator.dart';
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
import '../widgets/monthly_schedule_list.dart';
import '../widgets/payment_history_sheet.dart';
import '../widgets/payoff_timeline_chart.dart';
import '../widgets/debt_cost_split_card.dart';
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
    await GlassBottomSheet.show(
      context: context,
      child: const AddDebtBottomSheet(),
    );
  }

  void _showLogPayment(DebtEntity debt) async {
    await GlassBottomSheet.show(
      context: context,
      child: LogPaymentBottomSheet(debt: debt),
    );
  }

  void _showEditDebt(DebtEntity debt) async {
    await GlassBottomSheet.show(
      context: context,
      child: EditDebtBottomSheet(debt: debt),
    );
  }

  void _showStrategyComparison() {
    GlassBottomSheet.show(
      context: context,
      child: const StrategyComparisonSheet(),
    );
  }

  void _showPaymentHistory(DebtEntity debt) {
    GlassBottomSheet.show(
      context: context,
      child: PaymentHistorySheet(debt: debt),
    );
  }

  Future<void> _deleteDebt(DebtEntity debt) async {
    final success =
        await ref.read(debtNotifierProvider.notifier).deleteDebt(debt.id);
    if (!mounted) return;
    if (success) {
      ref.invalidate(debtsProvider);
      ref.invalidate(debtSummaryProvider);
      SuccessSnackbar.show(context, message: 'debt.deleted'.tr(namedArgs: {'name': debt.name}));
    } else {
      ErrorSnackbar.show(context, message: 'debt.failedToDelete'.tr());
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

    final dateFormat = DateFormat('MMM yyyy');
    final currencyFormat = ref.watch(currencyFormat0Provider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'debt.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brandTeal,
          labelColor: AppColors.brandTeal,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'debt.overviewTab'.tr()),
            Tab(text: 'debt.planTab'.tr()),
          ],
        ),
      ),
      floatingActionButtonAnimator: const InstantFabAnimator(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: debtsAsync.valueOrNull?.isNotEmpty == true
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeightMd,
                child: ElevatedButton.icon(
                  onPressed: _showAddDebt,
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
                    'debt.addDebt'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
      body: debtsAsync.when(
        loading: () => _buildLoading(),
        error: (e, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyState(
              icon: CupertinoIcons.exclamationmark_circle,
              title: 'debt.failedToLoad'.tr(),
              message: 'debt.pullToRefresh'.tr(),
            ),
            Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                label: Text('debt.retry'.tr()),
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
                    title: 'debt.noDebts'.tr(),
                    message: 'debt.noDebtsMessage'.tr(),
                    backgroundColor: AppColors.brandTeal,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeightMd,
                    child: ElevatedButton.icon(
                      onPressed: _showAddDebt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandTeal,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor:
                            AppColors.brandTeal.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                      ),
                      icon: const Icon(CupertinoIcons.add, size: 20),
                      label: Text(
                        'debt.addDebt'.tr(),
                        style: const TextStyle(
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
                color: AppColors.brandTeal,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.md, AppSizes.md, 100,
                  ),
                  children: [
                    // Hero card — uses simulated result when extra payment is active
                    DebtHeroCard(
                      totalBalance: totalBalance,
                      debtCount: debts.length,
                      payoffResult: activeResult ?? payoffResult,
                      debts: debts,
                      extraMonthly: extra,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Strategy card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.separatorDark.withValues(alpha: 0.5)
                              : AppColors.separator.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'debt.strategy'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _showStrategyComparison,
                                  child: Row(
                                    children: [
                                      Text(
                                        'debt.compare'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.brandTeal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
                                        CupertinoIcons.chevron_right,
                                        size: 12,
                                        color: AppColors.brandTeal,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<DebtStrategy>(
                                segments: [
                                  ButtonSegment(
                                    value: DebtStrategy.avalanche,
                                    label: Text('debt.avalanche'.tr()),
                                    icon: const Icon(CupertinoIcons.flame),
                                  ),
                                  ButtonSegment(
                                    value: DebtStrategy.snowball,
                                    label: Text('debt.snowball'.tr()),
                                    icon: const Icon(CupertinoIcons.snow),
                                  ),
                                ],
                                selected: {strategy},
                                onSelectionChanged: (s) => ref
                                    .read(selectedStrategyProvider.notifier)
                                    .state = s.first,
                                style: ButtonStyle(
                                  iconColor: WidgetStateProperty.resolveWith(
                                    (states) => states.contains(WidgetState.selected)
                                        ? AppColors.brandTeal
                                        : AppColors.textSecondary,
                                  ),
                                  textStyle: WidgetStateProperty.all(
                                    Theme.of(context).textTheme.labelLarge?.copyWith(
                                          fontSize: (Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) * 0.8,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSizes.xs),
                            Text(
                              strategy == DebtStrategy.avalanche
                                  ? 'debt.avalancheDesc'.tr()
                                  : 'debt.snowballDesc'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            if (payoffResult != null && payoffResult.schedule.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.sm),

                              // 3-metric summary row
                              Row(
                                children: [
                                  _MetricItem(
                                    icon: CupertinoIcons.calendar,
                                    iconColor: AppColors.brandTeal,
                                    value: dateFormat.format(payoffResult.debtFreeDate),
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  _MetricItem(
                                    icon: CupertinoIcons.clock,
                                    iconColor: AppColors.brandTeal,
                                    value: '${payoffResult.totalMonths} ${'debt.moAbbr'.tr()}',
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  _MetricItem(
                                    icon: CupertinoIcons.money_dollar,
                                    iconColor: AppColors.error,
                                    value: currencyFormat.format(payoffResult.totalInterestPaid),
                                    valueColor: AppColors.error,
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSizes.sm),

                              // Focus chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.sm,
                                  vertical: AppSizes.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandTeal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                                  border: Border.all(
                                    color: AppColors.brandTeal.withValues(alpha: 0.35),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.arrow_right_circle,
                                      size: 11,
                                      color: AppColors.brandTeal,
                                    ),
                                    const SizedBox(width: AppSizes.xs),
                                    Text(
                                      'debt.focusOn'.tr(namedArgs: {'name': payoffResult.schedule.first.focusDebtName}),
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: AppColors.brandTeal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Section header
                    Row(
                      children: [
                        Text(
                          'debt.yourDebts'.tr(),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          debts.length == 1
                              ? 'debt.accountCount'.tr(namedArgs: {'count': '1'})
                              : 'debt.accountCountPlural'.tr(namedArgs: {'count': '${debts.length}'}),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),

                    // Debt cards
                    ...sorted.map((debt) {
                          final isFocus = payoffResult?.schedule.isNotEmpty ==
                                  true &&
                              payoffResult!.schedule.first.focusDebtName ==
                                  debt.name;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSizes.sm),
                            child: DebtCard(
                              debt: debt,
                              isFocusDebt: isFocus,
                              focusReason: strategy == DebtStrategy.avalanche
                                  ? 'debt.highestRate'.tr()
                                  : 'debt.lowestBalance'.tr(),
                              onLogPayment: () => _showLogPayment(debt),
                              onEdit: () => _showEditDebt(debt),
                              onHistory: () => _showPaymentHistory(debt),
                              onDelete: () => _deleteDebt(debt),
                            ),
                          );
                        }),
                    const SizedBox(height: AppSizes.md),
                    ExtraPaymentCard(
                      totalMinimum: debts.fold(0.0, (s, d) => s + d.minimumPayment),
                    ),
                  ],
                ),
              ),

              // ── Tab 1: Plan ───────────────────────────────────────────
              payoffResult == null
                  ? Center(
                      child: Text(
                        'debt.noPlan'.tr(),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.md, AppSizes.md, AppSizes.md, 100,
                      ),
                      children: [
                        DebtCostSplitCard(
                          payoffResult: activeResult ?? payoffResult,
                          totalCurrentBalance: totalBalance,
                        ),
                        const SizedBox(height: AppSizes.md),
                        PayoffTimelineChart(
                          result: activeResult ?? payoffResult,
                          debts: debts,
                        ),
                        const SizedBox(height: AppSizes.lg),
                        MonthlyScheduleList(
                          result: activeResult ?? payoffResult,
                          debts: debts,
                          monthsToShow: 3,
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

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color? valueColor;

  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.xs),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
