import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../domain/entities/balance_forecast.dart';

class BalanceTimelineChart extends StatelessWidget {
  final BalanceForecast forecast;

  const BalanceTimelineChart({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    if (forecast.dailyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFormat = NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0);
    final hasCritical = forecast.dailyForecasts.any((f) => f.status == BalanceStatus.critical);
    final lineColor = hasCritical ? AppColors.error : AppColors.primaryTeal;

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
                '30-Day Balance Forecast',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              _buildStatusBadge(context, hasCritical),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              _buildLegendItem(context, color: AppColors.success, label: 'Healthy'),
              const SizedBox(width: AppSizes.md),
              _buildLegendItem(context, color: AppColors.warning, label: 'Warning'),
              const SizedBox(width: AppSizes.md),
              _buildLegendItem(context, color: AppColors.error, label: 'Critical'),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.textTertiary.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: _calculateInterval(),
                      getTitlesWidget: (value, meta) => Text(
                        currencyFormat.format(value),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: _xLabelInterval(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= forecast.dailyForecasts.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            DateFormat('MMM d').format(forecast.dailyForecasts[index].date),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                maxX: (forecast.dailyForecasts.length - 1).toDouble(),
                minY: _calculateMinY(),
                maxY: _calculateMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: forecast.dailyForecasts
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                              e.key.toDouble(),
                              e.value.projectedBalance,
                            ))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: lineColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          lineColor.withValues(alpha: 0.2),
                          lineColor.withValues(alpha: 0.0),
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
                        if (index < 0 || index >= forecast.dailyForecasts.length) return null;
                        final day = forecast.dailyForecasts[index];
                        final format = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
                        final dateFormat = DateFormat('MMM d');
                        return LineTooltipItem(
                          '${dateFormat.format(day.date)}\n${format.format(day.projectedBalance)}',
                          const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
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

  Widget _buildStatusBadge(BuildContext context, bool hasCritical) {
    final hasWarning = forecast.dailyForecasts.any((f) => f.status == BalanceStatus.warning);
    final color = hasCritical
        ? AppColors.error
        : hasWarning
            ? AppColors.warning
            : AppColors.success;
    final label = hasCritical ? 'Critical' : hasWarning ? 'Warning' : 'On Track';
    final icon = hasCritical
        ? Icons.trending_down
        : hasWarning
            ? Icons.warning_amber_rounded
            : Icons.trending_up;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, {required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  double _calculateMinY() {
    final balances = forecast.dailyForecasts.map((f) => f.projectedBalance);
    final min = balances.reduce((a, b) => a < b ? a : b);
    return (min * 0.9).floorToDouble();
  }

  double _calculateMaxY() {
    final balances = forecast.dailyForecasts.map((f) => f.projectedBalance);
    final max = balances.reduce((a, b) => a > b ? a : b);
    return (max * 1.1).ceilToDouble();
  }

  double _calculateInterval() {
    final range = _calculateMaxY() - _calculateMinY();
    final raw = range / 4;
    if (raw < 100) return 100;
    if (raw < 500) return 500;
    if (raw < 1000) return 1000;
    if (raw < 5000) return 5000;
    return (raw / 1000).ceil() * 1000.0;
  }

  double _xLabelInterval() {
    final count = forecast.dailyForecasts.length;
    if (count <= 7) return 1;
    if (count <= 14) return 3;
    return 7;
  }
}
