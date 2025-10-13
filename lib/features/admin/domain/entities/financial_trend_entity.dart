import 'package:equatable/equatable.dart';

/// Financial trend data point over time
class FinancialTrendEntity extends Equatable {
  final DateTime periodStart;
  final double totalIncome;
  final double totalExpense;
  final double netCashflow;
  final int transactionCount;
  final double averageTransactionAmount;

  const FinancialTrendEntity({
    required this.periodStart,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashflow,
    required this.transactionCount,
    required this.averageTransactionAmount,
  });

  @override
  List<Object?> get props => [
        periodStart,
        totalIncome,
        totalExpense,
        netCashflow,
        transactionCount,
        averageTransactionAmount,
      ];
}
