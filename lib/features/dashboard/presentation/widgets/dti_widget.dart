import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../debt_payoff/presentation/providers/debt_providers.dart';
import '../providers/dashboard_providers.dart';

class DtiWidget extends ConsumerWidget {
  const DtiWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(debtSummaryProvider);
    final dashboardAsync = ref.watch(dashboardNotifierProvider);

    // Only render when both loaded and DTI is meaningful
    final summary = summaryAsync.valueOrNull;
    final dashboard = dashboardAsync.valueOrNull;

    if (summary == null || dashboard == null) return const SizedBox.shrink();

    final totalMinPayment = (summary['total_min_payment'] as num?)?.toDouble() ?? 0.0;
    final monthlyIncome = dashboard.monthlyIncome;

    if (totalMinPayment <= 0 || monthlyIncome <= 0) return const SizedBox.shrink();

    final dti = totalMinPayment / monthlyIncome * 100;

    Color dtiColor;
    String dtiLabel;
    if (dti < 36) {
      dtiColor = AppColors.success;
      dtiLabel = 'Healthy';
    } else if (dti < 50) {
      dtiColor = AppColors.warning;
      dtiLabel = 'Moderate';
    } else {
      dtiColor = AppColors.error;
      dtiLabel = 'High';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.go('/debt'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              width: AppSizes.iconContainer,
              height: AppSizes.iconContainer,
              decoration: BoxDecoration(
                color: dtiColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(CupertinoIcons.creditcard, color: dtiColor, size: AppSizes.iconSm),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debt-to-Income Ratio',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryLabel,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dti.toStringAsFixed(1)}% — $dtiLabel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: dtiColor,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: AppColors.systemGray3),
          ],
        ),
      ),
    );
  }
}
