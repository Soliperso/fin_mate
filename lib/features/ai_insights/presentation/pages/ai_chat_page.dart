import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/providers/ai_query_limit_provider.dart';
import '../../../../core/config/supabase_client.dart';
import '../../../../shared/widgets/error_retry_widget.dart';
import '../providers/chat_provider.dart';
import '../providers/insights_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../widgets/enhanced_chat_message_bubble.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/suggested_prompts.dart';
import '../widgets/query_limit_banner.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isSendingCheck = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSendMessage(String text) async {
    if (_isSendingCheck || text.trim().isEmpty) return;
    setState(() => _isSendingCheck = true);

    final canMakeQuery = await ref.read(canMakeQueryProvider.future);

    if (!mounted) return;
    setState(() => _isSendingCheck = false);

    if (!canMakeQuery) {
      if (mounted) context.push('/paywall?reason=ai_limit');
      return;
    }

    if (!mounted) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    // Counter is now incremented atomically by the openai-proxy Edge Function.
    // Invalidate here so the usage banner reflects the new count after the response.
    ref.invalidate(aiQueryUsageProvider);
    _scrollToBottom();
    ref.invalidate(dynamicPromptsProvider);
  }

  void _handleActionTap(String actionType) {
    switch (actionType) {
      case 'view_accounts':
        context.go('/transactions');
      case 'add_transaction':
        context.push('/transactions/add');
      case 'view_details':
        _handleSendMessage('Tell me more details');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider);
    final List<String> suggestedPrompts =
        ref.watch(dynamicPromptsProvider).whenOrNull(data: (p) => p) ??
            ref.watch(suggestedPromptsProvider);
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
        title: Text(
          'AI Assistant',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSizes.sm),
            child: GestureDetector(
              onTap: () => _showClearChatDialog(),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.brandTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.delete,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: chatAsync.when(
        data: (messages) {
          final generalMessages =
              messages.where((m) => m.metadata?['goalId'] == null).toList();
          final isStreaming = _isSendingCheck ||
              generalMessages.any((m) => m.status == MessageStatus.streaming);
          if (isStreaming) _scrollToBottom();
          final hasMessages = generalMessages.isNotEmpty;

          return Column(
            children: [
              const QueryLimitBanner(),
              Expanded(
                child: !hasMessages
                    ? _buildWelcome(isDark, suggestedPrompts)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md),
                        itemCount: generalMessages.length,
                        itemBuilder: (context, index) =>
                            EnhancedChatMessageBubble(
                          message: generalMessages[index],
                          onFollowUpTap: _handleSendMessage,
                          onActionTap: _handleActionTap,
                        ),
                      ),
              ),
              if (hasMessages)
                Padding(
                  padding: const EdgeInsets.only(
                      top: AppSizes.sm, bottom: AppSizes.xs),
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
        loading: () => const Column(
          children: [
            QueryLimitBanner(),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        error: (error, stack) => ErrorRetryWidget(
          title: 'Failed to load chat',
          message: 'Unable to load chat history',
          onRetry: () => ref.invalidate(chatProvider),
        ),
      ),
    );
  }

  IconData _iconForPrompt(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('debt') || p.contains('payoff') || p.contains('credit')) {
      return CupertinoIcons.creditcard;
    }
    if (p.contains('bill') || p.contains('due') || p.contains('week')) {
      return CupertinoIcons.calendar_today;
    }
    if (p.contains('save') || p.contains('saving') || p.contains('goal')) {
      return CupertinoIcons.chart_bar_alt_fill;
    }
    if (p.contains('spend') || p.contains('expens') || p.contains('budget') ||
        p.contains('afford') || p.contains('categor')) {
      return CupertinoIcons.arrow_up_circle;
    }
    if (p.contains('balance') || p.contains('account')) {
      return CupertinoIcons.creditcard;
    }
    if (p.contains('income') || p.contains('earn')) {
      return CupertinoIcons.arrow_down_circle;
    }
    return CupertinoIcons.sparkles;
  }

  Widget _buildWelcome(bool isDark, List<String> prompts) {
    final meta = supabase.auth.currentUser?.userMetadata;
    final rawName =
        meta?['full_name'] as String? ?? meta?['name'] as String? ?? '';
    final firstName = rawName.trim().isNotEmpty
        ? rawName.trim().split(' ').first
        : (supabase.auth.currentUser?.email?.split('@').first ?? 'there');

    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.lg, AppSizes.md, AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.brandTeal, AppColors.tealLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.sparkles,
                    size: 22, color: Colors.white),
              ),
              const SizedBox(width: AppSizes.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finmate AI',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Your personal finance assistant',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // First message bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Text(
              'Hi, $firstName! I\'ve analysed your finances. What would you like to explore?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),

          // Quick start prompts
          Text(
            'QUICK START',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.sm),
          ...prompts.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs + 2),
              child: GestureDetector(
                onTap: () => _handleSendMessage(text),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_iconForPrompt(text),
                          size: 18, color: AppColors.brandTeal),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          text,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History'),
        content:
            const Text('Are you sure you want to clear all chat messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearHistory();
              Navigator.pop(ctx);
            },
            child: Text('Clear',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

}
