import 'package:easy_localization/easy_localization.dart';
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
    final label = _hasNoData ? 'moneyHealth.noDataYet'.tr() : _getScoreLabel(score);
    final subtitle = _hasNoData
        ? 'moneyHealth.addTransactionsMsg'.tr()
        : 'moneyHealth.basedOnMsg'.tr();
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
                  'moneyHealth.title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm + 2, vertical: AppSizes.xs - 1),
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
                const SizedBox(height: AppSizes.xs + 2),
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
    if (score >= 80) return 'moneyHealth.excellent'.tr();
    if (score >= 60) return 'moneyHealth.good'.tr();
    if (score >= 40) return 'moneyHealth.fair'.tr();
    return 'moneyHealth.needsImprovement'.tr();
  }
}
