import 'package:equatable/equatable.dart';

/// Represents insights about a specific merchant or vendor
class MerchantInsight extends Equatable {
  final String id;
  final String merchantName;
  final String category;
  final int visitCount;
  final double totalSpent;
  final double averagePerVisit;
  final DateTime firstTransaction;
  final DateTime lastTransaction;
  final double monthlyFrequency; // Average visits per month
  final List<DateTime> transactionDates;
  final double percentageOfCategorySpending;
  final bool isTopMerchant; // Top 5 by spend or frequency

  const MerchantInsight({
    required this.id,
    required this.merchantName,
    required this.category,
    required this.visitCount,
    required this.totalSpent,
    required this.averagePerVisit,
    required this.firstTransaction,
    required this.lastTransaction,
    required this.monthlyFrequency,
    required this.transactionDates,
    required this.percentageOfCategorySpending,
    this.isTopMerchant = false,
  });

  @override
  List<Object?> get props => [
        id,
        merchantName,
        category,
        visitCount,
        totalSpent,
        averagePerVisit,
        firstTransaction,
        lastTransaction,
        monthlyFrequency,
        transactionDates,
        percentageOfCategorySpending,
        isTopMerchant,
      ];

  MerchantInsight copyWith({
    String? id,
    String? merchantName,
    String? category,
    int? visitCount,
    double? totalSpent,
    double? averagePerVisit,
    DateTime? firstTransaction,
    DateTime? lastTransaction,
    double? monthlyFrequency,
    List<DateTime>? transactionDates,
    double? percentageOfCategorySpending,
    bool? isTopMerchant,
  }) {
    return MerchantInsight(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      visitCount: visitCount ?? this.visitCount,
      totalSpent: totalSpent ?? this.totalSpent,
      averagePerVisit: averagePerVisit ?? this.averagePerVisit,
      firstTransaction: firstTransaction ?? this.firstTransaction,
      lastTransaction: lastTransaction ?? this.lastTransaction,
      monthlyFrequency: monthlyFrequency ?? this.monthlyFrequency,
      transactionDates: transactionDates ?? this.transactionDates,
      percentageOfCategorySpending: percentageOfCategorySpending ?? this.percentageOfCategorySpending,
      isTopMerchant: isTopMerchant ?? this.isTopMerchant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant_name': merchantName,
      'category': category,
      'visit_count': visitCount,
      'total_spent': totalSpent,
      'average_per_visit': averagePerVisit,
      'first_transaction': firstTransaction.toIso8601String(),
      'last_transaction': lastTransaction.toIso8601String(),
      'monthly_frequency': monthlyFrequency,
      'transaction_dates': transactionDates.map((d) => d.toIso8601String()).toList(),
      'percentage_of_category_spending': percentageOfCategorySpending,
      'is_top_merchant': isTopMerchant,
    };
  }

  factory MerchantInsight.fromJson(Map<String, dynamic> json) {
    return MerchantInsight(
      id: json['id'] as String,
      merchantName: json['merchant_name'] as String,
      category: json['category'] as String,
      visitCount: json['visit_count'] as int,
      totalSpent: (json['total_spent'] as num).toDouble(),
      averagePerVisit: (json['average_per_visit'] as num).toDouble(),
      firstTransaction: DateTime.parse(json['first_transaction'] as String),
      lastTransaction: DateTime.parse(json['last_transaction'] as String),
      monthlyFrequency: (json['monthly_frequency'] as num).toDouble(),
      transactionDates: (json['transaction_dates'] as List<dynamic>)
          .map((d) => DateTime.parse(d as String))
          .toList(),
      percentageOfCategorySpending: (json['percentage_of_category_spending'] as num).toDouble(),
      isTopMerchant: json['is_top_merchant'] as bool? ?? false,
    );
  }
}
