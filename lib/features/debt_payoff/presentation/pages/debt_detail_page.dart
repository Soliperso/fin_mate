import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat2Provider);

    double? progressPercent;
    double paidAmount = 0;
    if (debt.originalBalance != null && debt.originalBalance! > 0) {
      paidAmount =
          (debt.originalBalance! - debt.balance).clamp(0.0, debt.originalBalance!);
      progressPercent =
          (paidAmount / debt.originalBalance! * 100).clamp(0.0, 100.0);
    }

    final monthsLeft = debt.monthsToPayoffAtMinimum;

    // Next milestone
    String? milestoneHint;
    if (progressPercent != null && progressPercent < 100) {
      int next;
      if (progressPercent >= 75) {
        next = 100;
      } else if (progressPercent >= 50) {
        next = 75;
      } else if (progressPercent >= 25) {
        next = 50;
      } else {
        next = 25;
      }
      if (debt.originalBalance != null) {
        final targetBalance = debt.originalBalance! * (1 - next / 100);
        final toGo = (debt.balance - targetBalance).clamp(0.0, debt.balance);
        milestoneHint =
            'debtDetail.milestoneHint'.tr(namedArgs: {'pct': '$next', 'amount': currencyFormat.format(toGo)});
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.lg, AppSizes.lg, AppSizes.lg, 120),
      children: [
        // Large donut ring
        Center(
          child: DebtProgressRing(
            progressPercent: progressPercent,
            size: 160,
            fillColor: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // Paid / Remaining row
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'debtDetail.paid'.tr(),
                value: currencyFormat.format(paidAmount),
                valueColor: AppColors.success,
                icon: CupertinoIcons.arrow_down_circle_fill,
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _StatTile(
                label: 'debtDetail.remaining'.tr(),
                value: currencyFormat.format(debt.balance),
                valueColor: AppColors.error,
                icon: CupertinoIcons.arrow_up_circle_fill,
                iconColor: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),

        // APR / Min Payment row
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'debtDetail.apr'.tr(),
                value: '${debt.interestRate.toStringAsFixed(2)}%',
                icon: CupertinoIcons.percent,
                iconColor: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _StatTile(
                label: 'debtDetail.minPayment'.tr(),
                value: currencyFormat.format(debt.minimumPayment),
                icon: CupertinoIcons.money_dollar_circle,
                iconColor: AppColors.brandTeal,
              ),
            ),
          ],
        ),

        if (monthsLeft != null) ...[
          const SizedBox(height: AppSizes.sm),
          _StatTile(
            label: 'debtDetail.monthsLeft'.tr(),
            value: '$monthsLeft ${'debtDetail.months'.tr()}',
            icon: CupertinoIcons.clock,
            iconColor: AppColors.brandTeal,
          ),
        ],

        if (milestoneHint != null) ...[
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                  color: AppColors.brandTeal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.flag_fill,
                    color: AppColors.brandTeal, size: 16),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    milestoneHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (progressPercent == null) ...[
          const SizedBox(height: AppSizes.md),
          Container(
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
          ),
        ],
      ],
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
    final dateFormat = DateFormat('MMM d, yyyy', context.locale.languageCode);

    return paymentsAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(AppSizes.md),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.creditcard,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: AppSizes.md),
                Text(
                  'paymentHistory.noPayments'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  'paymentHistory.noPaymentsMessage'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final totalPaid = payments.fold<double>(0, (s, p) => s + p.amount);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.md, AppSizes.md, AppSizes.md, 120),
          children: [
            // Summary banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.checkmark_seal_fill,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    payments.length == 1
                        ? 'paymentHistory.paymentsLogged'.tr(
                            namedArgs: {'count': '${payments.length}'})
                        : 'paymentHistory.paymentsLoggedPlural'.tr(
                            namedArgs: {'count': '${payments.length}'}),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.success),
                  ),
                  const Spacer(),
                  Text(
                    'paymentHistory.totalPaid'.tr(
                        namedArgs: {'amount': currencyFormat.format(totalPaid)}),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            ...payments.asMap().entries.map((entry) {
              final p = entry.value;
              final isLast = entry.key == payments.length - 1;
              return _PaymentItem(
                payment: p,
                debt: debt,
                dateFormat: dateFormat,
                currencyFormat: currencyFormat,
                showDivider: !isLast,
              );
            }),
          ],
        );
      },
    );
  }
}

class _PaymentItem extends ConsumerWidget {
  final DebtPaymentEntity payment;
  final DebtEntity debt;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;
  final bool showDivider;

  const _PaymentItem({
    required this.payment,
    required this.debt,
    required this.dateFormat,
    required this.currencyFormat,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.checkmark,
                    color: AppColors.success, size: 18),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(payment.paymentDate),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (payment.notes != null && payment.notes!.isNotEmpty)
                      Text(
                        payment.notes!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(payment.amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: AppSizes.xs),
              GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CupertinoIcons.trash,
                      color: AppColors.error, size: 16),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 44),
      ],
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
    final success = await ref
        .read(debtNotifierProvider.notifier)
        .deletePayment(
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

// ── Details Tab ───────────────────────────────────────────────────────────────

class _DetailsTab extends ConsumerWidget {
  final DebtEntity debt;

  const _DetailsTab({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, 120),
      children: [
        _DetailRow(
          label: 'debtDetail.type'.tr(),
          value: debt.debtTypeDisplay,
        ),
        _DetailRow(
          label: 'debtDetail.balance'.tr(),
          value: currencyFormat.format(debt.balance),
        ),
        if (debt.originalBalance != null)
          _DetailRow(
            label: 'debtDetail.originalBalance'.tr(),
            value: currencyFormat.format(debt.originalBalance!),
          ),
        _DetailRow(
          label: 'debtDetail.interestRate'.tr(),
          value: '${debt.interestRate.toStringAsFixed(2)}% APR',
        ),
        _DetailRow(
          label: 'debtDetail.minimumPayment'.tr(),
          value: currencyFormat.format(debt.minimumPayment),
        ),
        if (debt.dueDay != null)
          _DetailRow(
            label: 'debtDetail.dueDay'.tr(),
            value: 'debtDetail.dueDayValue'
                .tr(namedArgs: {'day': '${debt.dueDay!}'}),
          ),
        if (debt.notes != null && debt.notes!.isNotEmpty)
          _DetailRow(
            label: 'debtDetail.notes'.tr(),
            value: debt.notes!,
          ),
        _DetailRow(
          label: 'debtDetail.addedOn'.tr(),
          value: dateFormat.format(debt.createdAt),
          isLast: true,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm + 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

// ── Shared stat tile ──────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.4)
              : AppColors.separator.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.xs + 2),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
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
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
