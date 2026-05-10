import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/chat_message.dart';
import 'category_breakdown_chart.dart';
import 'follow_up_suggestions.dart';
import 'message_action_button.dart';

/// Blinking cursor shown while the assistant is streaming a response.
class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor();

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(
        '▋',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryTeal,
            ),
      ),
    );
  }
}

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
      padding: EdgeInsets.only(
        left: isUser ? AppSizes.md : 0,
        right: isUser ? AppSizes.md : 0,
        top: AppSizes.xs,
        bottom: AppSizes.xs,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Padding(
              padding:
                  const EdgeInsets.only(left: AppSizes.sm, right: AppSizes.xs),
              child: _buildAvatar(false),
            ),
          ],
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(right: isUser ? 0 : AppSizes.sm),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isUser ? null : double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: isUser
                          ? MediaQuery.of(context).size.width * 0.75
                          : double.infinity,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(isUser, context),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                            isUser ? AppSizes.radiusMd : AppSizes.radiusSm),
                        topRight: Radius.circular(
                            isUser ? AppSizes.radiusSm : AppSizes.radiusMd),
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
                        // Main text content with optional blinking cursor
                        if (message.status == MessageStatus.streaming &&
                            message.content.isEmpty)
                          const _StreamingCursor()
                        else if (message.status == MessageStatus.streaming)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  message.content,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: _getTextColor(isUser, context),
                                        height: 1.45,
                                        fontWeight: isUser
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const _StreamingCursor(),
                            ],
                          )
                        else
                          Text(
                            message.content,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: _getTextColor(isUser, context),
                                  height: 1.45,
                                  fontWeight: isUser
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                          ),

                        // Rich content — only after streaming completes
                        if (message.status != MessageStatus.streaming) ...[
                          if (message.type == MessageType.textWithChart &&
                              message.metadata != null)
                            _buildChartContent(message.metadata!),
                          if (message.type == MessageType.textWithActions &&
                              message.metadata != null)
                            _buildActionsContent(message.metadata!),
                        ],
                      ],
                    ),
                  ),

                  // Timestamp and status
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeFormat.format(message.timestamp),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                        ),
                        if (isUser &&
                            message.status == MessageStatus.sending) ...[
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textTertiary),
                            ),
                          ),
                        ] else if (isUser &&
                            message.status == MessageStatus.error) ...[
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.exclamationmark_circle,
                            size: 12,
                            color: AppColors.error,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Follow-up suggestions — shown only after streaming completes
                  if (!isUser &&
                      message.status == MessageStatus.sent &&
                      message.followUpSuggestions != null &&
                      message.followUpSuggestions!.isNotEmpty)
                    FollowUpSuggestions(
                      suggestions: message.followUpSuggestions!,
                      onSuggestionTap: onFollowUpTap ?? (_) {},
                    ),
                ],
              ),
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
        isUser ? CupertinoIcons.person_fill : CupertinoIcons.sparkles,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Color _getBackgroundColor(bool isUser, BuildContext context) {
    if (message.type == MessageType.error) {
      return AppColors.error.withValues(alpha: 0.1);
    }
    return isUser
        ? AppColors.primaryTeal
        : (Theme.of(context).cardTheme.color ?? AppColors.cardBackground);
  }

  Color _getTextColor(bool isUser, BuildContext context) {
    if (message.type == MessageType.error) {
      return AppColors.error;
    }
    if (isUser) {
      return Colors.white;
    }
    // Use theme's text color for proper dark mode support
    return Theme.of(context).textTheme.bodyMedium?.color ??
        AppColors.textPrimary;
  }

  Widget _buildChartContent(Map<String, dynamic> metadata) {
    final chartType = metadata['chartType'] as String?;

    if (chartType == 'category') {
      try {
        final rawData = metadata['categoryData'];
        if (rawData is List) {
          // Convert each item to Map<String, dynamic> if needed
          final categoryData = rawData
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return null;
              })
              .whereType<Map<String, dynamic>>()
              .toList();

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
        return CupertinoIcons.creditcard;
      case 'add_transaction':
        return CupertinoIcons.add_circled;
      case 'view_details':
        return CupertinoIcons.info_circle;
      case 'create_budget':
        return CupertinoIcons.money_dollar;
      default:
        return CupertinoIcons.chevron_right;
    }
  }
}
