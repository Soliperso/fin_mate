import '../entities/bill_group_entity.dart';
import '../entities/group_member_entity.dart';
import '../entities/group_expense_entity.dart';
import '../entities/expense_split_entity.dart';
import '../entities/settlement_entity.dart';
import '../entities/group_balance_entity.dart';

abstract class BillSplittingRepository {
  // Groups
  Future<List<BillGroup>> getUserGroups();
  Future<BillGroup> getGroupById(String groupId);
  Future<BillGroup> createGroup({
    required String name,
    String? description,
  });
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  });
  Future<void> deleteGroup(String groupId);

  // Members
  Future<List<GroupMember>> getGroupMembers(String groupId);
  Future<void> addGroupMember({
    required String groupId,
    required String userEmail,
    MemberRole role = MemberRole.member,
  });
  Future<void> removeGroupMember({
    required String groupId,
    required String userId,
  });
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole role,
  });

  // Expenses
  Future<List<GroupExpense>> getGroupExpenses(String groupId);
  Future<GroupExpense> createExpense({
    required String groupId,
    required String description,
    required double amount,
    required DateTime date,
    String? category,
    String? notes,
    SplitType splitType = SplitType.equal,
    Map<String, double>? customSplits,
  });
  Future<void> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
  });
  Future<void> deleteExpense(String expenseId);

  // Expense Splits
  Future<List<ExpenseSplit>> getExpenseSplits(String expenseId);
  Future<void> createCustomSplits({
    required String expenseId,
    required Map<String, double> splits,
  });

  // Settlements
  Future<List<Settlement>> getGroupSettlements(String groupId);
  Future<Settlement> createSettlement({
    required String groupId,
    required String toUserId,
    required double amount,
    String? notes,
    String? evidenceUrl,
  });

  // Balances
  Future<List<GroupBalance>> getGroupBalances(String groupId);
}
