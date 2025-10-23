import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/bill_splitting_remote_datasource.dart';
import '../../data/repositories/bill_splitting_repository_impl.dart';
import '../../domain/repositories/bill_splitting_repository.dart';
import '../../domain/entities/bill_group_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/entities/group_balance_entity.dart';
import '../../domain/entities/expense_split_entity.dart';

// Repository Provider
final billSplittingRepositoryProvider = Provider<BillSplittingRepository>((ref) {
  return BillSplittingRepositoryImpl(
    remoteDatasource: BillSplittingRemoteDatasource(),
  );
});

// Groups Provider
final userGroupsProvider = FutureProvider<List<BillGroup>>((ref) async {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return await repository.getUserGroups();
});

// Single Group Provider
final groupProvider = FutureProvider.family<BillGroup, String>((ref, groupId) async {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return await repository.getGroupById(groupId);
});

// Group Members Provider
final groupMembersProvider = FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return await repository.getGroupMembers(groupId);
});

// Group Expenses Provider
final groupExpensesProvider = FutureProvider.family<List<GroupExpense>, String>((ref, groupId) async {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return await repository.getGroupExpenses(groupId);
});

// Group Balances Provider
final groupBalancesProvider = FutureProvider.family<List<GroupBalance>, String>((ref, groupId) async {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return await repository.getGroupBalances(groupId);
});

// Group Settlements Provider
final groupSettlementsProvider = FutureProvider.family<List<Settlement>, String>((ref, groupId) async {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return await repository.getGroupSettlements(groupId);
});

// Expense Splits Provider
final expenseSplitsProvider = FutureProvider.family<List<ExpenseSplit>, String>((ref, expenseId) async {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return await repository.getExpenseSplits(expenseId);
});

// State Notifier for Group Operations
class GroupOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final BillSplittingRepository _repository;

  GroupOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<BillGroup?> createGroup({
    required String name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final group = await _repository.createGroup(
        name: name,
        description: description,
      );
      state = const AsyncValue.data(null);
      return group;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<bool> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteGroup(groupId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> addMember({
    required String groupId,
    required String userEmail,
    MemberRole role = MemberRole.member,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addGroupMember(
        groupId: groupId,
        userEmail: userEmail,
        role: role,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> removeMember({
    required String groupId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeGroupMember(
        groupId: groupId,
        userId: userId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}

final groupOperationsProvider = StateNotifierProvider<GroupOperationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return GroupOperationsNotifier(repository);
});

// State Notifier for Expense Operations
class ExpenseOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final BillSplittingRepository _repository;

  ExpenseOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<GroupExpense?> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required DateTime date,
    String? category,
    String? notes,
    SplitType splitType = SplitType.equal,
    Map<String, double>? customSplits,
  }) async {
    state = const AsyncValue.loading();
    try {
      final expense = await _repository.createExpense(
        groupId: groupId,
        description: description,
        amount: amount,
        date: date,
        category: category,
        notes: notes,
        splitType: splitType,
        customSplits: customSplits,
      );
      state = const AsyncValue.data(null);
      return expense;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<bool> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateExpense(
        expenseId: expenseId,
        description: description,
        amount: amount,
        date: date,
        category: category,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteExpense(expenseId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> createCustomSplits({
    required String expenseId,
    required Map<String, double> splits,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createCustomSplits(
        expenseId: expenseId,
        splits: splits,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}

final expenseOperationsProvider = StateNotifierProvider<ExpenseOperationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return ExpenseOperationsNotifier(repository);
});

// State Notifier for Settlement Operations
class SettlementOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final BillSplittingRepository _repository;

  SettlementOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<Settlement?> createSettlement({
    required String groupId,
    required String toUserId,
    required double amount,
    String? notes,
    String? evidenceUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final settlement = await _repository.createSettlement(
        groupId: groupId,
        toUserId: toUserId,
        amount: amount,
        notes: notes,
        evidenceUrl: evidenceUrl,
      );
      state = const AsyncValue.data(null);
      return settlement;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }
}

final settlementOperationsProvider = StateNotifierProvider<SettlementOperationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return SettlementOperationsNotifier(repository);
});

// State Notifier for Member Operations
class MemberOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final BillSplittingRepository _repository;

  MemberOperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> addMember({
    required String groupId,
    required String userEmail,
    MemberRole role = MemberRole.member,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addGroupMember(
        groupId: groupId,
        userEmail: userEmail,
        role: role,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow; // Re-throw to allow caller to handle specific error messages
    }
  }

  Future<bool> removeMember({
    required String groupId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeGroupMember(
        groupId: groupId,
        userId: userId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateMemberRole(
        groupId: groupId,
        userId: userId,
        role: role,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }
}

final memberOperationsProvider = StateNotifierProvider<MemberOperationsNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(billSplittingRepositoryProvider);
  return MemberOperationsNotifier(repository);
});
