import 'package:equatable/equatable.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// Dashboard statistics entity
class DashboardStats extends Equatable {
  /// Total net worth across all accounts
  final double netWorth;

  /// Net worth change percentage from previous period
  final double netWorthChangePercentage;

  /// Whether the net worth change is positive
  final bool isNetWorthPositive;

  /// Total income for the current month
  final double monthlyIncome;

  /// Total expenses for the current month
  final double monthlyExpenses;

  /// Money health score (0-100)
  final int moneyHealthScore;

  /// Recent transactions (last 5-10)
  final List<TransactionEntity> recentTransactions;

  /// Upcoming bills/recurring transactions
  final List<UpcomingBill> upcomingBills;

  const DashboardStats({
    required this.netWorth,
    required this.netWorthChangePercentage,
    required this.isNetWorthPositive,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.moneyHealthScore,
    required this.recentTransactions,
    required this.upcomingBills,
  });

  /// Empty dashboard stats for initial/loading state
  static const empty = DashboardStats(
    netWorth: 0,
    netWorthChangePercentage: 0,
    isNetWorthPositive: true,
    monthlyIncome: 0,
    monthlyExpenses: 0,
    moneyHealthScore: 0,
    recentTransactions: [],
    upcomingBills: [],
  );

  /// Net balance (income - expenses)
  double get netBalance => monthlyIncome - monthlyExpenses;

  @override
  List<Object?> get props => [
        netWorth,
        netWorthChangePercentage,
        isNetWorthPositive,
        monthlyIncome,
        monthlyExpenses,
        moneyHealthScore,
        recentTransactions,
        upcomingBills,
      ];

  DashboardStats copyWith({
    double? netWorth,
    double? netWorthChangePercentage,
    bool? isNetWorthPositive,
    double? monthlyIncome,
    double? monthlyExpenses,
    int? moneyHealthScore,
    List<TransactionEntity>? recentTransactions,
    List<UpcomingBill>? upcomingBills,
  }) {
    return DashboardStats(
      netWorth: netWorth ?? this.netWorth,
      netWorthChangePercentage: netWorthChangePercentage ?? this.netWorthChangePercentage,
      isNetWorthPositive: isNetWorthPositive ?? this.isNetWorthPositive,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      moneyHealthScore: moneyHealthScore ?? this.moneyHealthScore,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      upcomingBills: upcomingBills ?? this.upcomingBills,
    );
  }
}

/// Upcoming bill entity
class UpcomingBill extends Equatable {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final String? categoryId;
  final String? categoryName;

  const UpcomingBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.categoryId,
    this.categoryName,
  });

  /// Days until the bill is due
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props => [id, name, amount, dueDate, categoryId, categoryName];
}
