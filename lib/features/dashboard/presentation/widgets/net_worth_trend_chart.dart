import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/glass_container.dart';

class NetWorthTrendChart extends ConsumerWidget {
  final List<NetWorthSnapshot> snapshots;

  const NetWorthTrendChart({
    super.key,
    required this.snapshots,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (snapshots.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormat = ref.watch(currencyFormatCompactProvider);
    final isGrowth = _isOverallGrowth();

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      border: Border.all(color: Colors.transparent, width: 0),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Worth Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              _buildTrendIndicator(context, isGrowth),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.textTertiary.withValues(alpha: 0.06),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: _calculateInterval(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          currencyFormat.format(value),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < snapshots.length) {
                          final snapshot = snapshots[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSizes.sm),
                            child: Text(
                              DateFormat('MMM d').format(snapshot.date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (snapshots.length - 1).toDouble(),
                minY: _calculateMinY(),
                maxY: _calculateMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: snapshots
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value.netWorth,
                            ))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: isGrowth ? AppColors.primaryTeal : AppColors.error,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          isGrowth
                              ? AppColors.primaryTeal.withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.2),
                          isGrowth
                              ? AppColors.primaryTeal.withValues(alpha: 0.0)
                              : AppColors.error.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < snapshots.length) {
                          final snapshot = snapshots[index];
                          final format = ref.watch(currencyFormat0Provider);
                          final dateFormat = DateFormat('MMM d, y');
                          return LineTooltipItem(
                            '${dateFormat.format(snapshot.date)}\n${format.format(snapshot.netWorth)}',
                            TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, bool isGrowth) {
    final percentage = _calculateGrowthPercentage();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: isGrowth
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGrowth ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right,
            color: isGrowth ? AppColors.success : AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${isGrowth ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isGrowth ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  bool _isOverallGrowth() {
    if (snapshots.length < 2) return true;
    return snapshots.last.netWorth >= snapshots.first.netWorth;
  }

  double _calculateGrowthPercentage() {
    if (snapshots.length < 2) return 0;
    final first = snapshots.first.netWorth;
    final last = snapshots.last.netWorth;
    if (first == 0) return last > 0 ? 100 : 0;
    return ((last - first) / first) * 100;
  }

  double _calculateMinY() {
    if (snapshots.isEmpty) return 0;
    double minValue = snapshots.first.netWorth;
    for (final snapshot in snapshots) {
      if (snapshot.netWorth < minValue) minValue = snapshot.netWorth;
    }
    // Add 10% padding below
    return minValue * 0.9;
  }

  double _calculateMaxY() {
    if (snapshots.isEmpty) return 0;
    double maxValue = snapshots.first.netWorth;
    for (final snapshot in snapshots) {
      if (snapshot.netWorth > maxValue) maxValue = snapshot.netWorth;
    }
    // Add 10% padding above
    return maxValue * 1.1;
  }

  double _calculateInterval() {
    final range = _calculateMaxY() - _calculateMinY();
    // Aim for about 4-5 grid lines
    final rawInterval = range / 4;
    // Round to nice numbers
    if (rawInterval < 100) return 100;
    if (rawInterval < 500) return 500;
    if (rawInterval < 1000) return 1000;
    if (rawInterval < 5000) return 5000;
    return (rawInterval / 1000).ceil() * 1000;
  }
}

/// Data model for net worth snapshot
class NetWorthSnapshot {
  final DateTime date;
  final double netWorth;

  const NetWorthSnapshot({
    required this.date,
    required this.netWorth,
  });
}
