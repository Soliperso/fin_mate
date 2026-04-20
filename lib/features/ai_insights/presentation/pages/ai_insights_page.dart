import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/ai_query_limit_provider.dart';
import '../../../../core/providers/display_format_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/balance_forecast_provider.dart';
import '../providers/insights_providers.dart';
import '../../domain/entities/balance_forecast.dart';
import '../../domain/entities/chat_message.dart';
import '../widgets/enhanced_chat_message_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/suggested_prompts.dart';
import '../widgets/balance_timeline_chart.dart';
import '../widgets/query_limit_banner.dart';
import '../../../../shared/widgets/gradient_hero_card.dart';
import '../../../../shared/widgets/hero_stat_badge.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/empty_state_card.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import './insights_tab.dart';

class AiInsightsPage extends ConsumerStatefulWidget {
  const AiInsightsPage({super.key});

  @override
  ConsumerState<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends ConsumerState<AiInsightsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _chatScrollController = ScrollController();
  // True only during the brief query-limit check before streaming starts
  bool _isSendingCheck = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSendMessage(String text) async {
    if (_isSendingCheck) return;
    setState(() => _isSendingCheck = true);

    final canMakeQuery = await ref.read(canMakeQueryProvider.future);

    if (!mounted) return;
    setState(() => _isSendingCheck = false);

    if (!canMakeQuery) {
      _showQueryLimitDialog();
      return;
    }

    // Increment query count — continue even if this fails
    try {
      await ref.read(aiQueryOperationsProvider).incrementQueryCount();
    } catch (e) {
      debugPrint('Failed to increment query count: $e');
    }

    if (!mounted) return;

    // Streaming starts immediately inside the notifier; no need to await
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
    ref.invalidate(dynamicPromptsProvider);
  }

  void _handleActionTap(String actionType) {
    // Handle action button taps
    switch (actionType) {
      case 'view_accounts':
        // Navigate to transactions page to view all accounts
        context.go('/transactions');
        break;
      case 'add_transaction':
        // Navigate to add transaction page
        context.push('/transactions/add');
        break;
      case 'view_details':
        _handleSendMessage('Tell me more details');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('AI Insights'),
        actions: [
          if (_tabController.index == 0)
            PopupMenuButton<String>(
              icon: const Icon(CupertinoIcons.ellipsis),
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearChatDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.delete, size: 20),
                      SizedBox(width: 8),
                      Text('Clear chat history'),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(CupertinoIcons.refresh),
              onPressed: () {
                ref.invalidate(spendingInsightsProvider);
                ref.invalidate(defaultCategoryBreakdownProvider);
                ref.invalidate(defaultForecastProvider);
                ref.invalidate(balanceForecastProvider);
                ref.invalidate(multiScenarioForecastProvider);
                ref.invalidate(typedProactiveAlertsProvider);
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.brandTeal,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.brandTeal,
          tabs: const [
            Tab(
              icon: Icon(CupertinoIcons.chat_bubble_text, size: 20),
              text: 'Chat',
            ),
            Tab(
              icon: Icon(CupertinoIcons.chart_bar_alt_fill, size: 20),
              text: 'Insights',
            ),
            Tab(
              icon: Icon(CupertinoIcons.graph_circle, size: 20),
              text: 'Forecast',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          const InsightsTab(),
          _buildForecastTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final chatMessagesAsync = ref.watch(chatProvider);
    final List<String> suggestedPrompts =
        ref.watch(dynamicPromptsProvider).whenOrNull(data: (p) => p) ??
            ref.watch(suggestedPromptsProvider);

    return chatMessagesAsync.when(
      data: (messages) {
        final isStreaming =
            _isSendingCheck || messages.any((m) => m.status == MessageStatus.streaming);

        // Auto-scroll when a streaming message grows
        if (isStreaming) _scrollToBottom();

        return Column(
          children: [
            // Query limit banner — only visible ≥7/10 queries, chat tab only
            const QueryLimitBanner(),
            Expanded(
              child: messages.isEmpty
                  ? EmptyStateCard(
                      icon: CupertinoIcons.chat_bubble,
                      title: 'Start a Conversation',
                      message:
                          'Ask me anything about your finances! I can help you understand your spending patterns, track budgets, and make smarter financial decisions.',
                      backgroundColor: AppColors.brandTeal,
                    )
                  : ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                      itemCount: messages.length,
                      itemBuilder: (context, index) => EnhancedChatMessageBubble(
                        message: messages[index],
                        onFollowUpTap: _handleSendMessage,
                        onActionTap: _handleActionTap,
                      ),
                    ),
            ),
            // Persistent quick prompts always visible above the input
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.sm, bottom: AppSizes.xs),
              child: SuggestedPrompts(
                prompts: suggestedPrompts,
                onPromptTap: _handleSendMessage,
              ),
            ),
            ChatInputField(
              onSend: _handleSendMessage,
              isLoading: isStreaming,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorRetryWidget(
        title: 'Failed to load chat',
        message: 'Unable to load chat history',
        onRetry: () => ref.invalidate(chatProvider),
      ),
    );
  }

  Widget _buildForecastTab() {
    final activeForecastAsync = ref.watch(activeForecastProvider);
    final selectedScenario = ref.watch(selectedForecastScenarioProvider);
    final currencyFormat = ref.watch(currencyFormat2Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(balanceForecastProvider);
        ref.invalidate(multiScenarioForecastProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scenario selector — segmented-control style
            Row(
              children: ForecastScenarioType.values.map((type) {
                final isSelected = selectedScenario == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: type != ForecastScenarioType.conservative
                          ? AppSizes.xs
                          : 0,
                      left: type != ForecastScenarioType.baseline
                          ? AppSizes.xs
                          : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(selectedForecastScenarioProvider.notifier)
                          .state = type,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandTeal
                              : cardColor,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          type.label,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.md),
            activeForecastAsync.when(
              data: (forecast) {
                final balance = forecast.currentBalance;

                // Worst-case projected balance over 30 days — drives card color
                final minProjected = forecast.dailyForecasts.isEmpty
                    ? balance
                    : forecast.dailyForecasts
                        .map((d) => d.projectedBalance)
                        .reduce((a, b) => a < b ? a : b);

                final projected30 = forecast.dailyForecasts.isNotEmpty
                    ? forecast.dailyForecasts.last.projectedBalance
                    : balance;
                final isProjectedRisk = projected30 < 100;

                final List<Color> gradient;
                final Color shadowBase;
                final String oneLiner;

                if (minProjected > 500) {
                  gradient = [
                    AppColors.systemGreen,
                    const Color(0xFF27AE60),
                  ];
                  shadowBase = AppColors.systemGreen;
                  oneLiner = 'Your balance stays healthy throughout the next 30 days.';
                } else if (minProjected > 100) {
                  gradient = [
                    AppColors.systemOrange,
                    const Color(0xFFE67E22),
                  ];
                  shadowBase = AppColors.systemOrange;
                  final criticalDays = forecast.dailyForecasts
                      .where((d) => d.status == BalanceStatus.critical)
                      .length;
                  oneLiner = criticalDays > 0
                      ? 'Balance may drop critically low on $criticalDays day${criticalDays == 1 ? '' : 's'} this month.'
                      : 'Balance will get tight — projected low of ${currencyFormat.format(minProjected)}.';
                } else {
                  gradient = [
                    AppColors.systemRed,
                    const Color(0xFFC0392B),
                  ];
                  shadowBase = AppColors.systemRed;
                  oneLiner = forecast.warnings.isNotEmpty
                      ? forecast.warnings.first
                      : 'Balance is projected to hit a critical low. Review your expenses.';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero card
                    GradientHeroCard(
                      gradientColors: gradient,
                      shadowColor: shadowBase.withValues(alpha: 0.35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Balance',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            currencyFormat.format(balance),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          Row(
                            children: [
                              HeroStatBadge(
                                label: 'Safe to Spend',
                                value: currencyFormat
                                    .format(forecast.safeToSpend),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              HeroStatBadge(
                                label: '30-Day Projection',
                                value: currencyFormat.format(projected30),
                                highlight: isProjectedRisk,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    // One-liner interpretation
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xs),
                      child: Text(
                        oneLiner,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    BalanceTimelineChart(forecast: forecast),
                    const SizedBox(height: AppSizes.md),
                    _buildForecastDetails(
                        forecast.dailyForecasts.take(7).toList(), cardColor),
                  ],
                );
              },
              loading: () => const Column(
                children: [
                  SkeletonCard(height: 180),
                  SizedBox(height: AppSizes.md),
                  SkeletonCard(height: 250),
                ],
              ),
              error: (error, stack) => ErrorRetryWidget(
                title: 'Failed to generate forecast',
                message: 'Unable to predict future balance',
                onRetry: () => ref.invalidate(multiScenarioForecastProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastDetails(List<DailyForecast> forecast, Color cardColor) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    final currencyFormat = ref.watch(currencyFormat0Provider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.separatorDark : AppColors.separator;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
            child: Text(
              'Next 7 Days',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          ...forecast.asMap().entries.map((entry) {
            final i = entry.key;
            final day = entry.value;

            final Color statusColor;
            final String statusLabel;
            switch (day.status) {
              case BalanceStatus.warning:
                statusColor = AppColors.warning;
                statusLabel = 'Low';
                break;
              case BalanceStatus.critical:
                statusColor = AppColors.error;
                statusLabel = 'Critical';
                break;
              default:
                statusColor = AppColors.success;
                statusLabel = 'Good';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i > 0)
                  Divider(height: 1, thickness: 0.5, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: AppSizes.sm),
                  child: Row(
                    children: [
                      // Date + scheduled transactions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(day.date),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            if (day.scheduledTransactions.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              ...day.scheduledTransactions.map(
                                (tx) => Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    '· $tx',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      // Balance + status pill
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(day.projectedBalance),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            ),
                            child: Text(
                              statusLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == tomorrow) return 'Tomorrow';

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showQueryLimitDialog() {
    final operations = ref.read(aiQueryOperationsProvider);
    final daysUntilReset = operations.getDaysUntilReset();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(CupertinoIcons.xmark_circle, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('Query Limit Reached'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You\'ve used all 10 free AI queries for this month.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Your limit resets in $daysUntilReset days.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium for:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_circle_fill,
                        color: AppColors.success, size: 16),
                      SizedBox(width: 8),
                      Text('Unlimited AI queries'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_circle_fill,
                        color: AppColors.success, size: 16),
                      SizedBox(width: 8),
                      Text('Advanced insights & forecasting'),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_circle_fill,
                        color: AppColors.success, size: 16),
                      SizedBox(width: 8),
                      Text('Receipt scanning & more'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Premium subscriptions coming soon. Stay tuned!'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
            ),
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }
}
