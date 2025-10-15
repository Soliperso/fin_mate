import 'package:equatable/equatable.dart';

enum BalanceStatus {
  healthy, // Balance is comfortably above threshold
  warning, // Balance is approaching threshold
  critical, // Balance is below or near zero
}

class DailyForecast extends Equatable {
  final DateTime date;
  final double projectedBalance;
  final double income;
  final double expenses;
  final BalanceStatus status;
  final List<String> scheduledTransactions; // Transaction descriptions

  const DailyForecast({
    required this.date,
    required this.projectedBalance,
    required this.income,
    required this.expenses,
    required this.status,
    this.scheduledTransactions = const [],
  });

  @override
  List<Object?> get props => [
        date,
        projectedBalance,
        income,
        expenses,
        status,
        scheduledTransactions,
      ];

  DailyForecast copyWith({
    DateTime? date,
    double? projectedBalance,
    double? income,
    double? expenses,
    BalanceStatus? status,
    List<String>? scheduledTransactions,
  }) {
    return DailyForecast(
      date: date ?? this.date,
      projectedBalance: projectedBalance ?? this.projectedBalance,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
      status: status ?? this.status,
      scheduledTransactions: scheduledTransactions ?? this.scheduledTransactions,
    );
  }
}

class BalanceForecast extends Equatable {
  final double currentBalance;
  final double safeToSpend;
  final List<DailyForecast> dailyForecasts;
  final DateTime generatedAt;
  final List<String> warnings; // Low balance warnings

  const BalanceForecast({
    required this.currentBalance,
    required this.safeToSpend,
    required this.dailyForecasts,
    required this.generatedAt,
    this.warnings = const [],
  });

  @override
  List<Object?> get props => [
        currentBalance,
        safeToSpend,
        dailyForecasts,
        generatedAt,
        warnings,
      ];

  BalanceForecast copyWith({
    double? currentBalance,
    double? safeToSpend,
    List<DailyForecast>? dailyForecasts,
    DateTime? generatedAt,
    List<String>? warnings,
  }) {
    return BalanceForecast(
      currentBalance: currentBalance ?? this.currentBalance,
      safeToSpend: safeToSpend ?? this.safeToSpend,
      dailyForecasts: dailyForecasts ?? this.dailyForecasts,
      generatedAt: generatedAt ?? this.generatedAt,
      warnings: warnings ?? this.warnings,
    );
  }
}
