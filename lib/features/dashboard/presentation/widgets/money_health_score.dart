import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class MoneyHealthScore extends StatelessWidget {
  final int score;

  const MoneyHealthScore({
    super.key,
    required this.score,
  });

  bool get _hasNoData => score == 0;

  @override
  Widget build(BuildContext context) {
    final color = _hasNoData ? AppColors.systemGray : _getScoreColor(score);
    final label = _hasNoData ? 'No Data Yet' : _getScoreLabel(score);
    final subtitle = _hasNoData
        ? 'Add income & expense transactions to get your score'
        : 'Based on your spending & savings (last 30 days)';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    final ringBg = isDark
        ? AppColors.tertiarySystemBackgroundDark
        : AppColors.systemGray5;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: _hasNoData ? 0.0 : score / 100,
                    strokeWidth: 7,
                    backgroundColor: ringBg,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  _hasNoData ? '—' : '$score',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Money Health Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.systemGreen;
    if (score >= 60) return AppColors.systemOrange;
    return AppColors.systemRed;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Improvement';
  }
}
