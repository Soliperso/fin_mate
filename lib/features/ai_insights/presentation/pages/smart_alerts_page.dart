import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/insights_providers.dart';
import '../../domain/entities/proactive_alert.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../debt_payoff/presentation/providers/debt_providers.dart';

// Filter categories for the chips row
enum _AlertFilter { all, spending, budget, debt, forecast }

class SmartAlertsPage extends ConsumerStatefulWidget {
  const SmartAlertsPage({super.key});

  @override
  ConsumerState<SmartAlertsPage> createState() => _SmartAlertsPageState();
}

class _SmartAlertsPageState extends ConsumerState<SmartAlertsPage> {
  _AlertFilter _selected = _AlertFilter.all;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(typedProactiveAlertsProvider);
    final dismissedIds = ref.watch(dismissedAlertIdsProvider);
    final budgetsAsync = ref.watch(budgetsWithSpendingProvider);
    final debtGamificationAsync = ref.watch(debtGamificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build combined alert list
    final proactiveAlerts = alertsAsync.valueOrNull ?? [];
    final activeAlerts = proactiveAlerts
        .where((a) => !dismissedIds.contains(a.id))
        .toList();

    final List<_AlertItem> allAlerts = [];

    // Map proactive alerts
    for (final a in activeAlerts) {
      _AlertSeverityLevel severity;
      _AlertFilter category;
      switch (a.severity) {
        case AlertSeverity.critical:
        case AlertSeverity.high:
          severity = _AlertSeverityLevel.urgent;
        case AlertSeverity.medium:
          severity = _AlertSeverityLevel.review;
        case AlertSeverity.low:
          severity = _AlertSeverityLevel.headsUp;
      }
      switch (a.type) {
        case AlertType.unusualSpending:
          category = _AlertFilter.spending;
        case AlertType.cashFlowWarning:
        case AlertType.lowBalance:
        case AlertType.billCollision:
          category = _AlertFilter.forecast;
        default:
          category = _AlertFilter.spending;
      }
      allAlerts.add(_AlertItem(
        id: a.id,
        title: a.title,
        description: a.message,
        severity: severity,
        category: category,
        createdAt: a.createdAt,
        isRead: a.isRead,
      ));
    }

    // Budget overage alerts
    budgetsAsync.whenOrNull(data: (budgets) {
      for (final b in budgets) {
        if (b.isExceeded) {
          final categoryName = b.categoryName ?? 'Budget';
          allAlerts.add(_AlertItem(
            id: 'budget_${b.id}',
            title: '$categoryName budget exceeded',
            description:
                'You\'ve spent ${b.spentPercentage.toStringAsFixed(0)}% of your \$${b.amount.toStringAsFixed(0)} ${categoryName.toLowerCase()} budget this month.',
            severity: _AlertSeverityLevel.urgent,
            category: _AlertFilter.budget,
            createdAt: DateTime.now(),
            isRead: false,
          ));
        } else if (b.isNearLimit) {
          final categoryName = b.categoryName ?? 'Budget';
          allAlerts.add(_AlertItem(
            id: 'budget_near_${b.id}',
            title: '$categoryName budget at ${b.spentPercentage.toStringAsFixed(0)}%',
            description:
                'You\'ve spent \$${(b.spent ?? 0).toStringAsFixed(0)} of your \$${b.amount.toStringAsFixed(0)} ${categoryName.toLowerCase()} budget.',
            severity: _AlertSeverityLevel.review,
            category: _AlertFilter.budget,
            createdAt: DateTime.now(),
            isRead: true,
          ));
        }
      }
    });

    // Debt milestone wins (debtGamificationProvider is a sync Provider<DebtGamification?>)
    final gam = debtGamificationAsync;
    if (gam != null && gam.milestones.isNotEmpty) {
      for (final m in gam.milestones.take(1)) {
        allAlerts.add(_AlertItem(
          id: 'debt_milestone_${m.progressPercent.toInt()}',
          title: 'Debt payoff milestone',
          description:
              'You\'re ${m.progressPercent.toStringAsFixed(0)}% through your debt payoff plan. Keep up the great work!',
          severity: _AlertSeverityLevel.win,
          category: _AlertFilter.debt,
          createdAt: DateTime.now(),
          isRead: true,
        ));
      }
    }

    // Sort: unread first, then by severity
    allAlerts.sort((a, b) {
      if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
      return a.severity.index.compareTo(b.severity.index);
    });

    final filtered = _selected == _AlertFilter.all
        ? allAlerts
        : allAlerts.where((a) => a.category == _selected).toList();

    final newCount = allAlerts.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Smart Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (newCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '$newCount new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(typedProactiveAlertsProvider);
          ref.invalidate(budgetsWithSpendingProvider);
          ref.invalidate(debtGamificationProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Filter chips
            SliverToBoxAdapter(
              child: _FilterChipsRow(
                selected: _selected,
                onSelected: (f) => setState(() => _selected = f),
                isDark: isDark,
              ),
            ),

            // Alerts list
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  filter: _selected,
                  isDark: isDark,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _AlertCard(
                      item: filtered[index],
                      isDark: isDark,
                      onDismiss: () => ref
                          .read(dismissedAlertIdsProvider.notifier)
                          .update((s) => {...s, filtered[index].id}),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chips row ──────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  final _AlertFilter selected;
  final ValueChanged<_AlertFilter> onSelected;
  final bool isDark;

  const _FilterChipsRow({
    required this.selected,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_AlertFilter.all, 'All'),
      (_AlertFilter.spending, 'Spending'),
      (_AlertFilter.budget, 'Budget'),
      (_AlertFilter.debt, 'Debt'),
      (_AlertFilter.forecast, 'Forecast'),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 6),
        children: filters.map((f) {
          final (filter, label) = f;
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandTeal
                      : (isDark
                          ? AppColors.secondarySystemBackgroundDark
                          : AppColors.systemBackground),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandTeal
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final _AlertItem item;
  final bool isDark;
  final VoidCallback? onDismiss;

  const _AlertCard({
    required this.item,
    required this.isDark,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final (borderColor, badgeColor, badgeText) = switch (item.severity) {
      _AlertSeverityLevel.urgent => (
          AppColors.systemRed,
          AppColors.systemRed,
          'Urgent',
        ),
      _AlertSeverityLevel.review => (
          AppColors.systemOrange,
          AppColors.systemOrange,
          'Review',
        ),
      _AlertSeverityLevel.headsUp => (
          AppColors.systemOrange,
          AppColors.systemOrange,
          'Heads up',
        ),
      _AlertSeverityLevel.win => (
          AppColors.systemGreen,
          AppColors.systemGreen,
          'Win',
        ),
    };

    final timeLabel = _timeAgo(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusCard),
                  bottomLeft: Radius.circular(AppSizes.radiusCard),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.clock,
                            size: 11, color: AppColors.systemGray),
                        const SizedBox(width: 3),
                        Text(
                          timeLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.systemGray,
                              ),
                        ),
                        if (onDismiss != null &&
                            item.category != _AlertFilter.budget &&
                            item.category != _AlertFilter.debt) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: onDismiss,
                            child: Text(
                              'Dismiss',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return 'This month';
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _AlertFilter filter;
  final bool isDark;

  const _EmptyState({required this.filter, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.systemGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.checkmark_circle,
                  size: 30, color: AppColors.systemGreen),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              filter == _AlertFilter.all
                  ? 'All clear!'
                  : 'No ${filter.name} alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Nothing to review right now.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

enum _AlertSeverityLevel { urgent, review, headsUp, win }

class _AlertItem {
  final String id;
  final String title;
  final String description;
  final _AlertSeverityLevel severity;
  final _AlertFilter category;
  final DateTime createdAt;
  final bool isRead;

  const _AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.createdAt,
    required this.isRead,
  });
}
