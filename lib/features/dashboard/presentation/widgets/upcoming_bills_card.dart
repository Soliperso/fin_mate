import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import '../../../recurring_transactions/presentation/providers/recurring_transactions_providers.dart';

class UpcomingBillsCard extends ConsumerWidget {
  const UpcomingBillsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final upcomingAsync = ref.watch(upcomingRecurringTransactionsProvider);

    final bills = upcomingAsync.valueOrNull
        ?.where((t) => t.type == 'expense' && t.isActive)
        .toList()
      ?..sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));

    final isLoading = upcomingAsync.isLoading;
    final isEmpty = !isLoading && (bills == null || bills.isEmpty);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              AppSizes.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'upcomingBills.title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                GestureDetector(
                  onTap: () => context.push('/recurring-transactions'),
                  child: Text(
                    'upcomingBills.viewAll'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                AppSizes.sm,
                AppSizes.md,
                AppSizes.md,
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.systemGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: AppSizes.iconLg,
                        color: AppColors.systemGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'upcomingBills.noBills'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            _BillsList(bills: bills!, isDark: isDark),
        ],
      ),
    );
  }
}

class _BillsList extends ConsumerWidget {
  final List<RecurringTransactionEntity> bills;
  final bool isDark;

  const _BillsList({required this.bills, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = bills.length > 3 ? bills.sublist(0, 3) : bills;
    final currencyFormat = ref.watch(currencyFormat2Provider);

    return Column(
      children: [
        for (int i = 0; i < visible.length; i++) ...[
          _BillRow(
            bill: visible[i],
            currencyFormat: currencyFormat,
            isDark: isDark,
          ),
          if (i < visible.length - 1)
            Divider(
              height: 0,
              thickness: 0.5,
              indent: 60,
              endIndent: AppSizes.md,
              color: Theme.of(context).dividerColor,
            ),
        ],
        const SizedBox(height: AppSizes.xs),
      ],
    );
  }
}

class _BillRow extends StatelessWidget {
  final RecurringTransactionEntity bill;
  final NumberFormat currencyFormat;
  final bool isDark;

  const _BillRow({
    required this.bill,
    required this.currencyFormat,
    required this.isDark,
  });

  Color _dueColor() {
    if (bill.isOverdue || bill.daysUntilDue <= 0) return AppColors.systemRed;
    if (bill.daysUntilDue <= 7) return AppColors.systemOrange;
    return AppColors.systemGreen;
  }

  String _dueLabel(BuildContext context) {
    if (bill.isOverdue) return 'upcomingBills.overdue'.tr();
    final days = bill.daysUntilDue;
    if (days == 0) return 'upcomingBills.dueToday'.tr();
    if (days == 1) return 'upcomingBills.dueTomorrow'.tr();
    return 'upcomingBills.dueInDays'.tr(namedArgs: {'days': '$days'});
  }

  @override
  Widget build(BuildContext context) {
    final dueColor = _dueColor();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.systemRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Icon(
              CupertinoIcons.arrow_up,
              color: AppColors.systemRed,
              size: AppSizes.iconSm,
            ),
          ),
          const SizedBox(width: AppSizes.sm + 4),
          // Name + due chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.description ?? bill.categoryName ?? 'Bill',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.85),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bill.categoryName != null &&
                    bill.description != null &&
                    bill.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    bill.categoryName!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dueColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    _dueLabel(context),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dueColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Amount
          Text(
            currencyFormat.format(bill.amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.systemRed,
                ),
          ),
        ],
      ),
    );
  }
}
