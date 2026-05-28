import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/balance_forecast_provider.dart';
import '../providers/insights_providers.dart';
import '../../domain/entities/balance_forecast.dart';
import '../widgets/balance_timeline_chart.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/error_retry_widget.dart';

class BalanceForecastPage extends ConsumerWidget {
  const BalanceForecastPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(activeForecastProvider);
    final insightsAsync = ref.watch(spendingInsightsProvider);
    final currencyFmt = ref.watch(currencyFormat2Provider);
    final currencyFmt0 = ref.watch(currencyFormat0Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '30-Day Forecast',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.info_circle,
              size: 22,
              color: isDark
                  ? AppColors.secondaryLabelDark
                  : AppColors.textSecondary,
            ),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balanceForecastProvider);
          ref.invalidate(multiScenarioForecastProvider);
          ref.invalidate(spendingInsightsProvider);
        },
        child: forecastAsync.when(
          data: (forecast) => _ForecastBody(
            forecast: forecast,
            insights: insightsAsync.valueOrNull ?? [],
            currencyFmt: currencyFmt,
            currencyFmt0: currencyFmt0,
            isDark: isDark,
          ),
          loading: () => _LoadingSkeleton(),
          error: (error, stack) => ErrorRetryWidget(
            title: 'Forecast unavailable',
            message: 'Unable to generate your 30-day forecast',
            onRetry: () => ref.invalidate(multiScenarioForecastProvider),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('About This Forecast'),
        content: const Text(
          'Your 30-day forecast is calculated from your current balance, '
          'scheduled recurring transactions, and your recent spending patterns. '
          'It updates each time you open this page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ── Main body ─────────────────────────────────────────────────────────────────

class _ForecastBody extends StatelessWidget {
  final BalanceForecast forecast;
  final List<Map<String, dynamic>> insights;
  final dynamic currencyFmt;
  final dynamic currencyFmt0;
  final bool isDark;

  const _ForecastBody({
    required this.forecast,
    required this.insights,
    required this.currencyFmt,
    required this.currencyFmt0,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final dailyForecasts = forecast.dailyForecasts;
    final projectedBalance =
        dailyForecasts.isNotEmpty ? dailyForecasts.last.projectedBalance : 0.0;
    final projectedSavings = forecast.safeToSpend;
    final lowPoint = dailyForecasts.isNotEmpty
        ? dailyForecasts
            .map((d) => d.projectedBalance)
            .reduce((a, b) => a < b ? a : b)
        : 0.0;
    final totalDays = dailyForecasts.length.clamp(1, 30);
    final healthyDays =
        dailyForecasts.where((d) => d.status == BalanceStatus.healthy).length;
    final confidence =
        ((healthyDays / totalDays) * 100).clamp(0, 100).round();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 2×2 metric grid ──────────────────────────────────────────
          Row(
            children: [
              _MetricCard(
                label: 'PROJECTED BALANCE',
                value: currencyFmt.format(projectedBalance),
                valueColor: projectedBalance >= 0 ? AppColors.brandTeal : AppColors.systemRed,
                isDark: isDark,
              ),
              const SizedBox(width: AppSizes.sm),
              _MetricCard(
                label: 'PROJECTED SAVINGS',
                value: projectedSavings >= 0
                    ? '+${currencyFmt.format(projectedSavings)}'
                    : currencyFmt.format(projectedSavings),
                valueColor: projectedSavings >= 0
                    ? const Color(0xFF4A9EBF)
                    : AppColors.systemRed,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              _MetricCard(
                label: 'LOW POINT',
                value: currencyFmt.format(lowPoint),
                valueColor: lowPoint > 500
                    ? AppColors.brandTeal
                    : lowPoint > 100
                        ? AppColors.systemOrange
                        : AppColors.systemRed,
                isDark: isDark,
              ),
              const SizedBox(width: AppSizes.sm),
              _MetricCard(
                label: 'CONFIDENCE',
                value: '$confidence%',
                valueColor: confidence >= 70
                    ? AppColors.brandTeal
                    : confidence >= 40
                        ? AppColors.systemOrange
                        : AppColors.systemRed,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // ── Chart ────────────────────────────────────────────────────
          Container(
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
                Text(
                  'Projected balance — next 30 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSizes.sm),
                BalanceTimelineChart(forecast: forecast),
                const SizedBox(height: AppSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      DateFormat('MMM d').format(
                          DateTime.now().add(const Duration(days: 30))),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── AI Insights ──────────────────────────────────────────────
          if (insights.isNotEmpty) ...[
            Text(
              'AI INSIGHTS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            ...insights.take(3).map((insight) {
              final message = insight['message'] as String? ?? '';
              final type = insight['type'] as String? ?? 'info';
              return _InsightRow(
                  message: message, type: type, isDark: isDark);
            }),
          ],
        ],
      ),
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isDark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Expanded(
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm + 2, vertical: AppSizes.sm + 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    fontSize: 9,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI insight row ────────────────────────────────────────────────────────────

class _InsightRow extends StatelessWidget {
  final String message;
  final String type;
  final bool isDark;

  const _InsightRow(
      {required this.message, required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final (icon, color) = switch (type) {
      'warning' => (CupertinoIcons.exclamationmark_triangle_fill, AppColors.systemOrange),
      'positive' => (CupertinoIcons.arrow_up_right_circle_fill, AppColors.systemGreen),
      _ => (CupertinoIcons.lightbulb_fill, const Color(0xFF4A9EBF)),
    };

    final bgColor = switch (type) {
      'warning' => AppColors.systemOrange.withValues(alpha: 0.08),
      'positive' => AppColors.systemGreen.withValues(alpha: 0.08),
      _ => cardColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.xs + 2),
      padding: const EdgeInsets.all(AppSizes.sm + 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: SkeletonCard(height: 72)),
              SizedBox(width: AppSizes.sm),
              Expanded(child: SkeletonCard(height: 72)),
            ],
          ),
          SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(child: SkeletonCard(height: 72)),
              SizedBox(width: AppSizes.sm),
              Expanded(child: SkeletonCard(height: 72)),
            ],
          ),
          SizedBox(height: AppSizes.md),
          SkeletonCard(height: 250),
          SizedBox(height: AppSizes.md),
          SkeletonCard(height: 120),
        ],
      ),
    );
  }
}
