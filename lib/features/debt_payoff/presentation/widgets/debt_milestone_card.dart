import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/debt_providers.dart';

class DebtMilestoneCard extends ConsumerWidget {
  const DebtMilestoneCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(debtGamificationProvider);
    if (gamification == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = ref.watch(currencyFormat0Provider);

    return Card(
      elevation: 0,
      color: isDark
          ? AppColors.secondarySystemBackgroundDark
          : AppColors.secondarySystemBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        side: BorderSide(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  decoration: BoxDecoration(
                    color: AppColors.systemYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(
                    CupertinoIcons.star_fill,
                    size: 16,
                    color: AppColors.systemYellow,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'Your Progress',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: AppColors.brandTeal.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${gamification.badgeIcon} ${gamification.badgeTitle}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            // Streak + total paid stats
            Wrap(
              spacing: AppSizes.md,
              runSpacing: AppSizes.xs,
              children: [
                _StatChip(
                  icon: CupertinoIcons.flame_fill,
                  iconColor: AppColors.systemOrange,
                  label: gamification.streakMonths == 0
                      ? 'No streak yet'
                      : '${gamification.streakMonths} month streak',
                ),
                if (gamification.totalPaidAllTime > 0)
                  _StatChip(
                    icon: CupertinoIcons.checkmark_circle_fill,
                    iconColor: AppColors.systemGreen,
                    label: '${currencyFormat.format(gamification.totalPaidAllTime)} paid',
                  ),
              ],
            ),

            if (gamification.milestones.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.sm),
              ...gamification.milestones.map((m) => _MilestoneRow(milestone: m)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final DebtMilestone milestone;

  const _MilestoneRow({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final pct = milestone.progressPercent;
    final color = milestone.isComplete
        ? AppColors.systemGreen
        : pct >= 50
            ? AppColors.brandTeal
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  milestone.debtName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                milestone.isComplete
                    ? '✓ Paid Off!'
                    : '${pct.toStringAsFixed(0)}% → next: ${milestone.nextMilestone}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
