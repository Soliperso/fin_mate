import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';
import '../../features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'notification_service.dart';

/// Runs at app open and automatically processes any overdue recurring
/// transactions for the current user.
///
/// For each active recurring transaction whose [nextOccurrence] is in the past:
///   1. Inserts a [transactions] row dated at the scheduled occurrence date.
///   2. Advances [nextOccurrence] by the transaction's frequency.
///   3. Repeats for every missed cycle, capped at [_maxCyclesPerTx].
///   4. Deactivates the recurring transaction if its [endDate] has passed.
///
/// On completion, creates a single in-app notification summarising how many
/// transactions were logged automatically.
class RecurringTransactionProcessor {
  final SupabaseClient _supabase;

  /// Maximum number of missed cycles processed per recurring transaction.
  /// Prevents runaway inserts for very stale records (e.g. daily, years old).
  static const int _maxCyclesPerTx = 12;

  RecurringTransactionProcessor({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  Future<void> processOverdue() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final rows = await _supabase
          .from('recurring_transactions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true) as List<dynamic>;

      final today = DateTime.now();
      int totalProcessed = 0;

      for (final row in rows) {
        final nextOccurrenceStr = row['next_occurrence'] as String?;
        if (nextOccurrenceStr == null) continue;

        DateTime current = DateTime.parse(nextOccurrenceStr);
        if (!current.isBefore(today)) continue; // not due yet

        // Deactivate if past end date
        final endDateStr = row['end_date'] as String?;
        if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          if (endDate.isBefore(today)) {
            await _supabase
                .from('recurring_transactions')
                .update({
                  'is_active': false,
                  'updated_at': today.toIso8601String(),
                })
                .eq('id', row['id'] as String)
                .eq('user_id', userId);
            continue;
          }
        }

        final frequency = RecurringFrequency.values.firstWhere(
          (f) => f.name == (row['frequency'] as String),
          orElse: () => RecurringFrequency.monthly,
        );

        int cycles = 0;

        while (current.isBefore(today) && cycles < _maxCyclesPerTx) {
          final insertData = <String, dynamic>{
            'user_id': userId,
            'account_id': row['account_id'],
            'type': row['type'],
            'amount': row['amount'],
            'date': current.toIso8601String().split('T')[0],
            'is_recurring': true,
          };

          if (row['category_id'] != null) {
            insertData['category_id'] = row['category_id'];
          }
          if (row['description'] != null) {
            insertData['description'] = row['description'];
          }
          if (row['to_account_id'] != null) {
            insertData['to_account_id'] = row['to_account_id'];
          }

          await _supabase.from('transactions').insert(insertData);

          current = _advance(current, frequency);
          cycles++;
          totalProcessed++;
        }

        // Persist the advanced next_occurrence
        await _supabase
            .from('recurring_transactions')
            .update({
              'next_occurrence': current.toIso8601String().split('T')[0],
              'updated_at': today.toIso8601String(),
            })
            .eq('id', row['id'] as String)
            .eq('user_id', userId);
      }

      if (totalProcessed > 0) {
        await NotificationService(supabaseClient: _supabase).createNotification(
          userId: userId,
          type: NotificationType.transactionAlert,
          title: 'Recurring Transactions Logged',
          message:
              '$totalProcessed recurring transaction${totalProcessed == 1 ? '' : 's'} '
              'have been automatically logged.',
          priority: NotificationPriority.medium,
          actionUrl: '/recurring-transactions',
          actionLabel: 'View',
        );
      }
    } catch (e) {
      debugPrint('[RecurringTransactionProcessor] processOverdue error: $e');
    }
  }

  DateTime _advance(DateTime from, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurringFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}
