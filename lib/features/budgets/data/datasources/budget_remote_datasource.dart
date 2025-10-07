import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/budget_model.dart';

class BudgetRemoteDataSource {
  final SupabaseClient _supabase;

  BudgetRemoteDataSource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  /// Get all budgets for current user
  Future<List<BudgetModel>> getBudgets({bool? isActive}) async {
    var query = _supabase.from('budgets').select('''
          *,
          categories(name, icon, color)
        ''');

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      data['category_icon'] = json['categories']?['icon'];
      data['category_color'] = json['categories']?['color'];
      return BudgetModel.fromJson(data);
    }).toList();
  }

  /// Get a specific budget by ID
  Future<BudgetModel> getBudgetById(String id) async {
    final response = await _supabase
        .from('budgets')
        .select('''
          *,
          categories(name, icon, color)
        ''')
        .eq('id', id)
        .single();

    final data = Map<String, dynamic>.from(response);
    data['category_name'] = response['categories']?['name'];
    data['category_icon'] = response['categories']?['icon'];
    data['category_color'] = response['categories']?['color'];

    return BudgetModel.fromJson(data);
  }

  /// Create new budget
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final response = await _supabase
        .from('budgets')
        .insert(budget.toJson())
        .select('''
          *,
          categories(name, icon, color)
        ''')
        .single();

    final data = Map<String, dynamic>.from(response);
    data['category_name'] = response['categories']?['name'];
    data['category_icon'] = response['categories']?['icon'];
    data['category_color'] = response['categories']?['color'];

    return BudgetModel.fromJson(data);
  }

  /// Update budget
  Future<BudgetModel> updateBudget(String id, BudgetModel budget) async {
    final response = await _supabase
        .from('budgets')
        .update(budget.toJson())
        .eq('id', id)
        .select('''
          *,
          categories(name, icon, color)
        ''')
        .single();

    final data = Map<String, dynamic>.from(response);
    data['category_name'] = response['categories']?['name'];
    data['category_icon'] = response['categories']?['icon'];
    data['category_color'] = response['categories']?['color'];

    return BudgetModel.fromJson(data);
  }

  /// Delete budget
  Future<void> deleteBudget(String id) async {
    await _supabase.from('budgets').delete().eq('id', id);
  }

  /// Get budgets for a specific category
  Future<List<BudgetModel>> getBudgetsByCategory(String categoryId) async {
    final response = await _supabase
        .from('budgets')
        .select('''
          *,
          categories(name, icon, color)
        ''')
        .eq('category_id', categoryId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final data = Map<String, dynamic>.from(json);
      data['category_name'] = json['categories']?['name'];
      data['category_icon'] = json['categories']?['icon'];
      data['category_color'] = json['categories']?['color'];
      return BudgetModel.fromJson(data);
    }).toList();
  }

  /// Calculate total spending for a budget period
  ///
  /// Gets sum of all expenses in the budget's category
  /// within the budget's date range
  Future<double> calculateSpending({
    required String? categoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      var query = _supabase
          .from('transactions')
          .select('amount')
          .eq('type', 'expense')
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query;

      if (response.isEmpty) {
        return 0.0;
      }

      return (response as List).fold<double>(
        0.0,
        (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
      );
    } catch (e) {
      return 0.0;
    }
  }
}
