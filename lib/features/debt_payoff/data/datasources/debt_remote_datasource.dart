import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';

class DebtRemoteDatasource {
  final SupabaseClient _supabase;

  DebtRemoteDatasource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  Future<List<DebtModel>> getDebts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('debts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((json) => DebtModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch debts: $e');
    }
  }

  Future<DebtModel> createDebt({
    required String name,
    required String debtType,
    required double balance,
    required double interestRate,
    required double minimumPayment,
    int? dueDay,
    String? notes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('debts')
          .insert({
            'user_id': userId,
            'name': name,
            'debt_type': debtType,
            'balance': balance,
            'original_balance': balance,
            'interest_rate': interestRate,
            'minimum_payment': minimumPayment,
            'due_day': dueDay,
            'notes': notes,
          })
          .select()
          .single();

      return DebtModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create debt: $e');
    }
  }

  Future<DebtModel> updateDebt(String id, Map<String, dynamic> fields) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('debts')
          .update(fields)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return DebtModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update debt: $e');
    }
  }

  Future<void> deleteDebt(String id) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Soft delete
      await _supabase
          .from('debts')
          .update({'is_active': false})
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete debt: $e');
    }
  }

  Future<List<DebtPaymentModel>> getPayments(String debtId) async {
    try {
      final response = await _supabase
          .from('debt_payments')
          .select()
          .eq('debt_id', debtId)
          .order('payment_date', ascending: false);

      return (response as List).map((json) => DebtPaymentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  Future<DebtPaymentModel> logPayment({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final dateStr = paymentDate.toIso8601String().split('T')[0];

      // Insert payment record
      final paymentResponse = await _supabase
          .from('debt_payments')
          .insert({
            'debt_id': debtId,
            'user_id': userId,
            'amount': amount,
            'payment_date': dateStr,
            'notes': notes,
          })
          .select()
          .single();

      // Fetch current balance and update it
      final debtResponse = await _supabase
          .from('debts')
          .select('balance')
          .eq('id', debtId)
          .eq('user_id', userId)
          .single();

      final currentBalance = (debtResponse['balance'] as num).toDouble();
      final newBalance = (currentBalance - amount).clamp(0.0, double.infinity);

      await _supabase
          .from('debts')
          .update({'balance': newBalance})
          .eq('id', debtId)
          .eq('user_id', userId);

      return DebtPaymentModel.fromJson(paymentResponse);
    } catch (e) {
      throw Exception('Failed to log payment: $e');
    }
  }

  /// Records a debt payment that originated from the Transactions screen.
  /// Does NOT create a transaction entry (the transaction already exists).
  Future<void> recordDebtPayment({
    required String debtId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final dateStr = paymentDate.toIso8601String().split('T')[0];

      await _supabase.from('debt_payments').insert({
        'debt_id': debtId,
        'user_id': userId,
        'amount': amount,
        'payment_date': dateStr,
        'notes': notes,
      });

      final debtResponse = await _supabase
          .from('debts')
          .select('balance')
          .eq('id', debtId)
          .eq('user_id', userId)
          .single();

      final currentBalance = (debtResponse['balance'] as num).toDouble();
      final newBalance = (currentBalance - amount).clamp(0.0, double.infinity);

      await _supabase
          .from('debts')
          .update({'balance': newBalance})
          .eq('id', debtId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to record debt payment: $e');
    }
  }

  Future<Map<String, dynamic>> getDebtSummary() async {
    try {
      final debts = await getDebts();
      final totalBalance = debts.fold<double>(0, (sum, d) => sum + d.balance);
      final totalMinPayment = debts.fold<double>(0, (sum, d) => sum + d.minimumPayment);
      return {
        'total_balance': totalBalance,
        'total_min_payment': totalMinPayment,
        'debt_count': debts.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch debt summary: $e');
    }
  }
}
