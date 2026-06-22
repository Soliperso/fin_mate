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
  // Tracks which user the cached system prompt belongs to so a sign-out /
  // sign-in cycle on the same device never leaks the previous user's context.
  String? _cachedForUserId;

  static const String _model = 'gpt-4o-mini';
  static const int _maxHistoryTurns = 20; // Keep last 20 turns (40 messages)

  OpenAiChatService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  // AI is available when the user is authenticated (key lives server-side)
  bool get isAvailable => _supabase.auth.currentUser != null;

  /// Formats a dollar amount exactly with thousands separators and 2 decimals
  /// for the AI context. Example: 1247.83 → "$1,247.83", -50 → "-$50.00".
  ///
  /// Earlier iterations rounded for data-minimisation; reverted to exact
  /// figures so the assistant can give precise, accurate answers — which the
  /// product requires more than vendor-side data minimisation.
  static String _fmtMoney(num amount) {
    final sign = amount < 0 ? '-' : '';
    final abs = amount.abs();
    final whole = abs.truncate();
    final cents = ((abs - whole) * 100).round();
    return '$sign\$${_withThousands(whole)}.${cents.toString().padLeft(2, '0')}';
  }

  /// Inserts commas into a non-negative integer: 1234567 -> "1,234,567".
  static String _withThousands(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    final firstChunk = s.length % 3;
    if (firstChunk > 0) buffer.write(s.substring(0, firstChunk));
    for (int i = firstChunk; i < s.length; i += 3) {
      if (i > 0) buffer.write(',');
      buffer.write(s.substring(i, i + 3));
    }
    return buffer.toString();
  }

  /// Build the financial context system prompt from user's live data
  Future<String> _buildSystemPrompt(String userId) async {
    final buffer = StringBuffer();
    buffer.writeln(
      "User's live financial snapshot follows. These are the user's actual current figures from their accounts, transactions, debts, budgets, goals, and bills. Use exact amounts when answering. Never invent figures not present in this data.",
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
              '- ${a['name']} (${a['type']}): ${_fmtMoney(bal)}');
        }
        buffer.writeln('Total balance: ${_fmtMoney(total)}');
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
          buffer.writeln('- ${e.key}: ${_fmtMoney(e.value)}');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch spending categories: $e');
    }

    try {
      // Upcoming recurring bills (next 14 days). The description is a
      // user-typed label for their own subscription/rent/etc. (same category
      // as debt names and account names) — keep it so the AI can name what
      // it's listing. Amounts are still rounded to the nearest $100.
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
              '- ${b['description']}: ${_fmtMoney((b['amount'] as num))} on ${b['next_occurrence']}');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch upcoming bills: $e');
    }

    try {
      // Debts
      final debts = await _supabase
          .from('debts')
          .select('name, balance, interest_rate, minimum_payment, debt_type')
          .eq('user_id', userId)
          .eq('is_active', true);

      if ((debts as List).isNotEmpty) {
        double totalDebt = 0;
        buffer.writeln('\nDebts:');
        for (final d in debts) {
          final bal = (d['balance'] as num).toDouble();
          totalDebt += bal;
          buffer.writeln(
              '- ${d['name']} (${d['debt_type']}): ${_fmtMoney(bal)} @ ${d['interest_rate']}% APR, min ${_fmtMoney((d['minimum_payment'] as num))}/mo');
        }
        buffer.writeln('Total debt: ${_fmtMoney(totalDebt)}');
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
              '- $catName: ${_fmtMoney((b['amount'] as num))}');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch budgets: $e');
    }

    try {
      // Savings goals
      final goals = await _supabase
          .from('savings_goals')
          .select('name, target_amount, current_amount, deadline')
          .eq('user_id', userId)
          .eq('is_completed', false);

      if ((goals as List).isNotEmpty) {
        buffer.writeln('\nSavings goals:');
        for (final g in goals) {
          final target = (g['target_amount'] as num).toDouble();
          final current = (g['current_amount'] as num).toDouble();
          final pct =
              target > 0 ? (current / target * 100).toStringAsFixed(0) : '0';
          final due = g['deadline'] != null ? ', due ${g['deadline']}' : '';
          buffer.writeln(
              '- ${g['name']}: ${_fmtMoney(current)} of ${_fmtMoney(target)} ($pct%$due)');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch savings goals: $e');
    }

    try {
      // This month's income
      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final income = await _supabase
          .from('transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('type', 'income')
          .gte('date', monthStart);

      final totalIncome = (income as List)
          .fold(0.0, (sum, t) => sum + (t['amount'] as num).toDouble());
      if (totalIncome > 0) {
        buffer.writeln('\nIncome this month: ${_fmtMoney(totalIncome)}');
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch income: $e');
    }

    try {
      // Budget utilization — spent vs limit per category this month
      final now = DateTime.now();
      final monthStart =
          DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final budgets = await _supabase
          .from('budgets')
          .select('amount, category_id, categories(name)')
          .eq('user_id', userId);

      if ((budgets as List).isNotEmpty) {
        final categoryIds = budgets.map((b) => b['category_id']).toList();
        final spent = await _supabase
            .from('transactions')
            .select('amount, category_id')
            .eq('user_id', userId)
            .eq('type', 'expense')
            .gte('date', monthStart)
            .inFilter('category_id', categoryIds);

        final spentByCategory = <dynamic, double>{};
        for (final t in spent as List) {
          final id = t['category_id'];
          spentByCategory[id] =
              (spentByCategory[id] ?? 0) + (t['amount'] as num).toDouble();
        }

        buffer.writeln('\nBudget utilization this month:');
        for (final b in budgets) {
          final catName =
              (b['categories'] as Map<String, dynamic>?)?['name'] as String? ??
                  'Unknown';
          final limit = (b['amount'] as num).toDouble();
          final usedAmt = spentByCategory[b['category_id']] ?? 0.0;
          final pct = limit > 0 ? (usedAmt / limit * 100).toStringAsFixed(0) : '0';
          buffer.writeln(
              '- $catName: ${_fmtMoney(usedAmt)} of ${_fmtMoney(limit)} ($pct%)');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch budget utilization: $e');
    }

    try {
      // Last month's top spending by category
      final now = DateTime.now();
      final lastMonthStart =
          DateTime(now.year, now.month - 1, 1).toIso8601String().split('T')[0];
      final lastMonthEnd =
          DateTime(now.year, now.month, 0).toIso8601String().split('T')[0];
      final lastMonthTxns = await _supabase
          .from('transactions')
          .select('amount, categories(name)')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('date', lastMonthStart)
          .lte('date', lastMonthEnd);

      final lastMonthTotals = <String, double>{};
      for (final t in lastMonthTxns as List) {
        final cat =
            (t['categories'] as Map<String, dynamic>?)?['name'] as String? ??
                'Other';
        lastMonthTotals[cat] =
            (lastMonthTotals[cat] ?? 0) + (t['amount'] as num).toDouble();
      }

      if (lastMonthTotals.isNotEmpty) {
        final sorted = lastMonthTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        buffer.writeln('\nTop spending last month:');
        for (final e in sorted.take(5)) {
          buffer.writeln('- ${e.key}: ${_fmtMoney(e.value)}');
        }
      }
    } catch (e) {
      debugPrint('[OpenAiChatService] Failed to fetch last month spending: $e');
    }

    return buffer.toString();
  }

  /// Initialize or refresh session with latest financial context.
  ///
  /// We rebuild the context on every message (see sendMessage), but this is
  /// still called at chat-open time to pre-warm the snapshot and to detect
  /// cross-user transitions (sign-out → sign-in on the same device must
  /// never serve user A's data to user B).
  Future<void> initSession(String userId) async {
    if (_cachedForUserId != null && _cachedForUserId != userId) {
      _conversationHistory.clear();
    }
    _systemPrompt = await _buildSystemPrompt(userId);
    _cachedForUserId = userId;
  }

  /// Refresh the financial context from Supabase. Called before every send so
  /// the AI always sees the user's current state (a transaction added 10s ago,
  /// a debt paid down this morning, a balance synced just now).
  Future<void> _refreshContext() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    _systemPrompt = await _buildSystemPrompt(uid);
    _cachedForUserId = uid;
  }

  /// Send a message and get a ChatGPT response
  Future<QueryResponse> sendMessage(String userMessage) async {
    if (!isAvailable) {
      throw Exception('OpenAI API key not configured');
    }

    // Refresh the financial snapshot so the AI sees the user's current state
    // (transactions added since chat opened, balances just synced, etc.).
    await _refreshContext();

    // Trim history if too long
    if (_conversationHistory.length >= _maxHistoryTurns * 2) {
      _conversationHistory.removeRange(0, 2);
    }

    _conversationHistory.add({'role': 'user', 'content': userMessage});

    // The proxy strips any `system`-role messages from clients as an
    // anti-prompt-injection measure. Send the financial snapshot as a
    // `[CONTEXT]`-tagged user message + synthetic assistant ack so the model
    // grounds on it. The server's system prompt instructs the model to treat
    // `[CONTEXT]` as data, not instructions.
    final messages = <Map<String, String>>[
      {'role': 'user', 'content': '[CONTEXT]\n${_systemPrompt ?? ''}'},
      {
        'role': 'assistant',
        'content': "Understood. I have your current financial snapshot."
      },
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

    // Refresh the financial snapshot so the AI sees the user's current state.
    await _refreshContext();

    if (_conversationHistory.length >= _maxHistoryTurns * 2) {
      _conversationHistory.removeRange(0, 2);
    }
    _conversationHistory.add({'role': 'user', 'content': userMessage});

    final session = _supabase.auth.currentSession;
    if (session == null) {
      _conversationHistory.removeLast();
      throw Exception('User not authenticated');
    }

    // Same `[CONTEXT]` + synthetic-ack pattern as sendMessage — the proxy
    // strips `system` roles, so the financial snapshot rides as a user turn.
    final messages = <Map<String, String>>[
      {'role': 'user', 'content': '[CONTEXT]\n${_systemPrompt ?? ''}'},
      {
        'role': 'assistant',
        'content': "Understood. I have your current financial snapshot."
      },
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

  /// Clear session (called when user clears chat history or signs out)
  void clearSession() {
    _conversationHistory.clear();
    _systemPrompt = null;
    _cachedForUserId = null;
  }
}
