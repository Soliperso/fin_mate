import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../domain/entities/balance_forecast.dart';

class BalanceTimelineChart extends ConsumerWidget {
  final BalanceForecast forecast;

  const BalanceTimelineChart({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (forecast.dailyForecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final currencyFmt = ref.watch(currencyFormat2Provider);

    final balances = forecast.dailyForecasts.map((f) => f.projectedBalance).toList();
    final minBalance = balances.reduce((a, b) => a < b ? a : b);
    final lowPointIndex = balances.indexOf(minBalance);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          clipData: const FlClipData.all(),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (forecast.dailyForecasts.length - 1).toDouble(),
          minY: _calculateMinY(),
          maxY: _calculateMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: forecast.dailyForecasts.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.projectedBalance);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              color: const Color(0xFF4ECB71),
              barWidth: 2.0,
              isStrokeCapRound: false,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (index == lowPointIndex) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: Colors.amber,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4ECB71).withValues(alpha: 0.25),
                    const Color(0xFF4ECB71).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: minBalance < 0
                ? [
                    HorizontalLine(
                      y: 0,
                      color: Colors.white.withValues(alpha: 0.25),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ]
                : [],
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= forecast.dailyForecasts.length) return null;
                  final day = forecast.dailyForecasts[idx];
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(day.date)}\n${currencyFmt.format(day.projectedBalance)}',
                    const TextStyle(
                      color: Colors.white,
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
    );
  }

  double _calculateMinY() {
    final balances = forecast.dailyForecasts.map((f) => f.projectedBalance).toList();
    final min = balances.reduce((a, b) => a < b ? a : b);
    final max = balances.reduce((a, b) => a > b ? a : b);
    if (min == max) return min - 100;
    return (min * (min >= 0 ? 0.85 : 1.15)).floorToDouble();
  }

  double _calculateMaxY() {
    final balances = forecast.dailyForecasts.map((f) => f.projectedBalance).toList();
    final min = balances.reduce((a, b) => a < b ? a : b);
    final max = balances.reduce((a, b) => a > b ? a : b);
    if (min == max) return max + 100;
    return (max * (max >= 0 ? 1.15 : 0.85)).ceilToDouble();
  }
}
