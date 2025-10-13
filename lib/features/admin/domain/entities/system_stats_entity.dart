import 'package:equatable/equatable.dart';

/// System-wide statistics for admin dashboard
class SystemStatsEntity extends Equatable {
  final int totalUsers;
  final int activeUsers; // Users with transactions in last 30 days
  final int newUsersThisMonth;
  final int totalTransactions;
  final double totalIncome;
  final double totalExpense;
  final double totalNetWorth;
  final int totalAccounts;
  final int totalBudgets;
  final int totalBillGroups;

  const SystemStatsEntity({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersThisMonth,
    required this.totalTransactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalNetWorth,
    required this.totalAccounts,
    required this.totalBudgets,
    required this.totalBillGroups,
  });

  @override
  List<Object?> get props => [
        totalUsers,
        activeUsers,
        newUsersThisMonth,
        totalTransactions,
        totalIncome,
        totalExpense,
        totalNetWorth,
        totalAccounts,
        totalBudgets,
        totalBillGroups,
      ];

  double get activeUserPercentage =>
      totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0;

  double get averageTransactionsPerUser =>
      totalUsers > 0 ? totalTransactions / totalUsers : 0;
}
