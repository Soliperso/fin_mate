import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/insights_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../savings_goals/presentation/providers/savings_goal_providers.dart';
import 'insights_tab.dart';

class AiInsightsPage extends ConsumerWidget {
  const AiInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final alertsAsync = ref.watch(typedProactiveAlertsProvider);
    final goalAlertsAsync = ref.watch(goalAlertsProvider);
    final incomeAlertsAsync = ref.watch(incomeAlertsProvider);
    final dismissedIds = ref.watch(dismissedAlertIdsProvider);
    final insightsAsync = ref.watch(spendingInsightsProvider);
    final goalsAsync = ref.watch(savingsGoalsProvider);

    final activeAlertCount =
        (alertsAsync.whenOrNull(
              data: (alerts) =>
                  alerts.where((a) => !dismissedIds.contains(a.id)).length,
            ) ?? 0) +
        (goalAlertsAsync.whenOrNull(
              data: (alerts) =>
                  alerts.where((a) => !dismissedIds.contains(a.id)).length,
            ) ?? 0) +
        (incomeAlertsAsync.whenOrNull(
              data: (alerts) =>
                  alerts.where((a) => !dismissedIds.contains(a.id)).length,
            ) ?? 0);

    final activeGoalCount = goalsAsync.whenOrNull(
          data: (goals) => goals.where((g) => !g.isCompleted).length,
        ) ??
        0;

    final latestInsight = insightsAsync.whenOrNull(
      data: (insights) =>
          insights.isNotEmpty ? insights.first['message'] as String? : null,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brandTeal, AppColors.tealLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.sparkles,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              'AI Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(typedProactiveAlertsProvider);
          ref.invalidate(goalAlertsProvider);
          ref.invalidate(incomeAlertsProvider);
          ref.invalidate(spendingInsightsProvider);
          ref.invalidate(savingsGoalsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Money Health Score card ──────────────────────────────────
              statsAsync.when(
                data: (stats) => _HealthScoreCard(
                  score: stats.moneyHealthScore,
                  isDark: isDark,
                ),
                loading: () => _HealthScoreCard(score: 0, isDark: isDark, loading: true),
                error: (_, __) => _HealthScoreCard(score: 0, isDark: isDark),
              ),
              const SizedBox(height: AppSizes.md),

              // ── 2x2 Feature grid ─────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSizes.sm,
                mainAxisSpacing: AppSizes.sm,
                childAspectRatio: 1.15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _FeatureTile(
                    icon: CupertinoIcons.chat_bubble_text_fill,
                    iconColor: AppColors.brandTeal,
                    title: 'AI Assistant',
                    subtitle: 'Ask anything about your finances',
                    onTap: () => context.push('/insights/chat'),
                    isDark: isDark,
                  ),
                  _FeatureTile(
                    icon: CupertinoIcons.graph_circle,
                    iconColor: const Color(0xFF4A9EBF),
                    title: '30-Day Forecast',
                    subtitle: 'Projected balance & cash flow',
                    onTap: () => context.push('/insights/forecast'),
                    isDark: isDark,
                  ),
                  _FeatureTile(
                    icon: CupertinoIcons.bell_fill,
                    iconColor: AppColors.systemOrange,
                    title: 'Smart Alerts',
                    subtitle: activeAlertCount > 0
                        ? '$activeAlertCount new insight${activeAlertCount == 1 ? '' : 's'}'
                        : 'No new alerts',
                    badge: activeAlertCount > 0 ? '$activeAlertCount' : null,
                    onTap: () => context.push('/insights/alerts'),
                    isDark: isDark,
                  ),
                  _FeatureTile(
                    icon: CupertinoIcons.scope,
                    iconColor: AppColors.brandTeal,
                    title: 'Goal Coach',
                    subtitle: activeGoalCount > 0
                        ? '$activeGoalCount goal${activeGoalCount == 1 ? '' : 's'} active'
                        : 'No goals yet',
                    onTap: () => context.push('/insights/goal-coach'),
                    isDark: isDark,
                  ),
                ],
              ),

              // ── Latest AI Insight ────────────────────────────────────────
              if (latestInsight != null) ...[
                const SizedBox(height: AppSizes.md),
                _LatestInsightBanner(insight: latestInsight, isDark: isDark),
              ],

              // ── Spending Insights divider ─────────────────────────────────
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      thickness: 0.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                    child: Text(
                      'SPENDING INSIGHTS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      thickness: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              // ── Embedded spending analytics (alerts, categories,
              //    recurring charges, subscriptions, price changes) ───────────
              const InsightsTab(embedded: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Health Score Card ─────────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final int score;
  final bool isDark;
  final bool loading;

  const _HealthScoreCard({
    required this.score,
    required this.isDark,
    this.loading = false,
  });

  String get _label {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good Shape';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  Color get _scoreColor {
    if (score >= 80) return AppColors.systemGreen;
    if (score >= 60) return AppColors.brandTeal;
    if (score >= 40) return AppColors.systemOrange;
    return AppColors.systemRed;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 72,
            height: 72,
            child: loading
                ? CircularProgressIndicator(
                    strokeWidth: 5,
                    color: AppColors.brandTeal.withValues(alpha: 0.3),
                  )
                : _ScoreRing(score: score, color: _scoreColor, isDark: isDark),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONEY HEALTH SCORE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : _label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: loading ? AppColors.textSecondary : _scoreColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  final bool isDark;

  const _ScoreRing({required this.score, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ringBg = isDark
        ? AppColors.tertiarySystemBackgroundDark
        : AppColors.systemGray5;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 7,
            backgroundColor: ringBg,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          '$score',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }
}

// ── Feature Tile ──────────────────────────────────────────────────────────────

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  final bool isDark;

  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.systemRed,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        badge!,
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
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.textSecondary,
                    height: 1.3,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Latest Insight Banner ─────────────────────────────────────────────────────

class _LatestInsightBanner extends StatelessWidget {
  final String insight;
  final bool isDark;

  const _LatestInsightBanner({required this.insight, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.sparkles,
                  size: 13, color: AppColors.brandTeal),
              const SizedBox(width: 6),
              Text(
                'LATEST AI INSIGHT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
          ),
        ],
      ),
    );
  }
}
