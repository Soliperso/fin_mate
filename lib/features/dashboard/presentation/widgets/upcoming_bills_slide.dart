import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../recurring_transactions/presentation/providers/recurring_transactions_providers.dart';

class UpcomingBillsSlide extends ConsumerWidget {
  const UpcomingBillsSlide({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(upcomingRecurringTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return billsAsync.when(
      data: (all) {
        final bills = all.where((t) => t.type == 'expense').toList();
        if (bills.isEmpty) return const SizedBox.shrink();

        final next = bills.first;
        final extraCount = bills.length - 1;
        final Color accentColor;
        if (next.isOverdue || next.daysUntilDue <= 0) {
          accentColor = AppColors.systemRed;
        } else if (next.daysUntilDue <= 7) {
          accentColor = AppColors.systemOrange;
        } else {
          accentColor = AppColors.systemGreen;
        }
        final currencyFmt = ref.watch(currencyFormat2Provider);
        final convFactor = ref.watch(conversionFactorProvider);

        String dueLabel;
        if (next.isOverdue) {
          dueLabel = 'Overdue';
        } else if (next.daysUntilDue == 0) {
          dueLabel = 'Due today';
        } else if (next.daysUntilDue == 1) {
          dueLabel = 'Due tomorrow';
        } else {
          dueLabel = 'Due in ${next.daysUntilDue} days';
        }

        return GestureDetector(
          onTap: () => context.go('/recurring-transactions'),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.secondarySystemBackgroundDark
                  : AppColors.systemBackground,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                // ── Icon with count badge ────────────────────────────────────
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.calendar,
                          color: accentColor,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${bills.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                // ── Info column ──────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Upcoming Bills',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryLabel,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        next.description ?? 'Bill',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currencyFmt.format(next.amount * convFactor),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryLabel,
                            ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm + 2,
                              vertical: AppSizes.xs - 1,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text(
                              dueLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                            ),
                          ),
                          if (extraCount > 0) ...[
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              '+$extraCount more',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.secondaryLabel,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // ── Chevron ──────────────────────────────────────────────────
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: AppSizes.iconSm,
                  color: AppColors.secondaryLabel,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => GestureDetector(
        onTap: () => ref.invalidate(upcomingRecurringTransactionsProvider),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 14, color: AppColors.error),
              const SizedBox(width: AppSizes.xs),
              Text(
                'Failed to load · Tap to retry',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
