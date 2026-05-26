import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../../../savings_goals/domain/entities/savings_goal_entity.dart';
import '../../../savings_goals/presentation/providers/savings_goal_providers.dart';
import 'goal_coach_detail_page.dart';

/// AI Goal Coach — entry screen.
/// Shows all savings goals enriched with AI coaching status and a brief tip.
class GoalCoachPage extends ConsumerWidget {
  const GoalCoachPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.scope,
                size: 15,
                color: AppColors.brandTeal,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              'Goal Coach',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: AppSizes.xs + 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                'AI',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus, size: 22),
            onPressed: () => context.push('/goals'),
            tooltip: 'Add goal',
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          final active = goals.where((g) => !g.isCompleted).toList();
          final completed = goals.where((g) => g.isCompleted).toList();

          if (goals.isEmpty) {
            return _EmptyState(onAddGoal: () => context.push('/goals'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(savingsGoalsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.xl),
              children: [
                _CoachSummaryBanner(goals: active, isDark: isDark),
                const SizedBox(height: AppSizes.md),
                if (active.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'ACTIVE GOALS',
                    count: active.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  ...active.map((g) => _GoalCoachCard(
                        goal: g,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GoalCoachDetailPage(goal: g),
                          ),
                        ),
                      )),
                ],
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.md),
                  _SectionHeader(
                    label: 'COMPLETED',
                    count: completed.length,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  ...completed.map((g) => _GoalCoachCard(
                        goal: g,
                        isDark: isDark,
                        onTap: null,
                      )),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 44, color: AppColors.systemOrange),
              const SizedBox(height: AppSizes.sm),
              const Text('Could not load goals'),
              const SizedBox(height: AppSizes.sm),
              TextButton(
                onPressed: () => ref.invalidate(savingsGoalsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Coach summary banner ─────────────────────────────────────────────────────

class _CoachSummaryBanner extends ConsumerWidget {
  final List<SavingsGoal> goals;
  final bool isDark;

  const _CoachSummaryBanner({required this.goals, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goals.isEmpty) return const SizedBox.shrink();

    final onTrack = goals.where((g) => coachStatus(g) == GoalCoachStatus.onTrack).length;
    final atRisk = goals.where((g) => coachStatus(g) == GoalCoachStatus.atRisk).length;
    final ahead = goals.where((g) => coachStatus(g) == GoalCoachStatus.ahead).length;
    final overdue = goals.where((g) => coachStatus(g) == GoalCoachStatus.overdue).length;

    String headline;
    Color headlineColor;
    if (overdue > 0) {
      headline = '$overdue goal${overdue > 1 ? 's' : ''} overdue — let\'s catch up.';
      headlineColor = AppColors.systemRed;
    } else if (atRisk > 0) {
      headline = '$atRisk goal${atRisk > 1 ? 's' : ''} at risk — small boosts help.';
      headlineColor = AppColors.systemOrange;
    } else if (ahead > 0) {
      headline = 'Great pace — $ahead goal${ahead > 1 ? 's' : ''} ahead of schedule!';
      headlineColor = AppColors.systemGreen;
    } else {
      headline = 'All $onTrack goal${onTrack > 1 ? 's' : ''} on track. Keep it up!';
      headlineColor = AppColors.brandTeal;
    }

    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.sparkles,
                  color: AppColors.brandTeal, size: 14),
              const SizedBox(width: 6),
              Text(
                'AI COACHING SUMMARY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: headlineColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusPill(count: onTrack, label: 'On Track', color: AppColors.brandTeal),
              const SizedBox(width: 8),
              _StatusPill(count: atRisk, label: 'At Risk', color: AppColors.systemOrange),
              const SizedBox(width: 8),
              _StatusPill(count: ahead, label: 'Ahead', color: AppColors.systemGreen),
              if (overdue > 0) ...[
                const SizedBox(width: 8),
                _StatusPill(count: overdue, label: 'Overdue', color: AppColors.systemRed),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatusPill({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool isDark;

  const _SectionHeader(
      {required this.label, required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark
                    ? AppColors.secondaryLabelDark
                    : AppColors.textSecondary,
              ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.systemGray5,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.secondaryLabelDark : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Goal coach card ───────────────────────────────────────────────────────────

class _GoalCoachCard extends ConsumerWidget {
  final SavingsGoal goal;
  final bool isDark;
  final VoidCallback? onTap;

  const _GoalCoachCard({
    required this.goal,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(currencyFormat2Provider);
    final status = goal.isCompleted ? GoalCoachStatus.completed : coachStatus(goal);
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: icon + name + status badge
            Row(
              children: [
                _GoalIcon(goal: goal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _CoachStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: goal.progress / 100,
                minHeight: 5,
                backgroundColor: isDark
                    ? AppColors.systemGray.withValues(alpha: 0.2)
                    : AppColors.systemGray5,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor(status)),
              ),
            ),
            const SizedBox(height: 6),

            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${fmt.format(goal.currentAmount)} saved',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.textSecondary,
                      ),
                ),
                Text(
                  '${goal.progress.toStringAsFixed(0)}% of ${fmt.format(goal.targetAmount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.textSecondary,
                      ),
                ),
              ],
            ),

            // AI tip
            if (!goal.isCompleted) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm + 2, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.sparkles,
                        size: 12, color: AppColors.brandTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _coachTip(goal, status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.brandTeal,
                              height: 1.4,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Deadline + tap affordance
            if (onTap != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (goal.daysRemaining != null) ...[
                    const Icon(CupertinoIcons.calendar,
                        size: 12, color: AppColors.systemGray),
                    const SizedBox(width: 4),
                    Text(
                      _deadlineLabel(goal),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.systemGray,
                          ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'View coaching',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Icon(CupertinoIcons.chevron_right,
                      size: 12, color: AppColors.brandTeal),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Goal icon ─────────────────────────────────────────────────────────────────

class _GoalIcon extends StatelessWidget {
  final SavingsGoal goal;

  const _GoalIcon({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color = goal.color != null
        ? Color(int.tryParse('FF${goal.color!.replaceAll('#', '')}', radix: 16) ??
            0xFF20808D)
        : AppColors.brandTeal;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: goal.icon != null
            ? Text(goal.icon!, style: const TextStyle(fontSize: 18))
            : Icon(CupertinoIcons.flag_fill, color: color, size: 18),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _CoachStatusBadge extends StatelessWidget {
  final GoalCoachStatus status;

  const _CoachStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GoalCoachStatus.ahead => ('Ahead', AppColors.systemGreen),
      GoalCoachStatus.onTrack => ('On Track', AppColors.brandTeal),
      GoalCoachStatus.atRisk => ('At Risk', AppColors.systemOrange),
      GoalCoachStatus.overdue => ('Overdue', AppColors.systemRed),
      GoalCoachStatus.completed => ('Done', AppColors.systemGreen),
      GoalCoachStatus.noDeadline => ('Active', AppColors.systemGray),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddGoal;

  const _EmptyState({required this.onAddGoal});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.scope,
                  size: 32, color: AppColors.brandTeal),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No savings goals yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Add a goal and your AI coach will help you build a plan to reach it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),
            FilledButton.icon(
              onPressed: onAddGoal,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
                minimumSize: const Size(200, AppSizes.buttonHeightMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
              icon: const Icon(CupertinoIcons.plus, size: 18),
              label: const Text('Add first goal'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

enum GoalCoachStatus { ahead, onTrack, atRisk, overdue, completed, noDeadline }

GoalCoachStatus coachStatus(SavingsGoal goal) {
  if (goal.isCompleted) return GoalCoachStatus.completed;
  if (goal.deadline == null) return GoalCoachStatus.noDeadline;
  if (goal.isOverdue) return GoalCoachStatus.overdue;

  final daysLeft = goal.daysRemaining ?? 0;
  if (daysLeft == 0) return GoalCoachStatus.overdue;

  final idealProgress =
      1.0 - (daysLeft / goal.deadline!.difference(goal.createdAt).inDays.clamp(1, 9999));
  final actualProgress = goal.progress / 100;

  if (actualProgress >= idealProgress + 0.10) return GoalCoachStatus.ahead;
  if (actualProgress >= idealProgress - 0.10) return GoalCoachStatus.onTrack;
  return GoalCoachStatus.atRisk;
}

Color progressColor(GoalCoachStatus status) => switch (status) {
      GoalCoachStatus.ahead => AppColors.systemGreen,
      GoalCoachStatus.onTrack => AppColors.brandTeal,
      GoalCoachStatus.atRisk => AppColors.systemOrange,
      GoalCoachStatus.overdue => AppColors.systemRed,
      GoalCoachStatus.completed => AppColors.systemGreen,
      GoalCoachStatus.noDeadline => AppColors.brandTeal,
    };

String _coachTip(SavingsGoal goal, GoalCoachStatus status) {
  final needed = goal.monthlySavingsNeeded;
  switch (status) {
    case GoalCoachStatus.ahead:
      return 'You\'re ahead of pace — keep this rhythm and you\'ll finish early.';
    case GoalCoachStatus.onTrack:
      if (needed != null) {
        return 'Stay consistent at \$${needed.toStringAsFixed(0)}/mo and you\'ll hit your goal on time.';
      }
      return 'You\'re on track — steady contributions will get you there.';
    case GoalCoachStatus.atRisk:
      if (needed != null) {
        return 'Bump contributions to \$${needed.toStringAsFixed(0)}/mo to stay on schedule.';
      }
      return 'You\'re behind pace. Try boosting monthly contributions to catch up.';
    case GoalCoachStatus.overdue:
      return 'Deadline passed — set a new target date or increase your monthly contribution.';
    case GoalCoachStatus.noDeadline:
      return 'Add a deadline and your coach will build a personalized savings plan.';
    default:
      return '';
  }
}

String _deadlineLabel(SavingsGoal goal) {
  final days = goal.daysRemaining;
  if (days == null) return '';
  if (days == 0) return 'Due today';
  if (days == 1) return '1 day left';
  if (days < 30) return '$days days left';
  final months = (days / 30).round();
  return '~$months month${months > 1 ? 's' : ''} left';
}
