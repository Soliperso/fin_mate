import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class SpendingBreakdownCard extends ConsumerStatefulWidget {
  const SpendingBreakdownCard({super.key});

  @override
  ConsumerState<SpendingBreakdownCard> createState() =>
      _SpendingBreakdownCardState();
}

class _SpendingBreakdownCardState extends ConsumerState<SpendingBreakdownCard> {
  bool _expanded = false;

  static const _categoryColors = [
    AppColors.primaryTeal,
    AppColors.tealDark,
    AppColors.systemGreen,
    AppColors.systemOrange,
    AppColors.systemRed,
  ];

  @override
  Widget build(BuildContext context) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider('expense'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return breakdownAsync.maybeWhen(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();

        final sorted = [...data]
          ..sort(
              (a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
        final top = sorted.take(5).toList();
        final total = top.fold<double>(
          0,
          (sum, item) => sum + (item['amount'] as num).toDouble(),
        );

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.secondarySystemBackgroundDark
                : AppColors.systemBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            boxShadow: AppColors.cardShadow(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spending by Category',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          Text(
                            'This month',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          AnimatedRotation(
                            turns: _expanded ? 0.0 : -0.25,
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              CupertinoIcons.chevron_down,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Collapsed mini-summary (color dots + top category) ──────
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, 0, AppSizes.md, AppSizes.sm,
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < top.length; i++) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _categoryColors[i % _categoryColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < top.length - 1) const SizedBox(width: 4),
                      ],
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        '${top.length} categories',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),

              // ── Expanded category rows ───────────────────────────────────
              AnimatedCrossFade(
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, 0, AppSizes.md, AppSizes.md,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < top.length; i++) ...[
                        _CategoryRow(
                          name: top[i]['category'] as String,
                          amount: (top[i]['amount'] as num).toDouble(),
                          total: total,
                          color: _categoryColors[i % _categoryColors.length],
                          isDark: isDark,
                        ),
                        if (i < top.length - 1)
                          const SizedBox(height: AppSizes.sm),
                      ],
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 220),
              ),

              // ── Total row ────────────────────────────────────────────────
              Divider(
                height: 0,
                thickness: 0.5,
                indent: AppSizes.md,
                endIndent: AppSizes.md,
                color: isDark ? AppColors.separatorDark : AppColors.separator,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total expenses',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryLabel,
                          ),
                    ),
                    Text(
                      ref.watch(currencyFormat2Provider)
                          .format(total),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.systemRed,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── Category row ─────────────────────────────────────────────────────────────

class _CategoryRow extends ConsumerWidget {
  final String name;
  final double amount;
  final double total;
  final Color color;
  final bool isDark;

  const _CategoryRow({
    required this.name,
    required this.amount,
    required this.total,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fraction = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final pct = (fraction * 100).toStringAsFixed(0);
    final currencyFormat =
        ref.watch(currencyFormat0Provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Color dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Category name
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Percentage badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                '$pct%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            // Amount
            Text(
              currencyFormat.format(amount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Animated progress bar
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: isDark
                  ? AppColors.separatorDark
                  : color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
