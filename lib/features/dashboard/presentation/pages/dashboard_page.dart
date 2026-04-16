import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../core/services/notification_provider.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state_card.dart';
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
import '../widgets/upcoming_bills_card.dart';
import '../widgets/savings_rate_card.dart';
import '../widgets/spending_breakdown_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Refresh the badge count every time the dashboard is mounted so the
    // count stays accurate after reading notifications or switching tabs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).updateUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
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

    final avatarUrl = profileState.profile?.avatarUrl;
    final hasValidAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSizes.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'nav.dashboard'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              DateFormat('MMMM d, yyyy', context.locale.toString()).format(DateTime.now()),
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
              Tooltip(
                message: 'Notifications',
                child: CircularIconButton(
                  icon: unreadCount > 0
                      ? CupertinoIcons.bell_fill
                      : CupertinoIcons.bell,
                  onTap: () => context.push('/notifications'),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.systemRed,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSizes.xs),
          // Global search
          Tooltip(
            message: 'Search',
            child: CircularIconButton(
              icon: CupertinoIcons.search,
              onTap: () => context.go('/transactions?search=true'),
            ),
          ),
          const SizedBox(width: AppSizes.xs),
          // Avatar
          Tooltip(
            message: 'Profile',
            child: Padding(
              padding: const EdgeInsets.only(right: AppSizes.sm),
              child: GestureDetector(
                onTap: () => context.go('/profile'),
                child: hasValidAvatar
                    ? CircleAvatar(
                        radius: 17,
                        backgroundImage: NetworkImage(avatarUrl),
                      )
                    : CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.brandTeal,
                        child: Text(
                          getInitials(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.08,
                          ),
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
                  monthlyIncome: stats.monthlyIncome,
                  monthlyExpenses: stats.monthlyExpenses,
                ),
                const SizedBox(height: AppSizes.md),

                // ── Money health ──────────────────────────────────────────
                MoneyHealthScore(score: stats.moneyHealthScore),
                const SizedBox(height: AppSizes.md),

                // ── DTI ratio ─────────────────────────────────────────────
                const DtiWidget(),
                const SizedBox(height: AppSizes.md),

                // ── Upcoming bills ────────────────────────────────────────
                const UpcomingBillsCard(),
                const SizedBox(height: AppSizes.md),

                // ── Cash flow ─────────────────────────────────────────────
                CashFlowCard(
                  income: stats.monthlyIncome,
                  expenses: stats.monthlyExpenses,
                ),
                const SizedBox(height: AppSizes.md),

                // ── Savings rate ──────────────────────────────────────────
                SavingsRateCard(
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
                        if (flowData.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                            child: Center(
                              child: Text(
                                'dashboard.noFlowData'.tr(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          );
                        }
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
                        if (snapshots.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                            child: Center(
                              child: Text(
                                'dashboard.noWorthData'.tr(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          );
                        }
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

                // ── Spending breakdown ────────────────────────────────────
                const SpendingBreakdownCard(),
                const SizedBox(height: AppSizes.md),

                // ── Recent Transactions ───────────────────────────────────
                SectionHeader(
                  title: 'dashboard.recentTransactions'.tr(),
                  actionLabel: 'dashboard.seeAll'.tr(),
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
                  EmptyStateCard(
                    icon: CupertinoIcons.exclamationmark_circle,
                    title: 'dashboard.failedToLoad'.tr(),
                    message: 'dashboard.failedMessage'.tr(),
                    backgroundColor: AppColors.brandTeal,
                  ),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(dashboardNotifierProvider.notifier)
                            .loadDashboard();
                      },
                      icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                      label: Text('common.retry'.tr()),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmptyStateCard(
            icon: CupertinoIcons.doc_text,
            title: 'dashboard.noTransactions'.tr(),
            message: 'dashboard.noTransactionsMessage'.tr(),
            backgroundColor: AppColors.brandTeal,
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: AppSizes.buttonHeightMd,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/transactions/add?type=expense'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
              icon: const Icon(CupertinoIcons.add, size: AppSizes.iconSm),
              label: Text(
                'dashboard.addTransaction'.tr(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
                endIndent: AppSizes.md,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  final TransactionEntity transaction;
  final bool isDark;

  const _TransactionRow({required this.transaction, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;
    final amount = isIncome ? transaction.amount : -transaction.amount;
    final currencyFormat = ref.watch(currencyFormat2Provider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(
        transaction.date.year, transaction.date.month, transaction.date.day);
    final diff = today.difference(txDate).inDays;
    final dateText = diff == 0
        ? 'common.today'.tr()
        : diff == 1
            ? 'common.yesterday'.tr()
            : diff < 7
                ? 'common.daysAgo'.tr(namedArgs: {'count': '$diff'})
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
          vertical: AppSizes.sm + 4,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
                    transaction.description ?? 'dashboard.noDescription'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    transaction.categoryName ?? 'dashboard.uncategorized'.tr(),
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
