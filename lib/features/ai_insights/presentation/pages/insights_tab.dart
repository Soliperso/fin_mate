import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../providers/insights_providers.dart';
import '../widgets/goal_coach_entry_card.dart';
import '../widgets/monthly_summary_card.dart';
import '../../domain/entities/recurring_expense_pattern.dart';
import '../../domain/entities/spending_anomaly.dart';
import '../../domain/entities/proactive_alert.dart';

class InsightsTab extends ConsumerStatefulWidget {
  /// When [embedded] is true the widget returns a bare Column (no scroll
  /// wrapper, no RefreshIndicator) so it can be placed inside a parent
  /// scrollable such as [AiInsightsPage]. The GoalCoachEntryCard is also
  /// omitted in embedded mode because the hub already shows the feature grid.
  final bool embedded;

  const InsightsTab({super.key, this.embedded = false});

  @override
  ConsumerState<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends ConsumerState<InsightsTab> {
  // Index-based color palette for category breakdown
  static const _categoryPalette = [
    AppColors.systemBlue,
    AppColors.systemPurple,
    AppColors.systemOrange,
    AppColors.systemGreen,
    AppColors.systemIndigo,
  ];

  @override
  Widget build(BuildContext context) {
    final categoryBreakdownAsync = ref.watch(defaultCategoryBreakdownProvider);
    final recurringExpensesAsync = ref.watch(recurringExpensesProvider);
    final spendingAnomaliesAsync = ref.watch(spendingAnomaliesProvider);
    final alertsAsync = ref.watch(typedProactiveAlertsProvider);
    final dismissedIds = ref.watch(dismissedAlertIdsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded) ...[
          // ── 0. Monthly Summary ───────────────────────────────────────
          const MonthlySummaryCard(),
          const SizedBox(height: AppSizes.md),

          // ── Goal Coach entry ─────────────────────────────────────────
          const GoalCoachEntryCard(),
          const SizedBox(height: AppSizes.md),
        ],

            // ── 1. Proactive Alerts ──────────────────────────────────────
            alertsAsync.whenOrNull(
                  data: (alerts) {
                    final active = alerts
                        .where((a) => !dismissedIds.contains(a.id))
                        .toList();
                    if (active.isEmpty) return null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALERTS',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        ...active.map((a) => _buildAlertCard(a)),
                        const SizedBox(height: AppSizes.lg),
                      ],
                    );
                  },
                ) ??
                const SizedBox.shrink(),

            // ── 2. Spending by Category ──────────────────────────────────
            Text(
              'SPENDING BY CATEGORY',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            categoryBreakdownAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return EmptyStateCard(
                    icon: CupertinoIcons.chart_pie_fill,
                    title: 'No Spending Data',
                    message:
                        'Add some expenses to see your category breakdown.',
                    backgroundColor: AppColors.primaryTeal,
                  );
                }
                final total = categories.fold(
                  0.0,
                  (sum, c) => sum + (c['total_amount'] as double),
                );
                return _buildCategoryCard(categories, cardColor, total);
              },
              loading: () => const SkeletonCard(height: 280),
              error: (_, __) => ErrorRetryWidget(
                title: 'Failed to load categories',
                message: 'Unable to load spending breakdown',
                onRetry: () => ref.invalidate(defaultCategoryBreakdownProvider),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ── 3. Unusual Spending ──────────────────────────────────────
            Text(
              'UNUSUAL SPENDING',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            spendingAnomaliesAsync.when(
              data: (anomalies) => anomalies.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm + 4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusCard),
                        boxShadow: AppColors.cardShadow(isDark),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.checkmark_shield_fill,
                            color: AppColors.systemGreen,
                            size: 18,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'No unusual spending detected',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            color: AppColors.systemGreen,
                            size: 16,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: anomalies
                          .take(3)
                          .map((a) => _buildAnomalyCard(a, cardColor))
                          .toList(),
                    ),
              loading: () => const SkeletonCard(height: 180),
              error: (_, __) => ErrorRetryWidget(
                title: 'Failed to detect anomalies',
                message: 'Unable to analyze spending patterns',
                onRetry: () => ref.invalidate(spendingAnomaliesProvider),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ── 4. Recurring Charges ─────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECURRING CHARGES',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/recurring-transactions'),
                      child: Row(
                        children: [
                          Text(
                            'SEE ALL',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.brandTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            color: AppColors.brandTeal,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                recurringExpensesAsync.when(
                  data: (patterns) => patterns.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md, vertical: AppSizes.sm + 4),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusCard),
                            boxShadow: AppColors.cardShadow(isDark),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.repeat,
                                color: AppColors.systemPurple,
                                size: 18,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Text(
                                  'No recurring charges detected yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/recurring-transactions'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.brandTeal,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Add one'),
                              ),
                            ],
                          ),
                        )
                      : _buildRecurringChargesCard(patterns, cardColor),
                  loading: () => const SkeletonCard(height: 80),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSizes.lg),
              ],
            ),

            // ── 5. Recurring Price Changes ───────────────────────────────
            recurringExpensesAsync.when(
              data: (patterns) {
                final priceChanges =
                    patterns.where((p) => p.isPriceIncreased).toList();
                if (priceChanges.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRICE CHANGES',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    ...priceChanges
                        .map((p) => _buildPriceChangeCard(p, cardColor)),
                    const SizedBox(height: AppSizes.lg),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
    );

    if (widget.embedded) return content;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(typedProactiveAlertsProvider);
        ref.invalidate(defaultCategoryBreakdownProvider);
        ref.invalidate(recurringExpensesProvider);
        ref.invalidate(spendingAnomaliesProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: content,
      ),
    );
  }

  // ── Alert card ─────────────────────────────────────────────────────────────

  Widget _buildAlertCard(ProactiveAlert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final Color severity;
    switch (alert.severity) {
      case AlertSeverity.critical:
        severity = AppColors.error;
        break;
      case AlertSeverity.high:
        severity = AppColors.warning;
        break;
      default:
        severity = AppColors.primaryTeal;
    }

    final String severityLabel;
    switch (alert.severity) {
      case AlertSeverity.critical:
        severityLabel = 'Critical';
        break;
      case AlertSeverity.high:
        severityLabel = 'High';
        break;
      case AlertSeverity.medium:
        severityLabel = 'Medium';
        break;
      default:
        severityLabel = 'Low';
    }

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref
          .read(dismissedAlertIdsProvider.notifier)
          .dismiss(alert.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.md),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        child: const Icon(CupertinoIcons.xmark, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: AppColors.cardShadow(isDark),
          border: Border(left: BorderSide(color: severity, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.lightbulb_fill, color: severity, size: 20),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: severity.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            severityLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: severity,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      alert.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category card ──────────────────────────────────────────────────────────

  Widget _buildCategoryCard(
    List<Map<String, dynamic>> categories,
    Color cardColor,
    double total,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = ref.watch(currencyFormat2Provider);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Column(
        children: categories.take(5).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final category = entry.value;
          final accentColor = _categoryPalette[i % _categoryPalette.length];
          final amount = category['total_amount'] as double;
          final pct = total > 0 ? amount / total : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Row(
              children: [
                // Colored rank dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category['category_name'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}% · ${currencyFormat.format(amount)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.systemGray4.withValues(alpha: 0.15)
                                : AppColors.systemGray4.withValues(alpha: 0.35),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Anomaly card ───────────────────────────────────────────────────────────

  Widget _buildAnomalyCard(SpendingAnomaly anomaly, Color cardColor) {
    final Color severity;
    switch (anomaly.severity) {
      case AnomalySeverity.critical:
        severity = AppColors.error;
        break;
      case AnomalySeverity.high:
        severity = AppColors.warning;
        break;
      case AnomalySeverity.medium:
        severity = AppColors.warning.withValues(alpha: 0.7);
        break;
      default:
        severity = AppColors.primaryTeal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: severity.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: severity,
                  size: AppSizes.iconSm,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anomaly.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      anomaly.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (anomaly.deviationPercentage != null) ...[
                const SizedBox(width: AppSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: severity.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    '+${anomaly.deviationPercentage!.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: severity,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(CupertinoIcons.list_bullet, size: 13),
                  label: const Text('View Transactions'),
                  onPressed: () => context.go('/transactions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    minimumSize: const Size(0, 36),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(CupertinoIcons.bell, size: 13),
                  label: const Text('Set Budget Alert'),
                  onPressed: () => context.go('/budgets'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 9),
                    minimumSize: const Size(0, 36),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Price change card ──────────────────────────────────────────────────────

  Widget _buildPriceChangeCard(
    RecurringExpensePattern pattern,
    Color cardColor,
  ) {
    final currencyFormat = ref.watch(currencyFormat2Provider);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              CupertinoIcons.arrow_up_right,
              color: AppColors.warning,
              size: AppSizes.iconSm,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern.merchantName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '${pattern.interval.displayName} · ${currencyFormat.format(pattern.averageAmount)}'
                  '  (+${pattern.priceChangePercentage?.toStringAsFixed(1) ?? '?'}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (pattern.nextExpectedDate != null) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Next: ${DateFormat('MMM d, yyyy').format(pattern.nextExpectedDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _showUpdateAmountDialog(pattern),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ── Recurring charges card ─────────────────────────────────────────────────

  double _toMonthlyAmount(RecurringExpensePattern p) {
    switch (p.interval) {
      case RecurringInterval.weekly:
        return p.averageAmount * 52 / 12;
      case RecurringInterval.biweekly:
        return p.averageAmount * 26 / 12;
      case RecurringInterval.monthly:
        return p.averageAmount;
      case RecurringInterval.quarterly:
        return p.averageAmount / 3;
      case RecurringInterval.yearly:
        return p.averageAmount / 12;
      case RecurringInterval.unknown:
        return p.averageAmount;
    }
  }

  Widget _buildRecurringChargesCard(
    List<RecurringExpensePattern> patterns,
    Color cardColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final monthlyTotal =
        patterns.fold(0.0, (sum, p) => sum + _toMonthlyAmount(p));

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Monthly total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              Text(
                currencyFormat.format(monthlyTotal),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(height: AppSizes.md + 4, thickness: 0.5),
          ...patterns.take(5).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.systemPurple.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.repeat,
                          color: AppColors.systemPurple,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.merchantName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              p.interval.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormat.format(p.averageAmount),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _showUpdateAmountDialog(RecurringExpensePattern pattern) {
    final controller =
        TextEditingController(text: pattern.averageAmount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${pattern.merchantName} Amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'New amount',
            prefixText: '\$',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newAmount = double.tryParse(controller.text);
              if (newAmount != null && newAmount > 0) {
                try {
                  final userId = supabase.auth.currentUser?.id;
                  if (userId != null) {
                    await supabase
                        .from('recurring_transactions')
                        .update({'amount': newAmount})
                        .eq('description', pattern.merchantName)
                        .eq('user_id', userId);
                    ref.invalidate(recurringExpensesProvider);
                  }
                } catch (e) {
                  debugPrint(
                    '[InsightsTab] Failed to update recurring transaction: $e',
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
