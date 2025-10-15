import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/services/query_processor_service.dart';
import '../../domain/entities/chat_message.dart';

// Service provider
final queryProcessorProvider = Provider<QueryProcessorService>((ref) {
  return QueryProcessorService();
});

// Chat history storage key
const String _chatHistoryKey = 'ai_insights_chat_history';
const FlutterSecureStorage _storage = FlutterSecureStorage();

// Chat state notifier
class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final QueryProcessorService _queryProcessor;

  ChatNotifier(this._queryProcessor) : super(const AsyncValue.loading()) {
    _loadChatHistory();
  }

  /// Load chat history from storage
  Future<void> _loadChatHistory() async {
    try {
      final jsonStr = await _storage.read(key: _chatHistoryKey);
      if (jsonStr != null) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        final messages = jsonList
            .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(messages);
      } else {
        // Initialize with welcome message with follow-up suggestions
        final welcomeMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: MessageSender.assistant,
          content: 'Hi! I\'m your AI financial assistant. Ask me anything about your finances, '
              'spending patterns, upcoming bills, or balance forecast. How can I help you today?',
          timestamp: DateTime.now(),
          followUpSuggestions: [
            'What\'s my current balance?',
            'Show my spending by category',
            'What bills are due soon?',
          ],
        );
        state = AsyncValue.data([welcomeMessage]);
        await _saveChatHistory([welcomeMessage]);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Save chat history to storage
  Future<void> _saveChatHistory(List<ChatMessage> messages) async {
    try {
      // Keep only last 50 messages to avoid storage issues
      final messagesToSave = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
      final jsonList = messagesToSave.map((m) => m.toJson()).toList();
      final jsonStr = json.encode(jsonList);
      await _storage.write(key: _chatHistoryKey, value: jsonStr);
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Send a message and get response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentMessages = state.value ?? [];

    // Add user message with sending status
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    final updatedMessages = [...currentMessages, userMessage];
    state = AsyncValue.data(updatedMessages);
    await _saveChatHistory(updatedMessages);

    // Process query and get rich response
    try {
      final response = await _queryProcessor.processQueryRich(text);

      final assistantMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.assistant,
        content: response.content,
        timestamp: DateTime.now(),
        type: response.type,
        status: MessageStatus.sent,
        metadata: response.data,
        followUpSuggestions: response.followUpSuggestions,
      );

      final finalMessages = [...updatedMessages, assistantMessage];
      state = AsyncValue.data(finalMessages);
      await _saveChatHistory(finalMessages);
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: MessageSender.assistant,
        content: 'Sorry, I encountered an error processing your request. Please try again.',
        timestamp: DateTime.now(),
        type: MessageType.error,
        status: MessageStatus.error,
      );

      final finalMessages = [...updatedMessages, errorMessage];
      state = AsyncValue.data(finalMessages);
      await _saveChatHistory(finalMessages);
    }
  }

  /// Clear chat history
  Future<void> clearHistory() async {
    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.assistant,
      content: 'Chat history cleared. How can I help you today?',
      timestamp: DateTime.now(),
      followUpSuggestions: [
        'What\'s my current balance?',
        'Show my spending by category',
        'What bills are due soon?',
      ],
    );

    state = AsyncValue.data([welcomeMessage]);
    await _saveChatHistory([welcomeMessage]);
  }
}

// Chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  final queryProcessor = ref.watch(queryProcessorProvider);
  return ChatNotifier(queryProcessor);
});

// Suggested prompts provider
final suggestedPromptsProvider = Provider<List<String>>((ref) {
  final queryProcessor = ref.watch(queryProcessorProvider);
  return queryProcessor.getSuggestedPrompts();
});
