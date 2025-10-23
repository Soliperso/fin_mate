import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_client.dart';
import '../models/bill_group_model.dart';
import '../models/group_member_model.dart';
import '../models/group_expense_model.dart';
import '../models/expense_split_model.dart';
import '../models/settlement_model.dart';
import '../models/group_balance_model.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/group_expense_entity.dart';

class BillSplittingRemoteDatasource {
  final SupabaseClient _supabase;

  BillSplittingRemoteDatasource({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? supabase;

  // Groups
  Future<List<BillGroupModel>> getUserGroups() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get groups where user is a member
      final memberResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final groupIds = (memberResponse as List).map((m) => m['group_id'] as String).toList();

      if (groupIds.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('bill_groups')
          .select()
          .inFilter('id', groupIds)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => BillGroupModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch groups: $e');
    }
  }

  Future<BillGroupModel> getGroupById(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Verify user is a member of this group
      final memberCheck = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (memberCheck == null) {
        throw Exception('Access denied: You are not a member of this group');
      }

      final response = await _supabase
          .from('bill_groups')
          .select()
          .eq('id', groupId)
          .single();

      return BillGroupModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch group: $e');
    }
  }

  Future<BillGroupModel> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) throw Exception('User not authenticated');


      final response = await _supabase
          .from('bill_groups')
          .insert({
            'name': name,
            'description': description,
            'created_by': userId,
          })
          .select()
          .single();

      return BillGroupModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Verify user is a member of this group (admin check can be added later)
      final memberCheck = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (memberCheck == null) {
        throw Exception('Access denied: You are not a member of this group');
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;

      await _supabase
          .from('bill_groups')
          .update(updateData)
          .eq('id', groupId);
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Verify user is the creator of this group
      final group = await _supabase
          .from('bill_groups')
          .select('created_by')
          .eq('id', groupId)
          .maybeSingle();

      if (group == null || group['created_by'] != userId) {
        throw Exception('Access denied: Only the group creator can delete this group');
      }

      await _supabase.from('bill_groups').delete().eq('id', groupId);
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // Members
  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('''
            *,
            user_profiles!inner(full_name, email, avatar_url)
          ''')
          .eq('group_id', groupId)
          .order('joined_at', ascending: true);

      return (response as List).map((json) {
        return GroupMemberModel.fromJson({
          ...json,
          'full_name': json['user_profiles']['full_name'],
          'email': json['user_profiles']['email'],
          'avatar_url': json['user_profiles']['avatar_url'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch group members: $e');
    }
  }

  Future<void> addGroupMember({
    required String groupId,
    required String userEmail,
    MemberRole role = MemberRole.member,
  }) async {
    try {
      // Get user ID from email
      final userResponse = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('email', userEmail.toLowerCase().trim())
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('User not found: No user exists with email $userEmail');
      }

      final userId = userResponse['id'] as String;

      // Check if user is already a member
      final existingMember = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('Already a member: This user is already in the group');
      }

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': role.value,
      });
    } catch (e) {
      // Re-throw with original message if it's already a custom exception
      if (e.toString().contains('User not found') ||
          e.toString().contains('Already a member')) {
        rethrow;
      }
      throw Exception('Failed to add group member: $e');
    }
  }

  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove group member: $e');
    }
  }

  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole role,
  }) async {
    try {
      await _supabase
          .from('group_members')
          .update({'role': role.value})
          .eq('group_id', groupId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  // Expenses
  Future<List<GroupExpenseModel>> getGroupExpenses(String groupId) async {
    try {
      final response = await _supabase
          .from('group_expenses')
          .select('''
            *,
            user_profiles!inner(full_name)
          ''')
          .eq('group_id', groupId)
          .order('date', ascending: false);

      return (response as List).map((json) {
        return GroupExpenseModel.fromJson({
          ...json,
          'paid_by_name': json['user_profiles']['full_name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch group expenses: $e');
    }
  }

  Future<GroupExpenseModel> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required DateTime date,
    String? category,
    String? notes,
    SplitType splitType = SplitType.equal,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('group_expenses')
          .insert({
            'group_id': groupId,
            'description': description,
            'amount': amount,
            'paid_by': userId,
            'date': date.toIso8601String().split('T')[0],
            'category': category,
            'notes': notes,
            'split_type': splitType.value,
          })
          .select('''
            *,
            user_profiles!inner(full_name)
          ''')
          .single();

      return GroupExpenseModel.fromJson({
        ...response,
        'paid_by_name': response['user_profiles']['full_name'],
      });
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (description != null) updateData['description'] = description;
      if (amount != null) updateData['amount'] = amount;
      if (date != null) updateData['date'] = date.toIso8601String().split('T')[0];
      if (category != null) updateData['category'] = category;
      if (notes != null) updateData['notes'] = notes;

      await _supabase
          .from('group_expenses')
          .update(updateData)
          .eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _supabase.from('group_expenses').delete().eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Expense Splits
  Future<List<ExpenseSplitModel>> getExpenseSplits(String expenseId) async {
    try {
      final response = await _supabase
          .from('expense_splits')
          .select('''
            *,
            user_profiles!inner(full_name)
          ''')
          .eq('expense_id', expenseId);

      return (response as List).map((json) {
        return ExpenseSplitModel.fromJson({
          ...json,
          'user_name': json['user_profiles']['full_name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch expense splits: $e');
    }
  }

  Future<void> createCustomSplits({
    required String expenseId,
    required Map<String, double> splits,
  }) async {
    try {
      // Delete existing splits
      await _supabase.from('expense_splits').delete().eq('expense_id', expenseId);

      // Create new splits
      final splitData = splits.entries.map((entry) => {
        'expense_id': expenseId,
        'user_id': entry.key,
        'amount': entry.value,
      }).toList();

      await _supabase.from('expense_splits').insert(splitData);
    } catch (e) {
      throw Exception('Failed to create custom splits: $e');
    }
  }

  // Settlements
  Future<List<SettlementModel>> getGroupSettlements(String groupId) async {
    try {
      final response = await _supabase
          .from('settlements')
          .select('''
            *,
            from_user_profile:user_profiles!settlements_from_user_fkey(full_name),
            to_user_profile:user_profiles!settlements_to_user_fkey(full_name)
          ''')
          .eq('group_id', groupId)
          .order('settled_at', ascending: false);

      return (response as List).map((json) {
        return SettlementModel.fromJson({
          ...json,
          'from_user_name': json['from_user_profile']['full_name'],
          'to_user_name': json['to_user_profile']['full_name'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch settlements: $e');
    }
  }

  Future<SettlementModel> createSettlement({
    required String groupId,
    required String toUserId,
    required double amount,
    String? notes,
    String? evidenceUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('settlements')
          .insert({
            'group_id': groupId,
            'from_user': userId,
            'to_user': toUserId,
            'amount': amount,
            'notes': notes,
            'evidence_url': evidenceUrl,
          })
          .select('''
            *,
            from_user_profile:user_profiles!settlements_from_user_fkey(full_name),
            to_user_profile:user_profiles!settlements_to_user_fkey(full_name)
          ''')
          .single();

      return SettlementModel.fromJson({
        ...response,
        'from_user_name': response['from_user_profile']['full_name'],
        'to_user_name': response['to_user_profile']['full_name'],
      });
    } catch (e) {
      throw Exception('Failed to create settlement: $e');
    }
  }

  // Balances
  Future<List<GroupBalanceModel>> getGroupBalances(String groupId) async {
    try {
      final response = await _supabase.rpc('get_group_balances', params: {
        'p_group_id': groupId,
      });

      return (response as List)
          .map((json) => GroupBalanceModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch group balances: $e');
    }
  }
}
