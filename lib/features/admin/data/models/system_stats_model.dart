import '../../domain/entities/system_stats_entity.dart';

/// Data model for system statistics
class SystemStatsModel extends SystemStatsEntity {
  const SystemStatsModel({
    required super.totalUsers,
    required super.activeUsers,
    required super.newUsersThisMonth,
    required super.totalTransactions,
    required super.totalIncome,
    required super.totalExpense,
    required super.totalNetWorth,
    required super.totalAccounts,
    required super.totalBudgets,
    required super.totalBillGroups,
  });

  factory SystemStatsModel.fromJson(Map<String, dynamic> json) {
    return SystemStatsModel(
      totalUsers: (json['total_users'] as int?) ?? 0,
      activeUsers: (json['active_users'] as int?) ?? 0,
      newUsersThisMonth: (json['new_users_this_month'] as int?) ?? 0,
      totalTransactions: (json['total_transactions'] as int?) ?? 0,
      totalIncome: ((json['total_income'] as num?) ?? 0).toDouble(),
      totalExpense: ((json['total_expense'] as num?) ?? 0).toDouble(),
      totalNetWorth: ((json['total_net_worth'] as num?) ?? 0).toDouble(),
      totalAccounts: (json['total_accounts'] as int?) ?? 0,
      totalBudgets: (json['total_budgets'] as int?) ?? 0,
      totalBillGroups: (json['total_bill_groups'] as int?) ?? 0,
    );
  }
}
