import '../../domain/entities/bill_group_entity.dart';
import '../../domain/entities/group_member_entity.dart';
import '../../domain/entities/group_expense_entity.dart';
import '../../domain/entities/expense_split_entity.dart';
import '../../domain/entities/settlement_entity.dart';
import '../../domain/entities/group_balance_entity.dart';
import '../../domain/repositories/bill_splitting_repository.dart';
import '../datasources/bill_splitting_remote_datasource.dart';

class BillSplittingRepositoryImpl implements BillSplittingRepository {
  final BillSplittingRemoteDatasource _remoteDatasource;

  BillSplittingRepositoryImpl({
    required BillSplittingRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<List<BillGroup>> getUserGroups() async {
    return await _remoteDatasource.getUserGroups();
  }

  @override
  Future<BillGroup> getGroupById(String groupId) async {
    return await _remoteDatasource.getGroupById(groupId);
  }

  @override
  Future<BillGroup> createGroup({
    required String name,
    String? description,
  }) async {
    return await _remoteDatasource.createGroup(
      name: name,
      description: description,
    );
  }

  @override
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    await _remoteDatasource.updateGroup(
      groupId: groupId,
      name: name,
      description: description,
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _remoteDatasource.deleteGroup(groupId);
  }

  @override
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    return await _remoteDatasource.getGroupMembers(groupId);
  }

  @override
  Future<void> addGroupMember({
    required String groupId,
    required String userEmail,
    MemberRole role = MemberRole.member,
  }) async {
    await _remoteDatasource.addGroupMember(
      groupId: groupId,
      userEmail: userEmail,
      role: role,
    );
  }

  @override
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    await _remoteDatasource.removeGroupMember(
      groupId: groupId,
      userId: userId,
    );
  }

  @override
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole role,
  }) async {
    await _remoteDatasource.updateMemberRole(
      groupId: groupId,
      userId: userId,
      role: role,
    );
  }

  @override
  Future<List<GroupExpense>> getGroupExpenses(String groupId) async {
    return await _remoteDatasource.getGroupExpenses(groupId);
  }

  @override
  Future<GroupExpense> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required DateTime date,
    String? category,
    String? notes,
    SplitType splitType = SplitType.equal,
    Map<String, double>? customSplits,
  }) async {
    final expense = await _remoteDatasource.createExpense(
      groupId: groupId,
      description: description,
      amount: amount,
      date: date,
      category: category,
      notes: notes,
      splitType: splitType,
    );

    // If custom splits provided, create them
    if (customSplits != null && customSplits.isNotEmpty) {
      await _remoteDatasource.createCustomSplits(
        expenseId: expense.id,
        splits: customSplits,
      );
    }

    return expense;
  }

  @override
  Future<void> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
  }) async {
    await _remoteDatasource.updateExpense(
      expenseId: expenseId,
      description: description,
      amount: amount,
      date: date,
      category: category,
      notes: notes,
    );
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _remoteDatasource.deleteExpense(expenseId);
  }

  @override
  Future<List<ExpenseSplit>> getExpenseSplits(String expenseId) async {
    return await _remoteDatasource.getExpenseSplits(expenseId);
  }

  @override
  Future<void> createCustomSplits({
    required String expenseId,
    required Map<String, double> splits,
  }) async {
    await _remoteDatasource.createCustomSplits(
      expenseId: expenseId,
      splits: splits,
    );
  }

  @override
  Future<List<Settlement>> getGroupSettlements(String groupId) async {
    return await _remoteDatasource.getGroupSettlements(groupId);
  }

  @override
  Future<Settlement> createSettlement({
    required String groupId,
    required String toUserId,
    required double amount,
    String? notes,
    String? evidenceUrl,
  }) async {
    return await _remoteDatasource.createSettlement(
      groupId: groupId,
      toUserId: toUserId,
      amount: amount,
      notes: notes,
      evidenceUrl: evidenceUrl,
    );
  }

  @override
  Future<List<GroupBalance>> getGroupBalances(String groupId) async {
    return await _remoteDatasource.getGroupBalances(groupId);
  }
}
