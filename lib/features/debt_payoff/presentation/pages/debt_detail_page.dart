import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_payment_entity.dart';
import '../providers/debt_providers.dart';
import '../widgets/debt_progress_ring.dart';
import '../widgets/edit_debt_bottom_sheet.dart';
import '../widgets/log_payment_bottom_sheet.dart';

class DebtDetailPage extends ConsumerStatefulWidget {
  final String debtId;

  const DebtDetailPage({super.key, required this.debtId});

  @override
  ConsumerState<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends ConsumerState<DebtDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debt = ref.watch(debtByIdProvider(widget.debtId));

    if (debt == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        automaticallyImplyLeading: false,
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          debt.name,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => GlassBottomSheet.show(
              context: context,
              child: EditDebtBottomSheet(debt: debt),
            ),
            child: Text(
              'common.edit'.tr(),
              style: const TextStyle(
                color: AppColors.brandTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.brandTeal,
          labelColor: AppColors.brandTeal,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'debtDetail.progress'.tr()),
            Tab(text: 'debtDetail.transactions'.tr()),
            Tab(text: 'debtDetail.details'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ProgressTab(debt: debt),
          _TransactionsTab(debt: debt),
          _DetailsTab(debt: debt),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        child: SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeightMd,
          child: ElevatedButton.icon(
            onPressed: () => GlassBottomSheet.show(
              context: context,
              child: LogPaymentBottomSheet(debt: debt),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.brandTeal.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            icon: const Icon(CupertinoIcons.add),
            label: Text('debtCard.logPayment'.tr()),
          ),
        ),
      ),
    );
  }
}

// ── Progress Tab ──────────────────────────────────────────────────────────────

class _ProgressTab extends ConsumerWidget {
  final DebtEntity debt;

  const _ProgressTab({required this.debt});

  static DateTime? _nextDueDate(int? dueDay) {
    if (dueDay == null) return null;
    final now = DateTime.now();
    try {
      final thisMonth = DateTime(now.year, now.month, dueDay);
      if (thisMonth.isAfter(now)) return thisMonth;
      return DateTime(now.year, now.month + 1, dueDay);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final currency0 = ref.watch(currencyFormat0Provider);
    final shortDateFormat = DateFormat('MMM d', context.locale.languageCode);
    final paymentsAsync = ref.watch(debtPaymentsProvider(debt.id));

    double principalPaid = 0;
    double? progressPercent;
    if (debt.originalBalance != null && debt.originalBalance! > 0) {
      principalPaid =
          (debt.originalBalance! - debt.balance).clamp(0.0, debt.originalBalance!);
      progressPercent =
          (principalPaid / debt.originalBalance! * 100).clamp(0.0, 100.0);
    }

    final dailyInterest = debt.balance * debt.interestRate / 100 / 365;
    final monthsLeft = debt.monthsToPayoffAtMinimum;
    final nextDue = _nextDueDate(debt.dueDay);

    return paymentsAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.md, AppSizes.md, AppSizes.md, 120),
        children: const [
          SkeletonCard(),
          SizedBox(height: AppSizes.sm),
          SkeletonCard(),
          SizedBox(height: AppSizes.sm),
          SkeletonCard(),
        ],
      ),
      error: (_, __) => _buildBody(
        context: context,
        currencyFormat: currencyFormat,
        currency0: currency0,
        shortDateFormat: shortDateFormat,
        principalPaid: principalPaid,
        progressPercent: progressPercent,
        dailyInterest: dailyInterest,
        monthsLeft: monthsLeft,
        nextDue: nextDue,
        totalPaid: 0,
        interestPaid: 0,
        lastPayment: null,
      ),
      data: (payments) {
        final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
        final interestPaid =
            (totalPaid - principalPaid).clamp(0.0, double.infinity);
        final lastPayment = payments.isNotEmpty ? payments.first : null;

        return _buildBody(
          context: context,
          currencyFormat: currencyFormat,
          currency0: currency0,
          shortDateFormat: shortDateFormat,
          principalPaid: principalPaid,
          progressPercent: progressPercent,
          dailyInterest: dailyInterest,
          monthsLeft: monthsLeft,
          nextDue: nextDue,
          totalPaid: totalPaid,
          interestPaid: interestPaid,
          lastPayment: lastPayment,
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required NumberFormat currencyFormat,
    required NumberFormat currency0,
    required DateFormat shortDateFormat,
    required double principalPaid,
    required double? progressPercent,
    required double dailyInterest,
    required int? monthsLeft,
    required DateTime? nextDue,
    required double totalPaid,
    required double interestPaid,
    required DebtPaymentEntity? lastPayment,
  }) {
    final hasBreakdown = debt.originalBalance != null &&
        debt.originalBalance! > 0 &&
        (principalPaid > 0 || totalPaid > 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(13, AppSizes.md, 13, 120),
      children: [
        // ── Hero card: donut + legend + progress badge ──────────────────────
        _HeroCard(
          progressPercent: progressPercent,
          hasBreakdown: hasBreakdown,
          principalPaid: principalPaid,
          interestPaid: interestPaid,
          principalRemaining: debt.balance,
          currencyFormat: currencyFormat,
          currency0: currency0,
        ),

        const SizedBox(height: AppSizes.md),

        // ── Payment card (last payment + next due) ──────────────────────────
        if (lastPayment != null || nextDue != null)
          _PaymentCard(
            lastPayment: lastPayment,
            nextDue: nextDue,
            minPayment: debt.minimumPayment,
            shortDateFormat: shortDateFormat,
            currencyFormat: currencyFormat,
          ),

        if (lastPayment != null || nextDue != null)
          const SizedBox(height: AppSizes.md),

        // ── Loan metrics section ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: Text(
            'LOAN METRICS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),
        ),

        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'debtDetail.apr'.tr(),
                value: '${debt.interestRate.toStringAsFixed(2)}%',
                icon: CupertinoIcons.percent,
                accentColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _MetricTile(
                label: 'debtDetail.dailyInterest'.tr(),
                value: '${currencyFormat.format(dailyInterest)}/day',
                icon: CupertinoIcons.clock_fill,
                accentColor: AppColors.systemOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'debtDetail.minPayment'.tr(),
                value: currencyFormat.format(debt.minimumPayment),
                icon: CupertinoIcons.money_dollar_circle,
                accentColor: AppColors.brandTeal,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            if (monthsLeft != null)
              Expanded(
                child: _MetricTile(
                  label: 'debtDetail.monthsLeft'.tr(),
                  value: '$monthsLeft ${'debtDetail.months'.tr()}',
                  icon: CupertinoIcons.calendar,
                  accentColor: AppColors.brandTeal,
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),

        // ── Milestone card ──────────────────────────────────────────────────
        if (progressPercent != null) ...[
          const SizedBox(height: AppSizes.md),
          _MilestoneCard(
            progressPercent: progressPercent,
            originalBalance: debt.originalBalance!,
            currentBalance: debt.balance,
            currencyFormat: currencyFormat,
          ),
        ],

        // ── No original balance notice ──────────────────────────────────────
        if (progressPercent == null) ...[
          const SizedBox(height: AppSizes.md),
          _NoProgressNotice(),
        ],
      ],
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final double? progressPercent;
  final bool hasBreakdown;
  final double principalPaid;
  final double interestPaid;
  final double principalRemaining;
  final NumberFormat currencyFormat;
  final NumberFormat currency0;

  const _HeroCard({
    required this.progressPercent,
    required this.hasBreakdown,
    required this.principalPaid,
    required this.interestPaid,
    required this.principalRemaining,
    required this.currencyFormat,
    required this.currency0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0D2224), Color(0xFF111111)]
              : const [Color(0xFFEDF7F8), Color(0xFFF8FDFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(
          color: AppColors.brandTeal
              .withValues(alpha: isDark ? 0.18 : 0.12),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.lg, AppSizes.md, AppSizes.md),
            child: Column(
              children: [
                // Donut
                hasBreakdown
                    ? _DonutOnly(
                        principalPaid: principalPaid,
                        interestPaid: interestPaid,
                        principalRemaining: principalRemaining,
                        currency0: currency0,
                      )
                    : DebtProgressRing(
                        progressPercent: progressPercent,
                        size: 180,
                        fillColor: AppColors.success,
                      ),

                const SizedBox(height: AppSizes.md),

                // Vertical legend — only non-zero rows
                if (hasBreakdown) ...[
                  _DonutLegend(
                    principalPaid: principalPaid,
                    interestPaid: interestPaid,
                    principalRemaining: principalRemaining,
                    currencyFormat: currencyFormat,
                  ),
                ],
              ],
            ),
          ),

          // Progress % badge — top right
          if (progressPercent != null)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm + 2, vertical: AppSizes.xs + 1),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: AppColors.brandTeal
                        .withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Text(
                  '${progressPercent!.toStringAsFixed(0)}% paid',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Donut (chart only, no legend) ────────────────────────────────────────────

class _DonutOnly extends StatelessWidget {
  final double principalPaid;
  final double interestPaid;
  final double principalRemaining;
  final NumberFormat currency0;

  const _DonutOnly({
    required this.principalPaid,
    required this.interestPaid,
    required this.principalRemaining,
    required this.currency0,
  });

  @override
  Widget build(BuildContext context) {
    const size = 180.0;
    final total = principalPaid + interestPaid + principalRemaining;
    if (total <= 0) return const SizedBox(width: size, height: size);

    final sections = <PieChartSectionData>[
      if (principalPaid > 0)
        PieChartSectionData(
          value: principalPaid,
          color: AppColors.success,
          radius: size * 0.18,
          title: '',
          showTitle: false,
        ),
      if (interestPaid > 0)
        PieChartSectionData(
          value: interestPaid,
          color: AppColors.error,
          radius: size * 0.18,
          title: '',
          showTitle: false,
        ),
      PieChartSectionData(
        value: principalRemaining > 0 ? principalRemaining : 0.001,
        color: principalRemaining > 0
            ? AppColors.warning
            : Colors.grey.withValues(alpha: 0.15),
        radius: size * 0.18,
        title: '',
        showTitle: false,
      ),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 3,
              centerSpaceRadius: size * 0.32,
              sections: sections,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currency0.format(principalRemaining),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'debtDetail.remaining'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Donut Legend (vertical) ───────────────────────────────────────────────────

class _DonutLegend extends StatelessWidget {
  final double principalPaid;
  final double interestPaid;
  final double principalRemaining;
  final NumberFormat currencyFormat;

  const _DonutLegend({
    required this.principalPaid,
    required this.interestPaid,
    required this.principalRemaining,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_LegendData>[
      if (principalPaid > 0)
        _LegendData(
          color: AppColors.success,
          label: 'debtDetail.principalPaid'.tr(),
          value: currencyFormat.format(principalPaid),
        ),
      if (interestPaid > 0)
        _LegendData(
          color: AppColors.error,
          label: 'debtDetail.interestPaid'.tr(),
          value: currencyFormat.format(interestPaid),
        ),
      _LegendData(
        color: AppColors.warning,
        label: 'debtDetail.remaining'.tr(),
        value: currencyFormat.format(principalRemaining),
      ),
    ];

    return Column(
      children: items
          .asMap()
          .entries
          .map((e) => Column(
                children: [
                  _LegendRow(data: e.value),
                  if (e.key < items.length - 1)
                    Divider(
                      height: AppSizes.sm,
                      color: AppColors.separator.withValues(alpha: 0.3),
                    ),
                ],
              ))
          .toList(),
    );
  }
}

class _LegendData {
  final Color color;
  final String label;
  final String value;

  const _LegendData(
      {required this.color, required this.label, required this.value});
}

class _LegendRow extends StatelessWidget {
  final _LegendData data;

  const _LegendRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            data.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          Text(
            data.value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: data.color,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Payment Card ──────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final DebtPaymentEntity? lastPayment;
  final DateTime? nextDue;
  final double minPayment;
  final DateFormat shortDateFormat;
  final NumberFormat currencyFormat;

  const _PaymentCard({
    required this.lastPayment,
    required this.nextDue,
    required this.minPayment,
    required this.shortDateFormat,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.25),
        ),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Column(
        children: [
          if (lastPayment != null)
            _PaymentRow(
              icon: CupertinoIcons.checkmark_seal_fill,
              iconColor: AppColors.success,
              label: 'debtDetail.lastPayment'.tr(),
              primary: currencyFormat.format(lastPayment!.amount),
              secondary: shortDateFormat.format(lastPayment!.paymentDate),
              primaryColor: AppColors.success,
            ),
          if (lastPayment != null && nextDue != null)
            Divider(
              height: 1,
              indent: 48,
              endIndent: AppSizes.md,
              color: isDark
                  ? AppColors.separatorDark.withValues(alpha: 0.4)
                  : AppColors.separator.withValues(alpha: 0.3),
            ),
          if (nextDue != null)
            _PaymentRow(
              icon: CupertinoIcons.bell_fill,
              iconColor: AppColors.error,
              label: 'debtDetail.nextDueDate'.tr(),
              primary: DateFormat(AppDateFormats.mediumDate).format(nextDue!),
              secondary: currencyFormat.format(minPayment),
              primaryColor: null,
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String primary;
  final String secondary;
  final Color? primaryColor;

  const _PaymentRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.primary,
    required this.secondary,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  primary,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                ),
              ],
            ),
          ),
          Text(
            secondary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Metric Tile ───────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.25),
        ),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 4,
                color: accentColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm + 2,
                      vertical: AppSizes.sm + 2),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Icon(icon, color: accentColor, size: 18),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
      ),
    );
  }
}

// ── Milestone Card ────────────────────────────────────────────────────────────

class _MilestoneCard extends StatelessWidget {
  final double progressPercent;
  final double originalBalance;
  final double currentBalance;
  final NumberFormat currencyFormat;

  const _MilestoneCard({
    required this.progressPercent,
    required this.originalBalance,
    required this.currentBalance,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Next milestone
    int nextMilestonePct;
    if (progressPercent >= 75) {
      nextMilestonePct = 100;
    } else if (progressPercent >= 50) {
      nextMilestonePct = 75;
    } else if (progressPercent >= 25) {
      nextMilestonePct = 50;
    } else {
      nextMilestonePct = 25;
    }

    final targetBalance = originalBalance * (1 - nextMilestonePct / 100);
    final toGo = (currentBalance - targetBalance).clamp(0.0, currentBalance);
    final hintText = 'debtDetail.milestoneHint'.tr(namedArgs: {
      'pct': '$nextMilestonePct',
      'amount': currencyFormat.format(toGo),
    });

    const milestones = [25, 50, 75, 100];

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.25),
        ),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(CupertinoIcons.flag_fill,
                  color: AppColors.brandTeal, size: 16),
              const SizedBox(width: AppSizes.xs + 2),
              Text(
                'Next Milestone',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${progressPercent.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.sm + 4),

          // Progress bar with milestone markers
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.tertiarySystemBackgroundDark
                          : AppColors.systemGray5,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: (progressPercent / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brandTeal, AppColors.success],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                  ),
                  // Milestone dots
                  ...milestones.map((m) {
                    final x = barWidth * m / 100 - 5;
                    final reached = progressPercent >= m;
                    return Positioned(
                      left: x,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: reached
                              ? AppColors.brandTeal
                              : (isDark
                                  ? AppColors.tertiarySystemBackgroundDark
                                  : AppColors.systemGray4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: reached
                                ? AppColors.brandTeal
                                : (isDark
                                    ? AppColors.separatorDark
                                    : AppColors.separator),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),

          const SizedBox(height: AppSizes.sm + 2),

          // Milestone labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: milestones.map((m) {
              final reached = progressPercent >= m;
              return Text(
                '$m%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: reached
                          ? AppColors.brandTeal
                          : AppColors.textSecondary,
                      fontWeight: reached ? FontWeight.w700 : FontWeight.w400,
                    ),
              );
            }).toList(),
          ),

          if (progressPercent < 100) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              hintText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── No Progress Notice ────────────────────────────────────────────────────────

class _NoProgressNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Text(
        'debtDetail.noOriginalBalance'.tr(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Transactions Tab ──────────────────────────────────────────────────────────

class _TransactionsTab extends ConsumerWidget {
  final DebtEntity debt;

  const _TransactionsTab({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(debtPaymentsProvider(debt.id));
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final dateFormat =
        DateFormat(AppDateFormats.mediumDate, context.locale.languageCode);
    final monthFormat = DateFormat('MMMM yyyy', context.locale.languageCode);

    return paymentsAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.fromLTRB(13, AppSizes.md, 13, 120),
        children: const [
          SkeletonCard(),
          SizedBox(height: AppSizes.sm),
          SkeletonCard(),
          SizedBox(height: AppSizes.sm),
          SkeletonCard(),
        ],
      ),
      error: (_, __) => Center(
        child: Text(
          'paymentHistory.failedToLoad'.tr(),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.creditcard,
                      size: 32,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'paymentHistory.noPayments'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'paymentHistory.noPaymentsMessage'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final totalPaid = payments.fold<double>(0, (s, p) => s + p.amount);
        final avgPayment = totalPaid / payments.length;

        // Group payments by calendar month
        final months = <String>[];
        final grouped = <String, List<DebtPaymentEntity>>{};
        for (final p in payments) {
          final key = monthFormat.format(p.paymentDate);
          if (!grouped.containsKey(key)) {
            months.add(key);
            grouped[key] = [];
          }
          grouped[key]!.add(p);
        }
        final showMonthHeaders = months.length > 1;

        return ListView(
          padding: const EdgeInsets.fromLTRB(13, AppSizes.md, 13, 120),
          children: [
            _TransactionSummaryCard(
              totalPaid: totalPaid,
              count: payments.length,
              avgPayment: avgPayment,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: AppSizes.md),
            for (final month in months) ...[
              if (showMonthHeaders)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppSizes.xs + 2, top: AppSizes.xs),
                  child: Text(
                    month.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
              for (final p in grouped[month]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: _PaymentItemCard(
                    payment: p,
                    debt: debt,
                    dateFormat: dateFormat,
                    currencyFormat: currencyFormat,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

// ── Payment Item Card ─────────────────────────────────────────────────────────

class _PaymentItemCard extends ConsumerWidget {
  final DebtPaymentEntity payment;
  final DebtEntity debt;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  const _PaymentItemCard({
    required this.payment,
    required this.debt,
    required this.dateFormat,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.25),
        ),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.success),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm + 2, vertical: AppSizes.sm + 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dateFormat.format(payment.paymentDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (payment.notes != null &&
                                payment.notes!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                payment.notes!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currencyFormat.format(payment.amount),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _confirmDelete(context, ref),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: const Icon(CupertinoIcons.trash,
                                  color: AppColors.error, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('paymentHistory.undoPayment'.tr()),
        content: Text(
          'paymentHistory.undoConfirmation'.tr(namedArgs: {
            'amount': NumberFormat.currency(symbol: '\$').format(payment.amount)
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('paymentHistory.undoButton'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success =
        await ref.read(debtNotifierProvider.notifier).deletePayment(
              paymentId: payment.id,
              debtId: payment.debtId,
              amount: payment.amount,
            );
    if (!context.mounted) return;
    if (success) {
      ref.invalidate(debtPaymentsProvider(debt.id));
    }
  }
}

// ── Transaction Summary Card ──────────────────────────────────────────────────

class _TransactionSummaryCard extends StatelessWidget {
  final double totalPaid;
  final int count;
  final double avgPayment;
  final NumberFormat currencyFormat;

  const _TransactionSummaryCard({
    required this.totalPaid,
    required this.count,
    required this.avgPayment,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.25),
        ),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'paymentHistory.totalPaid'.tr(
                      namedArgs: {'amount': currencyFormat.format(totalPaid)}),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  count == 1
                      ? 'paymentHistory.paymentsLogged'
                          .tr(namedArgs: {'count': '$count'})
                      : 'paymentHistory.paymentsLoggedPlural'
                          .tr(namedArgs: {'count': '$count'}),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(avgPayment),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'avg',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Details Tab ───────────────────────────────────────────────────────────────

class _DetailsTab extends ConsumerWidget {
  final DebtEntity debt;

  const _DetailsTab({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final dateFormat = DateFormat(AppDateFormats.mediumDate);
    final dailyInterest = debt.balance * debt.interestRate / 100 / 365;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardDecoration = BoxDecoration(
      color: isDark
          ? AppColors.secondarySystemBackgroundDark
          : AppColors.systemBackground,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      border: Border.all(
        color: isDark
            ? AppColors.separatorDark.withValues(alpha: 0.5)
            : AppColors.separator.withValues(alpha: 0.25),
      ),
      boxShadow: AppColors.cardShadow(isDark),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(13, AppSizes.lg, 13, 120),
      children: [
        // ── Account Details ──────────────────────────────────────────────────
        _SectionHeader(label: 'debtDetail.accountDetails'.tr()),
        const SizedBox(height: AppSizes.xs),
        Container(
          decoration: cardDecoration,
          child: Column(
            children: [
              _IconDetailRow(
                icon: CupertinoIcons.money_dollar_circle,
                iconColor: AppColors.brandTeal,
                label: 'debtDetail.payoffAmount'.tr(),
                value: currencyFormat.format(debt.balance),
              ),
              _IconDetailRow(
                icon: CupertinoIcons.creditcard,
                iconColor: AppColors.brandTeal,
                label: 'debtDetail.minimumPayment'.tr(),
                value: currencyFormat.format(debt.minimumPayment),
              ),
              _IconDetailRow(
                icon: CupertinoIcons.clock_fill,
                iconColor: AppColors.systemOrange,
                label: 'debtDetail.dailyInterest'.tr(),
                value: '${currencyFormat.format(dailyInterest)}/day',
              ),
              if (debt.dueDay != null)
                _IconDetailRow(
                  icon: CupertinoIcons.calendar,
                  iconColor: AppColors.error,
                  label: 'debtDetail.dueDay'.tr(),
                  value: 'debtDetail.dueDayValue'
                      .tr(namedArgs: {'day': '${debt.dueDay!}'}),
                  isLast: true,
                )
              else
                _IconDetailRow(
                  icon: CupertinoIcons.tag_fill,
                  iconColor: AppColors.systemPurple,
                  label: 'debtDetail.type'.tr(),
                  value: debt.debtTypeDisplay,
                  isLast: true,
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        // ── Loan Terms ───────────────────────────────────────────────────────
        _SectionHeader(label: 'debtDetail.loanTerms'.tr()),
        const SizedBox(height: AppSizes.xs),
        Container(
          decoration: cardDecoration,
          child: Column(
            children: [
              if (debt.originalBalance != null)
                _IconDetailRow(
                  icon: CupertinoIcons.chart_bar_alt_fill,
                  iconColor: AppColors.textSecondary,
                  label: 'debtDetail.originalBalance'.tr(),
                  value: currencyFormat.format(debt.originalBalance!),
                ),
              if (debt.dueDay != null)
                _IconDetailRow(
                  icon: CupertinoIcons.tag_fill,
                  iconColor: AppColors.systemPurple,
                  label: 'debtDetail.type'.tr(),
                  value: debt.debtTypeDisplay,
                ),
              _IconDetailRow(
                icon: CupertinoIcons.percent,
                iconColor: AppColors.systemOrange,
                label: 'debtDetail.interestRate'.tr(),
                value: '${debt.interestRate.toStringAsFixed(2)}% APR',
              ),
              if (debt.notes != null && debt.notes!.isNotEmpty)
                _IconDetailRow(
                  icon: CupertinoIcons.text_bubble,
                  iconColor: AppColors.textSecondary,
                  label: 'debtDetail.notes'.tr(),
                  value: debt.notes!,
                ),
              _IconDetailRow(
                icon: CupertinoIcons.calendar_badge_plus,
                iconColor: AppColors.textSecondary,
                label: 'debtDetail.addedOn'.tr(),
                value: dateFormat.format(debt.createdAt),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isLast;

  const _IconDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.secondaryLabel,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 56,
            endIndent: AppSizes.md,
            color: isDark
                ? AppColors.separatorDark.withValues(alpha: 0.4)
                : AppColors.separator.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
