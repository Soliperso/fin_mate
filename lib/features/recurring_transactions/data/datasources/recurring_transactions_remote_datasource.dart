import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/recurring_transaction_model.dart';

class RecurringTransactionsRemoteDatasource {
  final SupabaseClient _supabase;

  RecurringTransactionsRemoteDatasource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  Future<List<RecurringTransactionModel>> getAllRecurringTransactions() async {
    final response = await _supabase
        .from('recurring_transactions')
        .select('''
          *,
          categories(name)
        ''')
        .order('next_occurrence', ascending: true);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      return RecurringTransactionModel.fromJson(data);
    }).toList();
  }

  Future<List<RecurringTransactionModel>> getActiveRecurringTransactions() async {
    final response = await _supabase
        .from('recurring_transactions')
        .select('''
          *,
          categories(name)
        ''')
        .eq('is_active', true)
        .order('next_occurrence', ascending: true);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      return RecurringTransactionModel.fromJson(data);
    }).toList();
  }

  Future<List<RecurringTransactionModel>> getUpcomingRecurringTransactions({
    int daysAhead = 30,
  }) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));

    final response = await _supabase
        .from('recurring_transactions')
        .select('''
          *,
          categories(name)
        ''')
        .eq('is_active', true)
        .gte('next_occurrence', now.toIso8601String().split('T')[0])
        .lte('next_occurrence', futureDate.toIso8601String().split('T')[0])
        .order('next_occurrence', ascending: true);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      return RecurringTransactionModel.fromJson(data);
    }).toList();
  }

  Future<RecurringTransactionModel> getRecurringTransactionById(String id) async {
    final response = await _supabase
        .from('recurring_transactions')
        .select('''
          *,
          categories(name)
        ''')
        .eq('id', id)
        .single();

    final data = Map<String, dynamic>.from(response);
    data['category_name'] = response['categories']?['name'];
    return RecurringTransactionModel.fromJson(data);
  }

  Future<RecurringTransactionModel> createRecurringTransaction(
    Map<String, dynamic> data,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    data['user_id'] = userId;

    final response = await _supabase
        .from('recurring_transactions')
        .insert(data)
        .select('''
          *,
          categories(name)
        ''')
        .single();

    final responseData = Map<String, dynamic>.from(response);
    responseData['category_name'] = response['categories']?['name'];
    return RecurringTransactionModel.fromJson(responseData);
  }

  Future<RecurringTransactionModel> updateRecurringTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _supabase
        .from('recurring_transactions')
        .update(data)
        .eq('id', id)
        .select('''
          *,
          categories(name)
        ''')
        .single();

    final responseData = Map<String, dynamic>.from(response);
    responseData['category_name'] = response['categories']?['name'];
    return RecurringTransactionModel.fromJson(responseData);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _supabase
        .from('recurring_transactions')
        .delete()
        .eq('id', id);
  }
}
