import '../../domain/entities/financial_trend_entity.dart';

class FinancialTrendModel extends FinancialTrendEntity {
  const FinancialTrendModel({
    required super.periodStart,
    required super.totalIncome,
    required super.totalExpense,
    required super.netCashflow,
    required super.transactionCount,
    required super.averageTransactionAmount,
  });

  factory FinancialTrendModel.fromJson(Map<String, dynamic> json) {
    return FinancialTrendModel(
      periodStart: DateTime.parse(json['period_start']),
      totalIncome: (json['total_income'] ?? 0).toDouble(),
      totalExpense: (json['total_expense'] ?? 0).toDouble(),
      netCashflow: (json['net_cashflow'] ?? 0).toDouble(),
      transactionCount: json['transaction_count'] ?? 0,
      averageTransactionAmount: (json['average_transaction_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_start': periodStart.toIso8601String(),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'net_cashflow': netCashflow,
      'transaction_count': transactionCount,
      'average_transaction_amount': averageTransactionAmount,
    };
  }
}
