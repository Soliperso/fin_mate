import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/savings_goal_model.dart';
import '../models/goal_contribution_model.dart';

class SavingsGoalRemoteDatasource {
  final SupabaseClient _supabase;

  SavingsGoalRemoteDatasource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  // Goals
  Future<List<SavingsGoalModel>> getGoals() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('savings_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SavingsGoalModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch savings goals: $e');
    }
  }

  Future<SavingsGoalModel> getGoalById(String goalId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('savings_goals')
          .select()
          .eq('id', goalId)
          .eq('user_id', userId)
          .single();

      return SavingsGoalModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch goal: $e');
    }
  }

  Future<SavingsGoalModel> createGoal({
    required String name,
    String? description,
    required double targetAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    String? color,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('savings_goals')
          .insert({
            'user_id': userId,
            'name': name,
            'description': description,
            'target_amount': targetAmount,
            'deadline': deadline?.toIso8601String().split('T')[0],
            'category': category,
            'icon': icon,
            'color': color,
          })
          .select()
          .single();

      return SavingsGoalModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  Future<void> updateGoal({
    required String goalId,
    String? name,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    String? category,
    String? icon,
    String? color,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (targetAmount != null) updateData['target_amount'] = targetAmount;
      if (deadline != null) updateData['deadline'] = deadline.toIso8601String().split('T')[0];
      if (category != null) updateData['category'] = category;
      if (icon != null) updateData['icon'] = icon;
      if (color != null) updateData['color'] = color;

      await _supabase
          .from('savings_goals')
          .update(updateData)
          .eq('id', goalId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('savings_goals').delete().eq('id', goalId).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  Future<void> markGoalAsCompleted(String goalId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('savings_goals').update({
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', goalId).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to mark goal as completed: $e');
    }
  }

  // Contributions
  Future<List<GoalContributionModel>> getGoalContributions(String goalId) async {
    try {
      final response = await _supabase
          .from('goal_contributions')
          .select()
          .eq('goal_id', goalId)
          .order('contributed_at', ascending: false);

      return (response as List)
          .map((json) => GoalContributionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch contributions: $e');
    }
  }

  Future<GoalContributionModel> addContribution({
    required String goalId,
    required double amount,
    String? notes,
    String? transactionId,
  }) async {
    try {
      final response = await _supabase
          .from('goal_contributions')
          .insert({
            'goal_id': goalId,
            'amount': amount,
            'notes': notes,
            'transaction_id': transactionId,
            'contributed_at': DateTime.now().toIso8601String().split('T')[0],
          })
          .select()
          .single();

      return GoalContributionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add contribution: $e');
    }
  }

  Future<void> deleteContribution(String contributionId) async {
    try {
      await _supabase.from('goal_contributions').delete().eq('id', contributionId);
    } catch (e) {
      throw Exception('Failed to delete contribution: $e');
    }
  }

  // Summary
  Future<Map<String, dynamic>> getGoalsSummary() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.rpc('get_goals_summary', params: {
        'p_user_id': userId,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch goals summary: $e');
    }
  }
}
