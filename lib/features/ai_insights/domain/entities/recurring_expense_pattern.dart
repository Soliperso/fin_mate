import 'package:equatable/equatable.dart';

enum RecurringInterval {
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
  unknown;

  String get displayName {
    switch (this) {
      case RecurringInterval.weekly:
        return 'Weekly';
      case RecurringInterval.biweekly:
        return 'Bi-weekly';
      case RecurringInterval.monthly:
        return 'Monthly';
      case RecurringInterval.quarterly:
        return 'Quarterly';
      case RecurringInterval.yearly:
        return 'Yearly';
      case RecurringInterval.unknown:
        return 'Unknown';
    }
  }
}

/// Represents a detected recurring expense (subscription, bill, etc.)
class RecurringExpensePattern extends Equatable {
  final String id;
  final String merchantName;
  final double averageAmount;
  final double? previousAmount; // For price change detection
  final RecurringInterval interval;
  final DateTime? lastOccurrence;
  final DateTime? nextExpectedDate;
  final int occurrenceCount;
  final double amountVariance; // ±% tolerance
  final String category;
  final bool isPriceIncreased;
  final double? priceChangePercentage;
  final List<DateTime> transactionDates;

  const RecurringExpensePattern({
    required this.id,
    required this.merchantName,
    required this.averageAmount,
    this.previousAmount,
    required this.interval,
    this.lastOccurrence,
    this.nextExpectedDate,
    required this.occurrenceCount,
    this.amountVariance = 5.0,
    required this.category,
    this.isPriceIncreased = false,
    this.priceChangePercentage,
    required this.transactionDates,
  });

  @override
  List<Object?> get props => [
        id,
        merchantName,
        averageAmount,
        previousAmount,
        interval,
        lastOccurrence,
        nextExpectedDate,
        occurrenceCount,
        amountVariance,
        category,
        isPriceIncreased,
        priceChangePercentage,
        transactionDates,
      ];

  RecurringExpensePattern copyWith({
    String? id,
    String? merchantName,
    double? averageAmount,
    double? previousAmount,
    RecurringInterval? interval,
    DateTime? lastOccurrence,
    DateTime? nextExpectedDate,
    int? occurrenceCount,
    double? amountVariance,
    String? category,
    bool? isPriceIncreased,
    double? priceChangePercentage,
    List<DateTime>? transactionDates,
  }) {
    return RecurringExpensePattern(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      averageAmount: averageAmount ?? this.averageAmount,
      previousAmount: previousAmount ?? this.previousAmount,
      interval: interval ?? this.interval,
      lastOccurrence: lastOccurrence ?? this.lastOccurrence,
      nextExpectedDate: nextExpectedDate ?? this.nextExpectedDate,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      amountVariance: amountVariance ?? this.amountVariance,
      category: category ?? this.category,
      isPriceIncreased: isPriceIncreased ?? this.isPriceIncreased,
      priceChangePercentage: priceChangePercentage ?? this.priceChangePercentage,
      transactionDates: transactionDates ?? this.transactionDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant_name': merchantName,
      'average_amount': averageAmount,
      'previous_amount': previousAmount,
      'interval': interval.name,
      'last_occurrence': lastOccurrence?.toIso8601String(),
      'next_expected_date': nextExpectedDate?.toIso8601String(),
      'occurrence_count': occurrenceCount,
      'amount_variance': amountVariance,
      'category': category,
      'is_price_increased': isPriceIncreased,
      'price_change_percentage': priceChangePercentage,
      'transaction_dates': transactionDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory RecurringExpensePattern.fromJson(Map<String, dynamic> json) {
    return RecurringExpensePattern(
      id: json['id'] as String,
      merchantName: json['merchant_name'] as String,
      averageAmount: (json['average_amount'] as num).toDouble(),
      previousAmount: json['previous_amount'] != null ? (json['previous_amount'] as num).toDouble() : null,
      interval: RecurringInterval.values.firstWhere(
        (e) => e.name == json['interval'],
        orElse: () => RecurringInterval.unknown,
      ),
      lastOccurrence: json['last_occurrence'] != null ? DateTime.parse(json['last_occurrence'] as String) : null,
      nextExpectedDate: json['next_expected_date'] != null ? DateTime.parse(json['next_expected_date'] as String) : null,
      occurrenceCount: json['occurrence_count'] as int,
      amountVariance: (json['amount_variance'] as num?)?.toDouble() ?? 5.0,
      category: json['category'] as String,
      isPriceIncreased: json['is_price_increased'] as bool? ?? false,
      priceChangePercentage: json['price_change_percentage'] != null ? (json['price_change_percentage'] as num).toDouble() : null,
      transactionDates: (json['transaction_dates'] as List<dynamic>)
          .map((d) => DateTime.parse(d as String))
          .toList(),
    );
  }
}
