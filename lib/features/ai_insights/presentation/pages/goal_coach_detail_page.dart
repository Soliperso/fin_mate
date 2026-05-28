import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/ai_query_limit_provider.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../widgets/query_limit_banner.dart';
import '../../../savings_goals/domain/entities/savings_goal_entity.dart';
import '../../../savings_goals/presentation/providers/savings_goal_providers.dart';
import '../providers/chat_provider.dart';
import '../../../ai_insights/domain/entities/chat_message.dart';
import 'goal_coach_page.dart' show GoalCoachStatus, coachStatus, progressColor;

/// AI Goal Coach — per-goal detail screen.
/// Shows AI health analysis, projection chart, what-if simulator, and a
/// goal-focused chat powered by the existing ChatNotifier / QueryProcessor.
class GoalCoachDetailPage extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const GoalCoachDetailPage({super.key, required this.goal});

  @override
  ConsumerState<GoalCoachDetailPage> createState() =>
      _GoalCoachDetailPageState();
}

class _GoalCoachDetailPageState extends ConsumerState<GoalCoachDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late double _boostAmount; // extra monthly contribution (what-if slider)
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  bool _isSendingCheck = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final needed = widget.goal.monthlySavingsNeeded ?? 100;
    _boostAmount = (needed * 0.2).clamp(10, 500).roundToDouble();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (_isSendingCheck || text.trim().isEmpty) return;
    setState(() => _isSendingCheck = true);

    final canMakeQuery = await ref.read(canMakeQueryProvider.future);

    if (!mounted) return;
    setState(() => _isSendingCheck = false);

    if (!canMakeQuery) {
      if (mounted) context.push('/paywall');
      return;
    }

    try {
      await ref.read(aiQueryOperationsProvider).incrementQueryCount();
    } catch (e) {
      debugPrint('Failed to increment query count: $e');
    }

    _chatController.clear();
    final contextualPrompt =
        'Regarding my "${widget.goal.name}" savings goal: $text';
    ref.read(chatProvider.notifier).sendMessage(contextualPrompt, goalId: widget.goal.id);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for live goal updates (e.g. new contribution added elsewhere)
    final liveGoalAsync =
        ref.watch(goalProvider(widget.goal.id));
    final goal = liveGoalAsync.valueOrNull ?? widget.goal;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt = ref.watch(currencyFormat2Provider);
    final status = coachStatus(goal);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          goal.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done',
                style: TextStyle(
                    color: AppColors.brandTeal, fontWeight: FontWeight.w600)),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.brandTeal,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.brandTeal,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.chart_bar_alt_fill, size: 18), text: 'Coaching'),
            Tab(icon: Icon(CupertinoIcons.chat_bubble_text, size: 18), text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildCoachingTab(goal, status, isDark, fmt),
          _buildChatTab(goal, isDark),
        ],
      ),
    );
  }

  // ── Coaching tab ────────────────────────────────────────────────────────────

  Widget _buildCoachingTab(
    SavingsGoal goal,
    GoalCoachStatus status,
    bool isDark,
    dynamic fmt,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HealthCard(goal: goal, status: status, fmt: fmt, isDark: isDark),
          const SizedBox(height: AppSizes.md),
          _ProjectionSection(goal: goal, boostAmount: _boostAmount, fmt: fmt, isDark: isDark),
          const SizedBox(height: AppSizes.md),
          _WhatIfSimulator(
            goal: goal,
            boostAmount: _boostAmount,
            fmt: fmt,
            isDark: isDark,
            onBoostChanged: (v) => setState(() => _boostAmount = v),
          ),
          const SizedBox(height: AppSizes.md),
          _CoachingTipsList(goal: goal, status: status, isDark: isDark),
          const SizedBox(height: AppSizes.md),
          _QuickChatButton(
            onTap: () => _tabs.animateTo(1),
            goalName: goal.name,
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  // ── Chat tab ────────────────────────────────────────────────────────────────

  Widget _buildChatTab(SavingsGoal goal, bool isDark) {
    final chatAsync = ref.watch(chatProvider);
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final chips = [
      'Am I on track to hit my goal?',
      'How can I save faster?',
      'What if I add \$50 more a month?',
      'When will I reach my goal?',
    ];

    return chatAsync.when(
      data: (messages) {
        final goalMessages = messages
            .where((m) => m.metadata?['goalId'] == goal.id)
            .toList();

        return Column(
          children: [
            const QueryLimitBanner(),
            // Context banner
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.sm),
              color: AppColors.brandTeal.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.sparkles,
                      size: 13, color: AppColors.brandTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chatting about "${goal.name}"',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Quick chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md, vertical: 6),
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemCount: chips.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendMessage(chips[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: cardColor,
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(chips[i],
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.brandTeal)),
                  ),
                ),
              ),
            ),

            // Messages
            Expanded(
              child: goalMessages.isEmpty
                  ? _ChatEmptyState(goalName: goal.name)
                  : ListView.builder(
                      controller: _chatScroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                      itemCount: goalMessages.length,
                      itemBuilder: (_, i) {
                        final msg = goalMessages[i];
                        final isUser = msg.sender == MessageSender.user;

                        final avatar = Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUser
                                  ? [AppColors.brandTeal, AppColors.tealDark]
                                  : [AppColors.brandTeal, AppColors.tealLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandTeal.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isUser
                                ? CupertinoIcons.person_fill
                                : CupertinoIcons.sparkles,
                            size: 16,
                            color: Colors.white,
                          ),
                        );

                        final bubble = Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.brandTeal : cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(isUser ? 14 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 14),
                            ),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                  ),
                          ),
                          child: Text(
                            msg.content,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: isUser
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: AppSizes.sm, right: AppSizes.xs),
                                  child: avatar,
                                ),
                              ],
                              bubble,
                              if (isUser) ...[
                                const SizedBox(width: AppSizes.sm),
                                avatar,
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.md),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: InputDecoration(
                        hintText: 'Ask about this goal…',
                        hintStyle: const TextStyle(
                            color: AppColors.systemGray, fontSize: 13),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.secondarySystemBackgroundDark
                            : AppColors.systemGray6,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  GestureDetector(
                    onTap: () => _sendMessage(_chatController.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.secondarySystemBackgroundDark
                            : AppColors.systemGray6,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(CupertinoIcons.paperplane_fill,
                          color: AppColors.brandTeal, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Chat unavailable')),
    );
  }
}

// ── Health card ───────────────────────────────────────────────────────────────

class _HealthCard extends ConsumerWidget {
  final SavingsGoal goal;
  final GoalCoachStatus status;
  final dynamic fmt;
  final bool isDark;

  const _HealthCard({
    required this.goal,
    required this.status,
    required this.fmt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = progressColor(status);
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final needed = goal.monthlySavingsNeeded;
    final daysLeft = goal.daysRemaining;

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
                  size: 13, color: AppColors.brandTeal),
              const SizedBox(width: 6),
              Text(
                'AI HEALTH ANALYSIS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.brandTeal,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Progress ring + stats
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: goal.progress / 100,
                    color: accentColor,
                  ),
                  child: Center(
                    child: Text(
                      '${goal.progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatRow(
                      label: 'Saved so far',
                      value: fmt.format(goal.currentAmount),
                      valueColor: accentColor,
                    ),
                    const SizedBox(height: 6),
                    _StatRow(
                      label: 'Still needed',
                      value: fmt.format(goal.remainingAmount),
                    ),
                    if (needed != null) ...[
                      const SizedBox(height: 6),
                      _StatRow(
                        label: 'Required/month',
                        value: fmt.format(needed),
                        valueColor: needed > 500
                            ? AppColors.systemOrange
                            : null,
                      ),
                    ],
                    if (daysLeft != null) ...[
                      const SizedBox(height: 6),
                      _StatRow(
                        label: 'Days remaining',
                        value: '$daysLeft',
                        valueColor: daysLeft < 30 ? AppColors.systemRed : null,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                )),
        Text(value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                )),
      ],
    );
  }
}

// ── Projection section ────────────────────────────────────────────────────────

class _ProjectionSection extends StatelessWidget {
  final SavingsGoal goal;
  final double boostAmount;
  final dynamic fmt;
  final bool isDark;

  const _ProjectionSection({
    required this.goal,
    required this.boostAmount,
    required this.fmt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    final needed = goal.monthlySavingsNeeded ?? 0;
    final baseMonths = needed > 0
        ? (goal.remainingAmount / needed)
        : null;
    final boostedMonths = (needed + boostAmount) > 0
        ? (goal.remainingAmount / (needed + boostAmount))
        : baseMonths;

    final savedMonths =
        (baseMonths != null && boostedMonths != null && baseMonths > 0)
            ? (baseMonths - boostedMonths).clamp(0.0, baseMonths).toDouble()
            : 0.0;

    return SizedBox(
      width: double.infinity,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMPLETION FORECAST',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.textSecondary,
                  ),
            ),
          const SizedBox(height: AppSizes.md),
          // Mini bar chart: current pace vs boosted
          _ProjectionBars(
            baseMonths: baseMonths,
            boostedMonths: boostedMonths,
            savedMonths: savedMonths,
            isDark: isDark,
          ),
          if (baseMonths != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _ProjectionChip(
                  label: 'At current pace',
                  value:
                      '${baseMonths.ceil()} month${baseMonths.ceil() != 1 ? 's' : ''}',
                  color: AppColors.systemGray,
                ),
                const SizedBox(width: AppSizes.sm),
                if (boostedMonths != null)
                  _ProjectionChip(
                    label: 'With +${fmt.format(boostAmount)}/mo',
                    value:
                        '${boostedMonths.ceil()} month${boostedMonths.ceil() != 1 ? 's' : ''}',
                    color: AppColors.brandTeal,
                  ),
              ],
            ),
            if (savedMonths > 0.5) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(CupertinoIcons.bolt_fill,
                      size: 13, color: AppColors.systemGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Save ${savedMonths.toStringAsFixed(1)} month${savedMonths >= 1.5 ? 's' : ''} by boosting contributions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.systemGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Add a deadline to see your completion forecast.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _ProjectionBars extends StatelessWidget {
  final double? baseMonths;
  final double? boostedMonths;
  final double savedMonths;
  final bool isDark;

  const _ProjectionBars({
    required this.baseMonths,
    required this.boostedMonths,
    required this.savedMonths,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (baseMonths == null) return const SizedBox.shrink();
    final max = baseMonths!.clamp(1, 60).toDouble();
    final boostedFraction =
        boostedMonths != null ? (boostedMonths! / max).clamp(0.1, 1.0) : 1.0;

    return Column(
      children: [
        _Bar(
          label: 'Current pace',
          fraction: 1.0,
          color: isDark ? AppColors.systemGray.withValues(alpha: 0.4) : AppColors.systemGray5,
        ),
        const SizedBox(height: 6),
        _Bar(
          label: 'With boost',
          fraction: boostedFraction,
          color: AppColors.brandTeal,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double fraction;
  final Color color;

  const _Bar({
    required this.label,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                height: 8,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectionChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProjectionChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── What-if simulator ─────────────────────────────────────────────────────────

class _WhatIfSimulator extends StatelessWidget {
  final SavingsGoal goal;
  final double boostAmount;
  final dynamic fmt;
  final bool isDark;
  final ValueChanged<double> onBoostChanged;

  const _WhatIfSimulator({
    required this.goal,
    required this.boostAmount,
    required this.fmt,
    required this.isDark,
    required this.onBoostChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                'WHAT-IF SIMULATOR',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '+${fmt.format(boostAmount)}/mo',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Drag to see how a monthly boost changes your timeline.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          Slider(
            value: boostAmount,
            min: 10,
            max: 500,
            divisions: 49,
            activeColor: AppColors.brandTeal,
            inactiveColor: AppColors.brandTeal.withValues(alpha: 0.2),
            label: '+${fmt.format(boostAmount)}',
            onChanged: onBoostChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('+\$10', style: TextStyle(fontSize: 10, color: AppColors.systemGray)),
              Text('+\$500', style: TextStyle(fontSize: 10, color: AppColors.systemGray)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Coaching tips list ────────────────────────────────────────────────────────

class _CoachingTipsList extends StatelessWidget {
  final SavingsGoal goal;
  final GoalCoachStatus status;
  final bool isDark;

  const _CoachingTipsList({
    required this.goal,
    required this.status,
    required this.isDark,
  });

  List<_TipData> _tips() {
    final needed = goal.monthlySavingsNeeded ?? 0;
    final daysLeft = goal.daysRemaining ?? 0;

    return switch (status) {
      GoalCoachStatus.ahead => [
          _TipData(
              icon: CupertinoIcons.bolt_fill,
              color: AppColors.systemGreen,
              title: 'Maintain your momentum',
              body:
                  'You\'re ahead of pace. Don\'t let a rough month erase your lead — protect your contributions first.'),
          _TipData(
              icon: CupertinoIcons.arrow_up_right_circle,
              color: AppColors.brandTeal,
              title: 'Consider raising your target',
              body:
                  'You\'re exceeding this goal. Think about whether a higher target amount better matches your ambition.'),
          _TipData(
              icon: CupertinoIcons.arrow_2_circlepath,
              color: AppColors.systemGreen,
              title: 'Automate to lock in gains',
              body:
                  'Set up a recurring transaction for this goal so contributions happen automatically each pay period.'),
        ],
      GoalCoachStatus.atRisk || GoalCoachStatus.overdue => [
          _TipData(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              color: AppColors.systemOrange,
              title: 'Increase your monthly contribution',
              body: needed > 0
                  ? 'You need \$${needed.toStringAsFixed(0)}/mo to hit your deadline. Even \$${(needed * 0.5).toStringAsFixed(0)} extra helps narrow the gap.'
                  : 'Any extra contribution this month will help you catch up.'),
          _TipData(
              icon: CupertinoIcons.scissors,
              color: AppColors.systemOrange,
              title: 'Find a budget to trim',
              body:
                  'Your dining budget is running hot this month. Redirecting 20% of that overage could add \$40–\$60 to this goal.'),
          _TipData(
              icon: CupertinoIcons.calendar_badge_plus,
              color: AppColors.systemGray,
              title: 'Extend the deadline',
              body: daysLeft > 0
                  ? 'Extending by 2–3 months lowers the required monthly amount to a more achievable level.'
                  : 'Set a new target date to get back on track with a realistic plan.'),
        ],
      GoalCoachStatus.noDeadline => [
          _TipData(
              icon: CupertinoIcons.calendar,
              color: AppColors.brandTeal,
              title: 'Set a deadline',
              body:
                  'Goals with deadlines are 3× more likely to be completed. Tap "Edit goal" to add a target date.'),
          _TipData(
              icon: CupertinoIcons.arrow_2_circlepath,
              color: AppColors.brandTeal,
              title: 'Add a recurring contribution',
              body:
                  'Set up a monthly recurring transfer so savings happen automatically — even small amounts compound over time.'),
        ],
      _ => [
          _TipData(
              icon: CupertinoIcons.checkmark_circle_fill,
              color: AppColors.brandTeal,
              title: 'Stay consistent',
              body:
                  'Consistent monthly contributions — however small — outperform irregular lump-sum deposits over time.'),
          _TipData(
              icon: CupertinoIcons.arrow_up_right_circle,
              color: AppColors.brandTeal,
              title: 'Boost with windfalls',
              body:
                  'Next time you get a bonus, tax refund, or Uber surge payout, route a portion here. It\'ll compound nicely.'),
          _TipData(
              icon: CupertinoIcons.shield_fill,
              color: AppColors.brandTeal,
              title: 'Protect your progress',
              body:
                  'Avoid dipping into this goal for non-emergencies — momentum lost is hard to rebuild.'),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'COACH\'S PLAYBOOK',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.md),
          ..._tips().asMap().entries.map((e) {
            final tip = e.value;
            final isLast = e.key == _tips().length - 1;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: tip.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(tip.icon, color: tip.color, size: 16),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(tip.body,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: AppSizes.sm),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TipData {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _TipData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

// ── Quick chat CTA ────────────────────────────────────────────────────────────

class _QuickChatButton extends StatelessWidget {
  final VoidCallback onTap;
  final String goalName;

  const _QuickChatButton({required this.onTap, required this.goalName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.brandTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border: Border.all(
              color: AppColors.brandTeal.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                  color: AppColors.brandTeal, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.chat_bubble_text,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ask your AI coach',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandTeal,
                        fontSize: 14),
                  ),
                  Text(
                    'Get personalised advice for "$goalName"',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.brandTeal),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                color: AppColors.brandTeal, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Chat empty state ──────────────────────────────────────────────────────────

class _ChatEmptyState extends StatelessWidget {
  final String goalName;

  const _ChatEmptyState({required this.goalName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.chat_bubble_text,
                  size: 26, color: AppColors.brandTeal),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Ask me anything about\n"$goalName"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 7;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress.clamp(0, 1) * 2 * math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
