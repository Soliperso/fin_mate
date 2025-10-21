import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/chat_message.dart';
import 'category_breakdown_chart.dart';
import 'follow_up_suggestions.dart';
import 'message_action_button.dart';

class EnhancedChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onFollowUpTap;
  final Function(String)? onActionTap;

  const EnhancedChatMessageBubble({
    super.key,
    required this.message,
    this.onFollowUpTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final timeFormat = DateFormat('h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(false),
            const SizedBox(width: AppSizes.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(isUser),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? AppSizes.radiusMd : AppSizes.radiusSm),
                      topRight: Radius.circular(isUser ? AppSizes.radiusSm : AppSizes.radiusMd),
                      bottomLeft: const Radius.circular(AppSizes.radiusMd),
                      bottomRight: const Radius.circular(AppSizes.radiusMd),
                    ),
                    border: message.type == MessageType.error
                        ? Border.all(color: AppColors.error, width: 1)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main text content
                      Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getTextColor(isUser),
                            ),
                      ),

                      // Rich content based on message type
                      if (message.type == MessageType.textWithChart && message.metadata != null)
                        _buildChartContent(message.metadata!),

                      if (message.type == MessageType.textWithActions && message.metadata != null)
                        _buildActionsContent(message.metadata!),
                    ],
                  ),
                ),

                // Timestamp and status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeFormat.format(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                    ),
                    if (isUser && message.status == MessageStatus.sending) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textTertiary),
                        ),
                      ),
                    ] else if (isUser && message.status == MessageStatus.error) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.error_outline,
                        size: 12,
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),

                // Follow-up suggestions (only for assistant messages)
                if (!isUser && message.followUpSuggestions != null && message.followUpSuggestions!.isNotEmpty)
                  FollowUpSuggestions(
                    suggestions: message.followUpSuggestions!,
                    onSuggestionTap: onFollowUpTap ?? (_) {},
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSizes.sm),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? AppColors.primaryTeal : AppColors.tealLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Color _getBackgroundColor(bool isUser) {
    if (message.type == MessageType.error) {
      return AppColors.error.withValues(alpha: 0.1);
    }
    return isUser ? AppColors.primaryTeal : AppColors.lightGray;
  }

  Color _getTextColor(bool isUser) {
    if (message.type == MessageType.error) {
      return AppColors.error;
    }
    return isUser ? Colors.white : AppColors.textPrimary;
  }

  Widget _buildChartContent(Map<String, dynamic> metadata) {
    final chartType = metadata['chartType'] as String?;

    if (chartType == 'category') {
      try {
        final rawData = metadata['categoryData'];
        if (rawData is List) {
          // Convert each item to Map<String, dynamic> if needed
          final categoryData = rawData.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return null;
          }).whereType<Map<String, dynamic>>().toList();

          if (categoryData.isNotEmpty) {
            return CategoryBreakdownChart(
              categoryData: categoryData,
              maxHeight: 180,
            );
          }
        }
      } catch (e) {
        // Silently fail and return empty
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionsContent(Map<String, dynamic> metadata) {
    final actions = metadata['actions'] as List?;
    if (actions == null || actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSizes.sm),
      child: MessageActionButtons(
        actions: actions.map((action) {
          return {
            'label': action['label'] as String,
            'icon': _getIconForActionType(action['type'] as String),
            'onTap': () {
              if (onActionTap != null) {
                onActionTap!(action['type'] as String);
              }
            },
          };
        }).toList(),
      ),
    );
  }

  IconData _getIconForActionType(String type) {
    switch (type) {
      case 'view_accounts':
        return Icons.account_balance_wallet;
      case 'add_transaction':
        return Icons.add_circle_outline;
      case 'view_details':
        return Icons.info_outline;
      case 'create_budget':
        return Icons.savings_outlined;
      default:
        return Icons.arrow_forward;
    }
  }
}
