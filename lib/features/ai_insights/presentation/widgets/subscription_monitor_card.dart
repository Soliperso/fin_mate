import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/recurring_expense_pattern.dart';
import '../providers/insights_providers.dart';

class SubscriptionMonitorCard extends ConsumerWidget {
  const SubscriptionMonitorCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringExpensesProvider);
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return recurringAsync.when(
      data: (patterns) {
        final subscriptions = patterns
            .where((p) =>
                p.interval == RecurringInterval.monthly ||
                p.interval == RecurringInterval.weekly ||
                p.interval == RecurringInterval.yearly ||
                p.interval == RecurringInterval.biweekly)
            .toList()
          ..sort((a, b) => b.averageAmount.compareTo(a.averageAmount));

        if (subscriptions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Subscriptions & Bills',
              actionLabel: 'View all',
              onAction: () => context.push('/recurring-transactions'),
            ),
            const SizedBox(height: AppSizes.sm),
            _SubscriptionList(
              subscriptions: subscriptions.take(5).toList(),
              currencyFormat: currencyFormat,
              isDark: isDark,
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        );
      },
      loading: () => _SubscriptionSkeleton(isDark: isDark),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SubscriptionList extends StatelessWidget {
  final List<RecurringExpensePattern> subscriptions;
  final NumberFormat currencyFormat;
  final bool isDark;

  const _SubscriptionList({
    required this.subscriptions,
    required this.currencyFormat,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Column(
        children: subscriptions.asMap().entries.map((entry) {
          final index = entry.key;
          final pattern = entry.value;
          final isLast = index == subscriptions.length - 1;
          return _SubscriptionRow(
            pattern: pattern,
            currencyFormat: currencyFormat,
            isDark: isDark,
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  final RecurringExpensePattern pattern;
  final NumberFormat currencyFormat;
  final bool isDark;
  final bool showDivider;

  const _SubscriptionRow({
    required this.pattern,
    required this.currencyFormat,
    required this.isDark,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final initial = pattern.merchantName.isNotEmpty
        ? pattern.merchantName[0].toUpperCase()
        : '?';

    // Color based on category or position
    final avatarColor = _categoryColor(pattern.category);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
          child: Row(
            children: [
              // Merchant initial avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: avatarColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),

              // Name + interval
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.merchantName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pattern.interval.displayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Amount + price change badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(pattern.averageAmount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (pattern.isPriceIncreased &&
                      pattern.priceChangePercentage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color:
                            AppColors.systemOrange.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.arrow_up,
                            size: 10,
                            color: AppColors.systemOrange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '+${pattern.priceChangePercentage!.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.systemOrange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: AppSizes.md + 36 + AppSizes.sm,
            endIndent: AppSizes.md,
            color: isDark ? AppColors.separatorDark : AppColors.separator,
            thickness: 0.5,
          ),
      ],
    );
  }

  Color _categoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('entertainment') || lower.contains('streaming')) {
      return AppColors.systemPurple;
    }
    if (lower.contains('food') || lower.contains('dining')) {
      return AppColors.systemOrange;
    }
    if (lower.contains('health') || lower.contains('fitness')) {
      return AppColors.systemGreen;
    }
    if (lower.contains('utility') || lower.contains('bill')) {
      return AppColors.systemBlue;
    }
    if (lower.contains('software') || lower.contains('tech')) {
      return AppColors.systemIndigo;
    }
    return AppColors.brandTeal;
  }
}

class _SubscriptionSkeleton extends StatelessWidget {
  final bool isDark;
  const _SubscriptionSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Subscriptions & Bills'),

        const SizedBox(height: AppSizes.sm),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.secondarySystemBackgroundDark
                : AppColors.systemGray6,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          ),
        ),
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }
}
