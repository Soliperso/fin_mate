import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/ai_query_limit_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/balance_forecast_provider.dart';
import '../providers/insights_providers.dart';
import '../../domain/entities/balance_forecast.dart';
import '../widgets/enhanced_chat_message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/suggested_prompts.dart';
import '../widgets/balance_forecast_card.dart';
import '../widgets/balance_timeline_chart.dart';
import '../widgets/query_limit_banner.dart';
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
  bool _isProcessing = false;

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
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleSendMessage(String text) async {
    // Check if user can make a query
    final canMakeQuery = await ref.read(canMakeQueryProvider.future);

    if (!canMakeQuery) {
      // Show limit reached dialog
      if (!mounted) return;
      _showQueryLimitDialog();
      return;
    }

    setState(() => _isProcessing = true);
    _scrollToBottom();

    // Increment query count for freemium users
    try {
      await ref.read(aiQueryOperationsProvider).incrementQueryCount();
    } catch (e) {
      // Continue even if count increment fails
      debugPrint('Failed to increment query count: $e');
    }

    // Ensure typing indicator shows for at least 800ms for better UX
    final minDisplayTime = Future.delayed(const Duration(milliseconds: 800));

    await Future.wait([
      ref.read(chatProvider.notifier).sendMessage(text),
      minDisplayTime,
    ]);

    setState(() => _isProcessing = false);
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
    final List<String> suggestedPrompts = ref.watch(dynamicPromptsProvider).whenOrNull(data: (p) => p)
        ?? ref.watch(suggestedPromptsProvider);

    return Column(
      children: [
        // Query limit banner
        const Padding(
          padding: EdgeInsets.all(AppSizes.md),
          child: QueryLimitBanner(),
        ),
        Expanded(
          child: chatMessagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return EmptyStateCard(
                  icon: CupertinoIcons.chat_bubble,
                  title: 'Start a Conversation',
                  message: 'Ask me anything about your finances! I can help you understand your spending patterns, track budgets, and make smarter financial decisions.',
                  backgroundColor: AppColors.brandTeal,
                );
              }

              return ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                itemCount: messages.length + (_isProcessing ? 2 : 1),
                itemBuilder: (context, index) {
                  // Show typing indicator while processing
                  if (_isProcessing && index == messages.length) {
                    return const TypingIndicator();
                  }

                  // Suggested prompts at bottom
                  if (index == messages.length || (_isProcessing && index == messages.length + 1)) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: AppSizes.md,
                        bottom: AppSizes.sm,
                      ),
                      child: SuggestedPrompts(
                        prompts: suggestedPrompts,
                        onPromptTap: _handleSendMessage,
                      ),
                    );
                  }

                  return EnhancedChatMessageBubble(
                    message: messages[index],
                    onFollowUpTap: _handleSendMessage,
                    onActionTap: _handleActionTap,
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => ErrorRetryWidget(
              title: 'Failed to load chat',
              message: 'Unable to load chat history',
              onRetry: () => ref.invalidate(chatProvider),
            ),
          ),
        ),
        ChatInputField(
          onSend: _handleSendMessage,
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  Widget _buildForecastTab() {
    final activeForecastAsync = ref.watch(activeForecastProvider);
    final selectedScenario = ref.watch(selectedForecastScenarioProvider);

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
            // Scenario selector
            SegmentedButton<ForecastScenarioType>(
              segments: ForecastScenarioType.values
                  .map((t) => ButtonSegment<ForecastScenarioType>(
                        value: t,
                        label: Text(
                          t.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              selected: {selectedScenario},
              onSelectionChanged: (s) => ref
                  .read(selectedForecastScenarioProvider.notifier)
                  .state = s.first,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.6);
                  }
                  return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
                }),
              ),
              expandedInsets: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSizes.md),
            activeForecastAsync.when(
              data: (forecast) {
                return Column(
                  children: [
                    BalanceForecastCard(forecast: forecast),
                    const SizedBox(height: AppSizes.md),
                    BalanceTimelineChart(forecast: forecast),
                    const SizedBox(height: AppSizes.md),
                    _buildForecastDetails(forecast.dailyForecasts.take(7).toList()),
                  ],
                );
              },
              loading: () => Column(
                children: const [
                  SkeletonCard(height: 200),
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

  Widget _buildForecastDetails(List forecast) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondarySystemBackgroundDark
            : AppColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next 7 Days Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            ...forecast.map((day) {
              final date = day.date as DateTime;
              final balance = day.projectedBalance as double;
              final status = day.status;
              final transactions = day.scheduledTransactions as List<String>;

              Color statusColor = AppColors.success;
              if (status.toString().contains('warning')) {
                statusColor = AppColors.warning;
              } else if (status.toString().contains('critical')) {
                statusColor = AppColors.error;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(date),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              '\$${balance.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: statusColor.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (transactions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      for (final tx in transactions)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSizes.sm, top: 2),
                          child: Text(
                            tx,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
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
