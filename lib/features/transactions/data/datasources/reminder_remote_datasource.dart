import 'package:finmate/core/config/supabase_client.dart';

class ReminderRemoteDatasource {
  /// Creates a reminder for [transactionId].
  /// [transactionDate] is used to compute remind_at = transactionDate - daysBefore.
  Future<void> createReminder({
    required String transactionId,
    required DateTime transactionDate,
    required int daysBefore,
    String? message,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    final remindAt = transactionDate.subtract(Duration(days: daysBefore));
    await supabase.from('transaction_reminders').insert({
      'user_id': userId,
      'transaction_id': transactionId,
      'remind_at': remindAt.toIso8601String().substring(0, 10),
      'days_before': daysBefore,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  /// Deletes a reminder by its id.
  Future<void> deleteReminder(String reminderId) async {
    await supabase.from('transaction_reminders').delete().eq('id', reminderId);
  }

  /// Returns all reminders for a given transaction.
  Future<List<Map<String, dynamic>>> getRemindersForTransaction(
      String transactionId) async {
    final data = await supabase
        .from('transaction_reminders')
        .select()
        .eq('transaction_id', transactionId)
        .order('remind_at');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fires the server-side function that converts due reminders into notifications.
  Future<void> processReminders() async {
    await supabase.rpc('process_transaction_reminders');
  }
}
