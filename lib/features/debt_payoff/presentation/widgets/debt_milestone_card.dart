import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Badge chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                          color: AppColors.brandTeal.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getBadgeIcon(gamification.badgeIcon),
                            size: 13,
                            color: AppColors.brandTeal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gamification.badgeTitle,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.brandTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Badge hint (months to next level)
                    if (gamification.monthsToNextBadge != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${gamification.monthsToNextBadge} mo to ',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                            ),
                            if (gamification.nextBadgeIcon.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Icon(
                                  _getBadgeIcon(gamification.nextBadgeIcon),
                                  size: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            Text(
                              gamification.nextBadgeTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            // Streak + total paid + overall progress stats
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
                    label:
                        '${currencyFormat.format(gamification.totalPaidAllTime)} paid',
                  ),
                if (gamification.overallProgressPercent != null)
                  _StatChip(
                    icon: CupertinoIcons.chart_pie_fill,
                    iconColor: AppColors.brandTeal,
                    label:
                        '${gamification.overallProgressPercent!.toStringAsFixed(0)}% paid off overall',
                  ),
              ],
            ),

            if (gamification.milestones.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.sm),
              ...gamification.milestones.map(
                (m) => _MilestoneRow(
                  milestone: m,
                  currencyFormat: currencyFormat,
                  isDark: isDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _getBadgeIcon(String iconCode) {
    return switch (iconCode) {
      'trophy' => CupertinoIcons.star_circle_fill,
      'bolt' => CupertinoIcons.bolt_fill,
      'flame' => CupertinoIcons.flame_fill,
      'rocket' => CupertinoIcons.paperplane_fill,
      'leaf' => CupertinoIcons.leaf_arrow_circlepath,
      _ => CupertinoIcons.star_fill,
    };
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
  final NumberFormat currencyFormat;
  final bool isDark;

  const _MilestoneRow({
    required this.milestone,
    required this.currencyFormat,
    required this.isDark,
  });

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
          // Name + progress label + remaining balance
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  milestone.isComplete
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              size: 13,
                              color: color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Paid Off!',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        )
                      : Text(
                          '${pct.toStringAsFixed(0)}% → next: ${milestone.nextMilestone}%',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                  if (!milestone.isComplete && milestone.currentBalance > 0)
                    Text(
                      '${currencyFormat.format(milestone.currentBalance)} left',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar with milestone tick marks
          SizedBox(
            height: 8,
            child: CustomPaint(
              painter: _GradientProgressPainter(
                progress: (pct / 100).clamp(0.0, 1.0),
                isDark: isDark,
              ),
              size: Size.infinite,
            ),
          ),
          // Motivational hint
          if (!milestone.isComplete)
            Builder(
              builder: (context) {
                final needed = milestone.amountToNextMilestone;
                if (needed == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: AppSizes.xs),
                  child: Text(
                    'Pay ${currencyFormat.format(needed)} more to reach ${milestone.nextMilestone}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _GradientProgressPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _GradientProgressPainter({required this.progress, required this.isDark});

  static const _gradientColors = [
    AppColors.systemOrange,
    AppColors.systemYellow,
    AppColors.brandTeal,
    AppColors.systemGreen,
  ];
  static const _gradientStops = [0.0, 0.33, 0.67, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 1, size.width, size.height - 2),
      radius,
    );

    // Track
    final trackPaint = Paint()
      ..color = isDark
          ? AppColors.separatorDark.withValues(alpha: 0.6)
          : AppColors.separator.withValues(alpha: 0.5);
    canvas.drawRRect(trackRect, trackPaint);

    // Gradient fill clipped to progress width
    if (progress > 0) {
      canvas.save();
      canvas.clipRRect(trackRect);
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          colors: _gradientColors,
          stops: _gradientStops,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(
        Rect.fromLTWH(0, 1, size.width * progress, size.height - 2),
        gradientPaint,
      );
      canvas.restore();
    }

    // Tick marks at 25/50/75/100%
    final tickPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.55);
    for (final tickPct in [25, 50, 75, 100]) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * (tickPct / 100) - 0.75, 0, 1.5, size.height),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GradientProgressPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
