import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/config/supabase_client.dart';
import '../../domain/entities/query_response.dart';
import '../../domain/entities/chat_message.dart';

class OpenAiChatService {
  final SupabaseClient _supabase;

  // Chat history: list of {role, content} maps for multi-turn context
  final List<Map<String, String>> _conversationHistory = [];
  String? _systemPrompt;

  static const String _model = 'gpt-4o-mini';
  static const int _maxHistoryTurns = 20; // Keep last 20 turns (40 messages)

  OpenAiChatService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  // AI is available when the user is authenticated (key lives server-side)
  bool get isAvailable => _supabase.auth.currentUser != null;

  /// Build the financial context system prompt from user's live data
  Future<String> _buildSystemPrompt(String userId) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are Finmate\'s AI financial assistant. '
      'Be concise (under 150 words per response), helpful, and use the user\'s actual financial data below. '
      'Never invent numbers. Only discuss personal finance topics. '
      'Format amounts as \$X,XXX.XX. '
      'Do not use markdown, asterisks, bullet symbols, or any special formatting — plain text only.',
    );

    try {
      // Account balances
      final accounts = await _supabase
          .from('accounts')
          .select('name, balance, type')
          .eq('user_id', userId)
          .eq('is_active', true);

      if ((accounts as List).isNotEmpty) {
        double total = 0;
        buffer.writeln('\nAccounts:');
        for (final a in accounts) {
          final bal = (a['balance'] as num).toDouble();
          total += bal;
          buffer.writeln(
              '- ${a['name']} (${a['type']}): \$${bal.toStringAsFixed(2)}');
        }
        buffer.writeln('Total balance: \$${total.toStringAsFixed(2)}');
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch account balances: $e');
    }

    try {
      // Top 5 spending categories this month
      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final txns = await _supabase
          .from('transactions')
          .select('amount, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', monthStart);

      final categoryTotals = <String, double>{};
      for (final t in txns as List) {
        final cat =
            (t['categories'] as Map<String, dynamic>?)?['name'] as String? ??
                'Other';
        categoryTotals[cat] =
            (categoryTotals[cat] ?? 0) + (t['amount'] as num).toDouble();
      }

      if (categoryTotals.isNotEmpty) {
        final sorted = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        buffer.writeln('\nTop spending this month:');
        for (final e in sorted.take(5)) {
          buffer.writeln('- ${e.key}: \$${e.value.toStringAsFixed(2)}');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch spending categories: $e');
    }

    try {
      // Upcoming recurring bills (next 14 days)
      final endDate = DateTime.now().add(const Duration(days: 14));
      final bills = await _supabase
          .from('recurring_transactions')
          .select('description, amount, next_occurrence')
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('type', 'expense')
          .lte('next_occurrence', endDate.toIso8601String().split('T')[0]);

      if ((bills as List).isNotEmpty) {
        buffer.writeln('\nUpcoming bills (next 14 days):');
        for (final b in bills) {
          buffer.writeln(
              '- ${b['description']}: \$${(b['amount'] as num).toStringAsFixed(2)} on ${b['next_occurrence']}');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch upcoming bills: $e');
    }

    try {
      // Debts
      final debts = await _supabase
          .from('debts')
          .select('name, current_balance, interest_rate, minimum_payment, type')
          .eq('user_id', userId)
          .eq('is_active', true);

      if ((debts as List).isNotEmpty) {
        double totalDebt = 0;
        buffer.writeln('\nDebts:');
        for (final d in debts) {
          final bal = (d['current_balance'] as num).toDouble();
          totalDebt += bal;
          buffer.writeln(
              '- ${d['name']} (${d['type']}): \$${bal.toStringAsFixed(2)} @ ${d['interest_rate']}% APR, min \$${(d['minimum_payment'] as num).toStringAsFixed(2)}/mo');
        }
        buffer.writeln('Total debt: \$${totalDebt.toStringAsFixed(2)}');
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch debts: $e');
    }

    try {
      // Monthly budgets
      final budgets = await _supabase
          .from('budgets')
          .select('amount, categories(name)')
          .eq('user_id', userId);

      if ((budgets as List).isNotEmpty) {
        buffer.writeln('\nMonthly budgets:');
        for (final b in budgets) {
          final catName =
              (b['categories'] as Map<String, dynamic>?)?['name'] as String? ??
                  'Unknown';
          buffer.writeln(
              '- $catName: \$${(b['amount'] as num).toStringAsFixed(2)}');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch budgets: $e');
    }

    try {
      // Savings goals
      final goals = await _supabase
          .from('savings_goals')
          .select('name, target_amount, current_amount, target_date')
          .eq('user_id', userId)
          .eq('is_completed', false);

      if ((goals as List).isNotEmpty) {
        buffer.writeln('\nSavings goals:');
        for (final g in goals) {
          final target = (g['target_amount'] as num).toDouble();
          final current = (g['current_amount'] as num).toDouble();
          final pct =
              target > 0 ? (current / target * 100).toStringAsFixed(0) : '0';
          final due = g['target_date'] != null ? ', due ${g['target_date']}' : '';
          buffer.writeln(
              '- ${g['name']}: \$${current.toStringAsFixed(2)} of \$${target.toStringAsFixed(2)} ($pct%$due)');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch savings goals: $e');
    }

    return buffer.toString();
  }

  /// Initialize or refresh session with latest financial context
  Future<void> initSession(String userId) async {
    if (_systemPrompt != null && _conversationHistory.isNotEmpty) return;
    _systemPrompt = await _buildSystemPrompt(userId);
    _conversationHistory.clear();
  }

  /// Send a message and get a ChatGPT response
  Future<QueryResponse> sendMessage(String userMessage) async {
    if (!isAvailable) {
      throw Exception('OpenAI API key not configured');
    }

    // Trim history if too long
    if (_conversationHistory.length >= _maxHistoryTurns * 2) {
      _conversationHistory.removeRange(0, 2);
    }

    _conversationHistory.add({'role': 'user', 'content': userMessage});

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt ?? ''},
      ..._conversationHistory,
    ];

    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('User not authenticated');

    final proxyUrl = '${EnvConfig.supabaseUrl}/functions/v1/openai-proxy';
    final response = await http.post(
      Uri.parse(proxyUrl),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
        'apikey': EnvConfig.supabaseAnonKey,
      },
      body: json.encode({
        'model': _model,
        'messages': messages,
        'max_tokens': 400,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      _conversationHistory.removeLast();
      throw Exception('OpenAI request failed: ${response.statusCode}');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final content =
        (decoded['choices'] as List).first['message']['content'] as String;

    _conversationHistory.add({'role': 'assistant', 'content': content});

    return QueryResponse(
      content: content.trim(),
      type: MessageType.text,
    );
  }

  /// Streams the AI response token by token via OpenAI SSE.
  /// Yields each content delta as it arrives. Conversation history is updated
  /// atomically when the stream completes or errors.
  Stream<String> sendMessageStreaming(String userMessage) async* {
    if (!isAvailable) throw Exception('Not authenticated');

    if (_conversationHistory.length >= _maxHistoryTurns * 2) {
      _conversationHistory.removeRange(0, 2);
    }
    _conversationHistory.add({'role': 'user', 'content': userMessage});

    final session = _supabase.auth.currentSession;
    if (session == null) {
      _conversationHistory.removeLast();
      throw Exception('User not authenticated');
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt ?? ''},
      ..._conversationHistory,
    ];

    final proxyUrl = '${EnvConfig.supabaseUrl}/functions/v1/openai-proxy';
    final request = http.Request('POST', Uri.parse(proxyUrl));
    request.headers.addAll({
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
      'apikey': EnvConfig.supabaseAnonKey,
    });
    request.body = json.encode({
      'model': _model,
      'messages': messages,
      'max_tokens': 400,
      'temperature': 0.7,
      'stream': true,
    });

    final client = http.Client();
    final fullContent = StringBuffer();

    try {
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        _conversationHistory.removeLast();
        throw Exception(
            'Streaming request failed: ${streamedResponse.statusCode}');
      }

      await for (final line in streamedResponse.stream
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data: ')) continue;
        final data = trimmed.substring(6);
        if (data == '[DONE]') break;

        try {
          final decoded = json.decode(data) as Map<String, dynamic>;
          final choices = decoded['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;
          final delta = choices.first['delta']?['content'] as String?;
          if (delta != null && delta.isNotEmpty) {
            fullContent.write(delta);
            yield delta;
          }
        } catch (_) {
          // Skip malformed SSE chunks
        }
      }

      if (fullContent.isNotEmpty) {
        _conversationHistory
            .add({'role': 'assistant', 'content': fullContent.toString()});
      } else {
        _conversationHistory.removeLast();
      }
    } catch (e) {
      if (fullContent.isEmpty) _conversationHistory.removeLast();
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Clear session (called when user clears chat history)
  void clearSession() {
    _conversationHistory.clear();
    _systemPrompt = null;
  }
}
