import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Donut ring chart showing debt payoff progress.
/// [progressPercent] ranges 0–100. When null, renders an empty ring.
class DebtProgressRing extends StatelessWidget {
  final double? progressPercent;
  final double size;
  final Color fillColor;
  final Color trackColor;

  const DebtProgressRing({
    super.key,
    required this.progressPercent,
    this.size = 56,
    this.fillColor = AppColors.success,
    this.trackColor = const Color(0x1A000000),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedTrack = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    final pct = (progressPercent ?? 0).clamp(0.0, 100.0);
    final remaining = 100.0 - pct;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: size * 0.34,
              sections: [
                PieChartSectionData(
                  value: pct > 0 ? pct : 0.001,
                  color: pct > 0 ? fillColor : resolvedTrack,
                  radius: size * 0.16,
                  title: '',
                  showTitle: false,
                ),
                if (remaining > 0)
                  PieChartSectionData(
                    value: remaining,
                    color: resolvedTrack,
                    radius: size * 0.16,
                    title: '',
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Text(
            progressPercent != null
                ? '${pct.toStringAsFixed(0)}%'
                : '—',
            style: TextStyle(
              fontSize: size * 0.18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
