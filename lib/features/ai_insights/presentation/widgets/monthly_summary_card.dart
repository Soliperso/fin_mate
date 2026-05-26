import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/insights_providers.dart';

class MonthlySummaryCard extends ConsumerWidget {
  const MonthlySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(defaultCategoryBreakdownProvider);
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return breakdownAsync.when(
      data: (categories) {
        final total = categories.fold(
          0.0,
          (sum, c) => sum + (c['total_amount'] as num? ?? 0).toDouble(),
        );
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final daysRemaining = daysInMonth - now.day + 1;
        final monthName = DateFormat('MMMM').format(now);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            boxShadow: AppColors.cardShadow(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.chart_bar_circle_fill,
                      size: 18,
                      color: AppColors.brandTeal,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$monthName Spending',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        '$daysRemaining days remaining',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(total),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatPill(
                        label: '${categories.length} categories',
                        icon: CupertinoIcons.tag_fill,
                        color: AppColors.systemPurple,
                        isDark: isDark,
                      ),
                      if (categories.isNotEmpty && total > 0) ...[
                        const SizedBox(height: AppSizes.xs),
                        _StatPill(
                          label: 'Top: ${categories.first['category_name'] as String? ?? '—'}',
                          icon: CupertinoIcons.chart_bar_fill,
                          color: AppColors.brandTeal,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _SummarySkeleton(isDark: isDark),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSizes.xs - 1),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  final bool isDark;
  const _SummarySkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      height: 90,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemGray6,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
    );
  }
}
