import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/services/query_processor_service.dart';
import '../../data/services/openai_chat_service.dart';
import '../../domain/entities/chat_message.dart';

// Service provider
final queryProcessorProvider = Provider<QueryProcessorService>((ref) {
  return QueryProcessorService(
    openAiChatService: OpenAiChatService(),
  );
});

// Chat history storage key
const String _chatHistoryKey = 'ai_insights_chat_history';
const FlutterSecureStorage _storage = FlutterSecureStorage();

// Chat state notifier
class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final QueryProcessorService _queryProcessor;
  StreamSubscription<String>? _activeStream;

  ChatNotifier(this._queryProcessor) : super(const AsyncValue.loading()) {
    _loadChatHistory();
  }

  @override
  void dispose() {
    _activeStream?.cancel();
    super.dispose();
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
        state = AsyncValue.data([]);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Save chat history to storage (max 50 messages, streaming messages excluded)
  Future<void> _saveChatHistory(List<ChatMessage> messages) async {
    try {
      final toSave =
          messages.where((m) => m.status != MessageStatus.streaming).toList();
      final capped =
          toSave.length > 50 ? toSave.sublist(toSave.length - 50) : toSave;
      await _storage.write(
          key: _chatHistoryKey,
          value: json.encode(capped.map((m) => m.toJson()).toList()));
    } catch (_) {
      // Ignore storage errors — UI already updated
    }
  }

  /// Send a message, streaming the AI response token by token.
  /// Pass [goalId] when sending from the goal coach so messages are scoped
  /// to that goal and excluded from the main AI chat history.
  Future<void> sendMessage(String text, {String? goalId}) async {
    if (text.trim().isEmpty) return;

    // Cancel any in-flight stream before starting a new one
    await _activeStream?.cancel();
    _activeStream = null;

    final currentMessages = state.value ?? [];
    final goalMeta = goalId != null ? {'goalId': goalId} : null;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: MessageSender.user,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      metadata: goalMeta,
    );

    final withUser = [...currentMessages, userMessage];
    state = AsyncValue.data(withUser);
    // Save user message without awaiting — don't block streaming start
    _saveChatHistory(withUser);

    // Placeholder that will grow as tokens arrive
    final assistantId = '${DateTime.now().millisecondsSinceEpoch + 1}';
    final placeholder = ChatMessage(
      id: assistantId,
      sender: MessageSender.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: MessageStatus.streaming,
      metadata: goalMeta,
    );
    state = AsyncValue.data([...withUser, placeholder]);

    final buffer = StringBuffer();

    _activeStream = _queryProcessor.streamMessage(text).listen(
      (chunk) {
        if (!mounted) return;
        buffer.write(chunk.replaceAll('*', ''));
        final current = state.valueOrNull;
        if (current == null) return;
        final idx = current.indexWhere((m) => m.id == assistantId);
        if (idx == -1) return;
        final updated = List<ChatMessage>.from(current);
        updated[idx] = updated[idx].copyWith(content: buffer.toString());
        state = AsyncValue.data(updated);
      },
      onError: (Object e) {
        debugPrint('[ChatNotifier] Stream error: $e');
        _resolveStream(assistantId, buffer.toString(), isError: true);
      },
      onDone: () {
        _resolveStream(assistantId, buffer.toString(), isError: false);
      },
      cancelOnError: true,
    );
  }

  void _resolveStream(String assistantId, String fullContent,
      {required bool isError}) {
    if (!mounted) return;
    final current = state.valueOrNull;
    if (current == null) return;
    final idx = current.indexWhere((m) => m.id == assistantId);
    if (idx == -1) return;

    final ChatMessage resolved;
    if (isError || fullContent.isEmpty) {
      resolved = current[idx].copyWith(
        content: fullContent.isEmpty
            ? 'Sorry, I couldn\'t generate a response. Please try again.'
            : fullContent,
        type: isError ? MessageType.error : MessageType.text,
        status: isError ? MessageStatus.error : MessageStatus.sent,
      );
    } else {
      resolved = current[idx].copyWith(
        content: fullContent,
        status: MessageStatus.sent,
      );
    }

    final updated = List<ChatMessage>.from(current);
    updated[idx] = resolved;
    state = AsyncValue.data(updated);
    _saveChatHistory(updated);
  }

  /// Clear chat history and reset OpenAI session
  Future<void> clearHistory() async {
    await _activeStream?.cancel();
    _activeStream = null;
    _queryProcessor.clearOpenAiSession();
    state = AsyncValue.data([]);
    await _saveChatHistory([]);
  }
}

// Chat provider
final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  final queryProcessor = ref.watch(queryProcessorProvider);
  return ChatNotifier(queryProcessor);
});

// Suggested prompts provider
final suggestedPromptsProvider = Provider<List<String>>((ref) {
  final queryProcessor = ref.watch(queryProcessorProvider);
  return queryProcessor.getSuggestedPrompts();
});
