import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../core/providers/feature_flag_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/success_animation.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/services/payoff_calculator.dart' show DebtStrategy;
import '../providers/debt_providers.dart';
import '../widgets/add_debt_bottom_sheet.dart';
import '../widgets/debt_card.dart';
import '../widgets/debt_hero_card.dart';
import '../widgets/debt_milestone_card.dart';
import '../widgets/edit_debt_bottom_sheet.dart';
import '../widgets/extra_payment_card.dart';
import '../widgets/log_payment_bottom_sheet.dart';
import '../widgets/monthly_schedule_list.dart';
import '../widgets/payment_history_sheet.dart';
import '../widgets/payoff_timeline_chart.dart';
import '../widgets/debt_cost_split_card.dart';
import '../widgets/payment_calendar_tab.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
    // The paid-off celebration is fired from within LogPaymentBottomSheet
    // itself, so every entry point gets it consistently.
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
      SuccessSnackbar.show(context,
          message: 'debt.deleted'.tr(namedArgs: {'name': debt.name}));
    } else {
      ErrorSnackbar.show(context, message: 'debt.failedToDelete'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureFlags = ref.watch(appFeatureFlagsProvider).valueOrNull;
    if (!featureEnabled(featureFlags, 'debt_payoff')) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text('debt.title'.tr()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: EmptyStateCard(
              icon: CupertinoIcons.lock_shield,
              title: 'Feature Unavailable',
              message:
                  'Debt Payoff is currently disabled.\nContact your administrator to enable it.',
              backgroundColor: AppColors.brandTeal,
            ),
          ),
        ),
      );
    }

    final debtsAsync = ref.watch(debtsProvider);
    final strategy = ref.watch(selectedStrategyProvider);
    final payoffResult = ref.watch(payoffResultProvider);
    final extra = ref.watch(extraPaymentProvider);
    final simResult = ref.watch(simulatedPayoffProvider);
    final activeResult =
        extra > 0 && simResult != null ? simResult : payoffResult;

    final dateFormat = DateFormat(AppDateFormats.monthYear);
    final currencyFormat = ref.watch(currencyFormat0Provider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'debt.title'.tr(),
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(fontWeight: FontWeight.bold),
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
            Tab(text: 'debt.trackTab'.tr()),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircularIconButton(
              icon: CupertinoIcons.add,
              onTap: _showAddDebt,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: debtsAsync.when(
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
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EmptyStateCard(
                            icon: CupertinoIcons.creditcard,
                            title: 'debt.noDebts'.tr(),
                            message: 'debt.noDebtsMessage'.tr(),
                            backgroundColor: AppColors.brandTeal,
                          ),
                          const SizedBox(height: AppSizes.lg),
                          SizedBox(
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
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusFull),
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
                    ),
                  ),
                ),
              );
            }

            final activeDebts =
                debts.where((d) => !d.isPaidOff).toList(growable: false);
            final paidOffDebts =
                debts.where((d) => d.isPaidOff).toList(growable: false);
            final sorted = _sortedDebts(activeDebts);
            final totalBalance =
                activeDebts.fold<double>(0, (s, d) => s + d.balance);

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
                      AppSizes.md,
                      AppSizes.md,
                      AppSizes.md,
                      100,
                    ),
                    children: [
                      // Hero card — uses simulated result when extra payment is active
                      DebtHeroCard(
                        totalBalance: totalBalance,
                        debtCount: activeDebts.length,
                        payoffResult: activeResult ?? payoffResult,
                        debts: activeDebts,
                        extraMonthly: extra,
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Strategy card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusCard),
                          side: BorderSide(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
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
                                    'debt.strategy'.tr().toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.systemGray,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.8,
                                        ),
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
                              // Strategy pill buttons
                              Row(
                                children: [
                                  _StrategyPill(
                                    label: 'debt.avalanche'.tr(),
                                    subtitle: 'Highest APR first',
                                    isSelected:
                                        strategy == DebtStrategy.avalanche,
                                    onTap: () => ref
                                        .read(
                                            selectedStrategyProvider.notifier)
                                        .state = DebtStrategy.avalanche,
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  _StrategyPill(
                                    label: 'debt.snowball'.tr(),
                                    subtitle: 'Smallest balance first',
                                    isSelected:
                                        strategy == DebtStrategy.snowball,
                                    onTap: () => ref
                                        .read(
                                            selectedStrategyProvider.notifier)
                                        .state = DebtStrategy.snowball,
                                  ),
                                ],
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
                              if (payoffResult != null &&
                                  payoffResult.schedule.isNotEmpty) ...[
                                const SizedBox(height: AppSizes.sm),

                                if (payoffResult.hitMaxMonths) ...[
                                  // Cap-hit: min payment < monthly interest — show actionable warning
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSizes.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.error
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radiusSm),
                                      border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.25),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons
                                              .exclamationmark_triangle_fill,
                                          size: 14,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(width: AppSizes.xs),
                                        Expanded(
                                          child: Text(
                                            'debtHero.neverPaysOffWarning'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: AppColors.error,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // 3-metric summary row (normal case)
                                  Row(
                                    children: [
                                      _MetricItem(
                                        icon: CupertinoIcons.calendar,
                                        iconColor: AppColors.brandTeal,
                                        value: dateFormat
                                            .format(payoffResult.debtFreeDate),
                                      ),
                                      const SizedBox(width: AppSizes.sm),
                                      _MetricItem(
                                        icon: CupertinoIcons.clock,
                                        iconColor: AppColors.brandTeal,
                                        value:
                                            '${payoffResult.totalMonths} ${'debt.moAbbr'.tr()}',
                                      ),
                                      const SizedBox(width: AppSizes.sm),
                                      _MetricItem(
                                        icon: CupertinoIcons.money_dollar,
                                        iconColor: AppColors.error,
                                        value: currencyFormat.format(
                                            payoffResult.totalInterestPaid),
                                        valueColor: AppColors.error,
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: AppSizes.sm),

                                // Focus chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.sm,
                                    vertical: AppSizes.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandTeal
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppSizes.radiusFull),
                                    border: Border.all(
                                      color: AppColors.brandTeal
                                          .withValues(alpha: 0.35),
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
                                        'debt.focusOn'.tr(namedArgs: {
                                          'name': payoffResult
                                              .schedule.first.focusDebtName
                                        }),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
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

                      // Active debts section — hidden when everything is paid off
                      if (activeDebts.isNotEmpty) ...[
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
                              activeDebts.length == 1
                                  ? 'debt.accountCount'
                                      .tr(namedArgs: {'count': '1'})
                                  : 'debt.accountCountPlural'.tr(namedArgs: {
                                      'count': '${activeDebts.length}'
                                    }),
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
                          final isFocus =
                              payoffResult?.schedule.isNotEmpty == true &&
                                  payoffResult!.schedule.first.focusDebtName ==
                                      debt.name;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.sm),
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
                          totalMinimum: activeDebts.fold(
                              0.0, (s, d) => s + d.minimumPayment),
                        ),
                        const SizedBox(height: AppSizes.md),
                      ],
                      const DebtMilestoneCard(),

                      // Paid-off ("Debt Free") section — collapsed by default
                      if (paidOffDebts.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.md),
                        _PaidOffSection(
                          debts: paidOffDebts,
                          onTapDebt: _showPaymentHistory,
                          onDeleteDebt: _deleteDebt,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Tab 1: Plan ───────────────────────────────────────────
                payoffResult == null
                    ? Center(
                        child: Text(
                          'debt.noPlan'.tr(),
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.md,
                          AppSizes.md,
                          AppSizes.md,
                          100,
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

                // ── Tab 2: Track ──────────────────────────────────────────
                const PaymentCalendarTab(),
              ],
            );
          },
        ),
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

class _StrategyPill extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _StrategyPill({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandTeal
                  : AppColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible "Paid Off" section listing debts that have been fully cleared.
/// Collapsed by default — preserves payoff history without cluttering the
/// active debt list.
class _PaidOffSection extends StatefulWidget {
  final List<DebtEntity> debts;
  final void Function(DebtEntity) onTapDebt;
  final void Function(DebtEntity) onDeleteDebt;

  const _PaidOffSection({
    required this.debts,
    required this.onTapDebt,
    required this.onDeleteDebt,
  });

  @override
  State<_PaidOffSection> createState() => _PaidOffSectionState();
}

class _PaidOffSectionState extends State<_PaidOffSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.xs),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 16,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'debt.paidOffSection'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '${widget.debts.length}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...widget.debts.map(
              (d) => _PaidOffRow(
                debt: d,
                onTap: () => widget.onTapDebt(d),
                onDelete: () => widget.onDeleteDebt(d),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single row inside the Paid Off section. Resolves the payoff date from the
/// debt's most recent payment.
class _PaidOffRow extends ConsumerWidget {
  final DebtEntity debt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PaidOffRow({
    required this.debt,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(debtPaymentsProvider(debt.id)).valueOrNull;
    final paidOffDate = payments?.fold<DateTime?>(
      null,
      (latest, p) => latest == null || p.paymentDate.isAfter(latest)
          ? p.paymentDate
          : latest,
    );
    final subtitle = paidOffDate != null
        ? 'debt.paidOffOn'.tr(namedArgs: {
            'date': DateFormat(AppDateFormats.mediumDate).format(paidOffDate),
          })
        : debt.debtTypeDisplay;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.md,
          AppSizes.sm,
          AppSizes.xs,
          AppSizes.sm,
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.checkmark_alt_circle_fill,
              size: 18,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            PopupMenuButton<void>(
              icon: const Icon(
                CupertinoIcons.ellipsis,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onSelected: (_) => onDelete(),
              itemBuilder: (context) => [
                PopupMenuItem<void>(
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.delete,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: AppSizes.sm),
                      Text('debtCard.deleteDebt'.tr()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
