import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/insights_providers.dart';

/// Hardcoded community spending benchmarks (% of monthly take-home pay).
const _kBenchmarks = <String, double>{
  'Food': 15.0,
  'Dining': 15.0,
  'Housing': 30.0,
  'Rent': 30.0,
  'Transport': 12.0,
  'Transportation': 12.0,
  'Entertainment': 5.0,
  'Shopping': 8.0,
  'Healthcare': 5.0,
  'Health': 5.0,
  'Utilities': 6.0,
  'Travel': 4.0,
  'Education': 3.0,
  'Other': 12.0,
};

double _benchmarkFor(String category) {
  final key = _kBenchmarks.keys.firstWhere(
    (k) => category.toLowerCase().contains(k.toLowerCase()),
    orElse: () => 'Other',
  );
  return _kBenchmarks[key] ?? 10.0;
}

class CommunityBenchmarkCard extends ConsumerWidget {
  const CommunityBenchmarkCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(defaultCategoryBreakdownProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark
          ? AppColors.secondarySystemBackgroundDark
          : AppColors.secondarySystemBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(
          color: isDark
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
                Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.systemPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_2_fill,
                    size: 16,
                    color: AppColors.systemPurple,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Benchmarks',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'How your spending compares (last 30 days)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            breakdownAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                'Could not load spending data.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              data: (breakdown) {
                final total = breakdown.fold<double>(
                  0,
                  (s, item) => s + ((item['total'] as num?)?.toDouble() ?? 0),
                );
                if (total == 0) {
                  return Text(
                    'Add transactions to see how your spending compares.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  );
                }
                final rows = breakdown.take(5).map((item) {
                  final cat = (item['category'] as String?) ?? 'Other';
                  final amount = (item['total'] as num?)?.toDouble() ?? 0;
                  final userPct = amount / total * 100;
                  return (
                    category: cat,
                    userPct: userPct,
                    communityPct: _benchmarkFor(cat),
                  );
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LegendDot(color: AppColors.brandTeal, label: 'You'),
                        const SizedBox(width: AppSizes.md),
                        _LegendDot(
                          color: AppColors.systemPurple.withValues(alpha: 0.45),
                          label: 'Community avg',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    for (final r in rows)
                      _BenchmarkRow(
                        category: r.category,
                        userPct: r.userPct,
                        communityPct: r.communityPct,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _BenchmarkRow extends StatelessWidget {
  final String category;
  final double userPct;
  final double communityPct;

  const _BenchmarkRow({
    required this.category,
    required this.userPct,
    required this.communityPct,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = userPct > communityPct * 1.2;
    final isUnder = userPct < communityPct * 0.8;
    final statusColor = isOver
        ? AppColors.systemOrange
        : isUnder
            ? AppColors.systemGreen
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isOver
                    ? '▲ ${userPct.toStringAsFixed(0)}%'
                    : isUnder
                        ? '▼ ${userPct.toStringAsFixed(0)}%'
                        : '${userPct.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              // Community average bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                child: LinearProgressIndicator(
                  value: (communityPct / 50).clamp(0.0, 1.0),
                  backgroundColor: AppColors.systemPurple.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.systemPurple.withValues(alpha: 0.3),
                  ),
                  minHeight: 6,
                ),
              ),
              // User bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                child: LinearProgressIndicator(
                  value: (userPct / 50).clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandTeal),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Avg: ${communityPct.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
