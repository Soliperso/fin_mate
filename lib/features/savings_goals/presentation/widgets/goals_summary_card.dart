import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';

class GoalsSummaryCard extends ConsumerWidget {
  final Map<String, dynamic> summary;

  const GoalsSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalGoals = summary['total_goals'] as int? ?? 0;
    final completedGoals = summary['completed_goals'] as int? ?? 0;
    final activeGoals = summary['active_goals'] as int? ?? 0;
    final totalTarget = (summary['total_target'] as num?)?.toDouble() ?? 0.0;
    final totalSaved = (summary['total_saved'] as num?)?.toDouble() ?? 0.0;
    final overallProgress =
        (summary['overall_progress'] as num?)?.toDouble() ?? 0.0;

    final currencyFormat = ref.watch(currencyFormat2Provider);

    return GradientHeroCard(
      gradientColors: const [AppColors.brandTeal, AppColors.brandTealLight],
      shadowColor: AppColors.brandTeal.withValues(alpha: 0.35),
      shadowBlurRadius: 16,
      shadowOffset: const Offset(0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: AppSizes.iconContainer,
                height: AppSizes.iconContainer,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  CupertinoIcons.money_dollar,
                  color: AppColors.white,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  'Goals Overview',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Total / Completed badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '$completedGoals / $totalGoals done',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // Stat chips row
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Active',
                  value: activeGoals.toString(),
                  icon: CupertinoIcons.flag,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _StatChip(
                  label: 'Saved',
                  value: currencyFormat.format(totalSaved),
                  icon: CupertinoIcons.creditcard,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _StatChip(
                  label: 'Target',
                  value: currencyFormat.format(totalTarget),
                  icon: CupertinoIcons.arrow_up_right,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // Overall progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
              Text(
                '${overallProgress.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: overallProgress / 100,
              minHeight: 8,
              backgroundColor: AppColors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.white, size: AppSizes.iconSm),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
