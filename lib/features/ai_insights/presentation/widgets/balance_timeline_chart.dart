import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '30-Day Balance Forecast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              height: 200,
              child: _BalanceChart(forecast: forecast),
            ),
            const SizedBox(height: AppSizes.md),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: AppColors.success,
          label: 'Healthy',
        ),
        const SizedBox(width: AppSizes.md),
        _LegendItem(
          color: AppColors.warning,
          label: 'Warning',
        ),
        const SizedBox(width: AppSizes.md),
        _LegendItem(
          color: AppColors.error,
          label: 'Critical',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
}

class _BalanceChart extends StatelessWidget {
  final BalanceForecast forecast;

  const _BalanceChart({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final dailyForecasts = forecast.dailyForecasts;
    if (dailyForecasts.isEmpty) return const SizedBox();

    // Find min and max values for scaling
    final balances = dailyForecasts.map((f) => f.projectedBalance).toList();
    final minBalance = balances.reduce((a, b) => a < b ? a : b);
    final maxBalance = balances.reduce((a, b) => a > b ? a : b);

    // Add padding to min/max
    final range = maxBalance - minBalance;
    final paddedMin = minBalance - (range * 0.1);
    final paddedMax = maxBalance + (range * 0.1);

    return CustomPaint(
      painter: _BalanceChartPainter(
        dailyForecasts: dailyForecasts,
        minValue: paddedMin,
        maxValue: paddedMax,
      ),
      child: Container(),
    );
  }
}

class _BalanceChartPainter extends CustomPainter {
  final List<DailyForecast> dailyForecasts;
  final double minValue;
  final double maxValue;

  _BalanceChartPainter({
    required this.dailyForecasts,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyForecasts.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw grid lines
    _drawGridLines(canvas, size);

    // Guard against division by zero
    final lengthDivisor = dailyForecasts.length > 1 ? dailyForecasts.length - 1 : 1;
    final valueDivisor = (maxValue - minValue).abs() > 0.01 ? (maxValue - minValue) : 1.0;

    // Draw balance line
    final path = Path();
    for (int i = 0; i < dailyForecasts.length; i++) {
      final forecast = dailyForecasts[i];
      final x = (i / lengthDivisor) * size.width;
      final normalizedY = (forecast.projectedBalance - minValue) / valueDivisor;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw gradient path
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryTeal.withValues(alpha: 0.3),
          AppColors.primaryTeal.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, gradientPaint);

    // Draw line
    paint.color = AppColors.primaryTeal;
    canvas.drawPath(path, paint);

    // Draw data points with color based on status
    for (int i = 0; i < dailyForecasts.length; i += 3) {
      // Show every 3rd point to avoid clutter
      final forecast = dailyForecasts[i];
      final x = (i / lengthDivisor) * size.width;
      final normalizedY = (forecast.projectedBalance - minValue) / valueDivisor;
      final y = size.height - (normalizedY * size.height);

      final pointColor = _getStatusColor(forecast.status);

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = pointColor
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Draw labels
    _drawLabels(canvas, size);
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Draw Y-axis labels (balance values)
    for (int i = 0; i <= 4; i++) {
      final value = minValue + ((maxValue - minValue) * (4 - i) / 4);
      final y = (i / 4) * size.height;

      textPainter.text = TextSpan(
        text: currencyFormat.format(value),
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width - 5, y - textPainter.height / 2),
      );
    }

    // Draw X-axis labels (dates)
    final dateFormat = DateFormat('MMM d');
    final labelIndices = [0, dailyForecasts.length ~/ 2, dailyForecasts.length - 1];

    for (final i in labelIndices) {
      if (i >= dailyForecasts.length) continue;

      final forecast = dailyForecasts[i];
      final x = (i / (dailyForecasts.length - 1)) * size.width;

      textPainter.text = TextSpan(
        text: dateFormat.format(forecast.date),
        style: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 10,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 5),
      );
    }
  }

  Color _getStatusColor(BalanceStatus status) {
    switch (status) {
      case BalanceStatus.healthy:
        return AppColors.success;
      case BalanceStatus.warning:
        return AppColors.warning;
      case BalanceStatus.critical:
        return AppColors.error;
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter oldDelegate) {
    return dailyForecasts != oldDelegate.dailyForecasts ||
        minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue;
  }
}
