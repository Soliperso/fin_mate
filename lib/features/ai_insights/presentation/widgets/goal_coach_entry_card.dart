import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../savings_goals/domain/entities/savings_goal_entity.dart';
import '../../../savings_goals/presentation/providers/savings_goal_providers.dart';

/// Compact entry card displayed in the Insights tab that routes the user
/// to the Goal Coach. Shows a live summary of goal health.
class GoalCoachEntryCard extends ConsumerWidget {
  const GoalCoachEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return GestureDetector(
      onTap: () => context.push('/insights/goal-coach'),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Icon orb
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.scope,
                color: AppColors.brandTeal,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSizes.sm),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Goal Coach',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.brandTeal.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.brandTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  goalsAsync.when(
                    data: (goals) {
                      final active =
                          goals.where((g) => !g.isCompleted).toList();
                      if (active.isEmpty) {
                        return Text(
                          'Add a savings goal to get started',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        );
                      }
                      final atRisk = active
                          .where((g) => _needsAttention(g))
                          .length;
                      final statusText = atRisk > 0
                          ? '$atRisk goal${atRisk > 1 ? 's' : ''} need${atRisk == 1 ? 's' : ''} attention'
                          : '${active.length} active goal${active.length > 1 ? 's' : ''} — all looking good';
                      return Text(
                        statusText,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: atRisk > 0
                                      ? AppColors.systemOrange
                                      : AppColors.textSecondary,
                                  fontWeight: atRisk > 0
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                      );
                    },
                    loading: () => Text(
                      'Loading goals…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    error: (_, __) => Text(
                      'Tap to view your goals',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSizes.sm),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: AppColors.systemGray),
          ],
        ),
      ),
    );
  }

  bool _needsAttention(SavingsGoal goal) {
    if (goal.isOverdue) return true;
    if (goal.deadline == null) return false;
    final daysLeft = goal.daysRemaining ?? 0;
    if (daysLeft == 0) return true;
    final totalDays =
        goal.deadline!.difference(goal.createdAt).inDays.clamp(1, 9999);
    final idealProgress = 1.0 - (daysLeft / totalDays);
    final actualProgress = goal.progress / 100;
    return actualProgress < idealProgress - 0.10;
  }
}
