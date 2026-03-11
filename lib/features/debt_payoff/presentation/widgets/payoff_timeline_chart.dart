import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/services/payoff_calculator.dart';

class PayoffTimelineChart extends StatelessWidget {
  final PayoffResult result;

  const PayoffTimelineChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final points = _buildSpots();
    if (points.isEmpty) return const SizedBox.shrink();

    final maxY = result.schedule.first.totalBalance * 1.08;
    final debtFreeLabel = DateFormat('MMM yyyy').format(result.debtFreeDate);

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payoff Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _interval(maxY),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: (isDark ? AppColors.white : AppColors.charcoal)
                        .withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: _interval(maxY),
                      getTitlesWidget: (value, _) => Text(
                        _compactCurrency(value),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        // Show label every ~6 data points
                        if (idx % 6 != 0 && idx != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final snapIdx =
                            (idx * result.schedule.length / points.length)
                                .round()
                                .clamp(0, result.schedule.length - 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM yy')
                                .format(result.schedule[snapIdx].date),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        );
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
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.error,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error.withValues(alpha: 0.18),
                          AppColors.error.withValues(alpha: 0.0),
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
                    getTooltipColor: (_) => isDark
                        ? AppColors.secondarySystemBackgroundDark
                        : AppColors.secondarySystemBackground,
                    getTooltipItems: (spots) => spots.map((s) {
                      final snapIdx =
                          (s.x * result.schedule.length / points.length)
                              .round()
                              .clamp(0, result.schedule.length - 1);
                      final snap = result.schedule[snapIdx];
                      return LineTooltipItem(
                        '${DateFormat('MMM yyyy').format(snap.date)}\n'
                        '\$${NumberFormat('#,##0').format(snap.totalBalance)}',
                        TextStyle(
                          color: isDark
                              ? AppColors.labelDark
                              : AppColors.label,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Debt-free: $debtFreeLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Downsample schedule to max 24 points for clean rendering.
  List<FlSpot> _buildSpots() {
    final total = result.schedule.length;
    if (total == 0) return [];

    final targetCount = total <= 24 ? total : 24;
    final step = total / targetCount;

    final spots = <FlSpot>[];
    for (int i = 0; i < targetCount; i++) {
      final snapIdx = (i * step).round().clamp(0, total - 1);
      spots.add(FlSpot(i.toDouble(), result.schedule[snapIdx].totalBalance));
    }
    // Always include the last point (balance = 0)
    if (spots.last.y > 0.01) {
      spots.add(FlSpot(targetCount.toDouble(), 0));
    }
    return spots;
  }

  double _interval(double maxY) {
    if (maxY <= 0) return 1000;
    final raw = maxY / 4;
    if (raw < 500) return 500;
    if (raw < 1000) return 1000;
    if (raw < 5000) return 5000;
    if (raw < 10000) return 10000;
    return (raw / 10000).ceil() * 10000.0;
  }

  String _compactCurrency(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(0)}K';
    return '\$${value.toStringAsFixed(0)}';
  }
}
