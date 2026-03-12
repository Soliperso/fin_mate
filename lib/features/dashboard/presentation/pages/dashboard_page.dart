import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/ads/ad_banner_widget.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/net_worth_card.dart';
import '../widgets/cash_flow_card.dart';
import '../widgets/cash_flow_chart.dart';
import '../widgets/net_worth_trend_chart.dart';
import '../widgets/money_health_score.dart';
import '../widgets/dti_widget.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final profileState = ref.watch(currentUserProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String getInitials() {
      if (user?.fullName == null || user?.fullName?.isEmpty == true) return 'U';
      final names = user!.fullName!.trim().split(' ');
      if (names.length == 1) return names[0][0].toUpperCase();
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSizes.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              DateFormat('MMMM d, yyyy').format(DateTime.now()),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.systemGray,
                  ),
            ),
          ],
        ),
        actions: [
          // Notification bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  unreadCount > 0
                      ? CupertinoIcons.bell_fill
                      : CupertinoIcons.bell,
                  size: 22,
                ),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.systemRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Avatar
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: profileState.profile?.avatarUrl != null &&
                      profileState.profile!.avatarUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 17,
                      backgroundImage:
                          NetworkImage(profileState.profile!.avatarUrl!),
                    )
                  : CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.brandTeal,
                      child: Text(
                        getInitials(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: -0.08,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: dashboardState.when(
        data: (stats) => RefreshIndicator(
          color: AppColors.brandTeal,
          onRefresh: () async {
            await ref.read(dashboardNotifierProvider.notifier).refresh();
            ref.invalidate(monthlyFlowDataProvider);
            ref.invalidate(netWorthSnapshotsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
              vertical: AppSizes.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero card ─────────────────────────────────────────────
                NetWorthCard(
                  netWorth: stats.netWorth,
                  changePercentage: stats.netWorthChangePercentage,
                  isPositive: stats.isNetWorthPositive,
                ),
                const SizedBox(height: AppSizes.md),

                // ── Money health ──────────────────────────────────────────
                MoneyHealthScore(score: stats.moneyHealthScore),
                const SizedBox(height: AppSizes.md),

                // ── DTI ratio ─────────────────────────────────────────────
                const DtiWidget(),
                const SizedBox(height: AppSizes.md),

                // ── Cash flow ─────────────────────────────────────────────
                CashFlowCard(
                  income: stats.monthlyIncome,
                  expenses: stats.monthlyExpenses,
                ),
                const SizedBox(height: AppSizes.md),

                // ── Charts ────────────────────────────────────────────────
                Consumer(
                  builder: (context, ref, _) {
                    final flowDataAsync = ref.watch(monthlyFlowDataProvider);
                    return flowDataAsync.when(
                      data: (flowData) {
                        if (flowData.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            CashFlowChart(flowData: flowData),
                            const SizedBox(height: AppSizes.md),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    );
                  },
                ),

                Consumer(
                  builder: (context, ref, _) {
                    final snapshotsAsync = ref.watch(netWorthSnapshotsProvider);
                    return snapshotsAsync.when(
                      data: (snapshots) {
                        if (snapshots.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            NetWorthTrendChart(snapshots: snapshots),
                            const SizedBox(height: AppSizes.md),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    );
                  },
                ),

                // ── Recent Transactions ───────────────────────────────────
                _SectionHeader(
                  title: 'Recent Transactions',
                  action: 'See All',
                  onAction: () => context.go('/transactions'),
                ),
                const SizedBox(height: AppSizes.xs),
                _RecentTransactionsCard(
                  transactions: stats.recentTransactions,
                  isDark: isDark,
                ),

                // Ad banner
                const SizedBox(height: AppSizes.md),
                const AdBannerWidget(),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        ),
        loading: () => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            children: [
              const SkeletonCard(height: 160),
              const SizedBox(height: AppSizes.md),
              const SkeletonCard(height: 100),
              const SizedBox(height: AppSizes.md),
              const SkeletonCard(height: 140),
              const SizedBox(height: AppSizes.md),
              const SkeletonChart(height: 200),
            ],
          ),
        ),
        error: (error, stack) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardNotifierProvider.notifier).refresh();
            ref.invalidate(monthlyFlowDataProvider);
            ref.invalidate(netWorthSnapshotsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmptyState(
                    icon: Icons.error_outline,
                    title: 'Failed to load dashboard',
                    message:
                        'Unable to fetch your financial data. Please check your connection and try again.',
                  ),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(dashboardNotifierProvider.notifier)
                            .loadDashboard();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.brandTeal,
                letterSpacing: -0.24,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Recent transactions card ──────────────────────────────────────────────────

class _RecentTransactionsCard extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final bool isDark;

  const _RecentTransactionsCard({
    required this.transactions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    if (transactions.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    size: 40,
                    color: AppColors.systemGray3,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'No recent transactions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.systemGray,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/transactions/add?type=expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
              icon: const Icon(CupertinoIcons.add, size: 20),
              label: const Text(
                'Add Transaction',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < transactions.length; i++) ...[
            _TransactionRow(
              transaction: transactions[i],
              isDark: isDark,
            ),
            if (i < transactions.length - 1)
              Divider(
                height: 0,
                thickness: 0.5,
                indent: 60,
                color: isDark ? AppColors.separatorDark : AppColors.separator,
              ),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionEntity transaction;
  final bool isDark;

  const _TransactionRow({required this.transaction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amount = isIncome ? transaction.amount : -transaction.amount;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(
        transaction.date.year, transaction.date.month, transaction.date.day);
    final diff = today.difference(txDate).inDays;
    final dateText = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Yesterday'
            : diff < 7
                ? '$diff days ago'
                : DateFormat('MMM d').format(transaction.date);

    final iconData = _iconForTransaction(transaction);
    final iconColor = isIncome ? AppColors.systemGreen : AppColors.systemRed;
    final iconBg = iconColor.withValues(alpha: 0.12);

    return InkWell(
      onTap: () => context.go(
          '/transactions/add?type=${transaction.type.name}&id=${transaction.id}'),
      child: Padding(
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
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSizes.sm + 4),
            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? 'No description',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.categoryName ?? 'Uncategorized',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${amount >= 0 ? '+' : ''}${currencyFormat.format(amount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: amount >= 0
                            ? AppColors.systemGreen
                            : AppColors.systemRed,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForTransaction(TransactionEntity tx) {
    final cat = tx.categoryName?.toLowerCase() ?? '';
    if (tx.type == TransactionType.income) {
      if (cat.contains('salary')) return CupertinoIcons.briefcase;
      if (cat.contains('freelance')) return CupertinoIcons.desktopcomputer;
      if (cat.contains('investment')) return CupertinoIcons.graph_circle;
      if (cat.contains('gift')) return CupertinoIcons.gift;
      return CupertinoIcons.money_dollar_circle;
    }
    if (cat.contains('food') || cat.contains('dining')) return CupertinoIcons.cart;
    if (cat.contains('transport')) return CupertinoIcons.car;
    if (cat.contains('shopping')) return CupertinoIcons.bag;
    if (cat.contains('entertainment')) return CupertinoIcons.film;
    if (cat.contains('bills') || cat.contains('utilities')) return CupertinoIcons.doc_text;
    if (cat.contains('health')) return CupertinoIcons.heart;
    if (cat.contains('education')) return CupertinoIcons.book;
    if (cat.contains('housing')) return CupertinoIcons.house;
    return CupertinoIcons.creditcard;
  }
}
