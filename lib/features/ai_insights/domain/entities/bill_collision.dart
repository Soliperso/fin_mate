import 'package:equatable/equatable.dart';

/// Represents multiple bills due on or near the same date
class BillCollision extends Equatable {
  final String id;
  final DateTime dueDate;
  final List<BillItem> bills; // Bills due on this date
  final double totalAmount; // Combined amount due
  final String recommendation; // Suggestion to reschedule
  final List<DateTime>? alternativeDates; // Suggested dates to stagger bills

  const BillCollision({
    required this.id,
    required this.dueDate,
    required this.bills,
    required this.totalAmount,
    required this.recommendation,
    this.alternativeDates,
  });

  bool get isMultipleBills => bills.length > 1;
  bool get isImminent {
    final now = DateTime.now();
    return dueDate.difference(now).inDays <= 7;
  }

  @override
  List<Object?> get props => [
        id,
        dueDate,
        bills,
        totalAmount,
        recommendation,
        alternativeDates,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'due_date': dueDate.toIso8601String(),
      'bills': bills.map((b) => b.toJson()).toList(),
      'total_amount': totalAmount,
      'recommendation': recommendation,
      'alternative_dates': alternativeDates?.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory BillCollision.fromJson(Map<String, dynamic> json) {
    return BillCollision(
      id: json['id'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      bills: (json['bills'] as List)
          .map((b) => BillItem.fromJson(b as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      recommendation: json['recommendation'] as String,
      alternativeDates: json['alternative_dates'] != null
          ? (json['alternative_dates'] as List).map((d) => DateTime.parse(d as String)).toList()
          : null,
    );
  }
}

/// Individual bill in a collision
class BillItem extends Equatable {
  final String name; // e.g., "Netflix", "Rent"
  final double amount;
  final String category; // Category name
  final DateTime dueDate;

  const BillItem({
    required this.name,
    required this.amount,
    required this.category,
    required this.dueDate,
  });

  @override
  List<Object?> get props => [name, amount, category, dueDate];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'due_date': dueDate.toIso8601String(),
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
    );
  }
}
