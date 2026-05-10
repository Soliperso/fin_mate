import 'dart:math';
import 'package:equatable/equatable.dart';

class DebtEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String debtType;
  final double balance;
  final double interestRate;
  final double minimumPayment;
  final int? dueDay;
  final bool isActive;
  final String? notes;
  final double? originalBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebtEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.debtType,
    required this.balance,
    required this.interestRate,
    required this.minimumPayment,
    this.dueDay,
    this.isActive = true,
    this.notes,
    this.originalBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  double get monthlyInterest => balance * (interestRate / 100 / 12);

  /// Returns estimated months to payoff at minimum payment, or null if not computable.
  int? get monthsToPayoffAtMinimum {
    if (balance <= 0 || minimumPayment <= 0) return null;
    final rate = interestRate / 100 / 12;
    if (rate <= 0) {
      // No interest: simple division
      return (balance / minimumPayment).ceil();
    }
    if (minimumPayment <= monthlyInterest) return null; // Never pays off
    final months =
        (-log(1 - rate * balance / minimumPayment) / log(1 + rate)).ceil();
    return months > 0 ? months : null;
  }

  String get debtTypeDisplay {
    switch (debtType) {
      case 'credit_card':
        return 'Credit Card';
      case 'student_loan':
        return 'Student Loan';
      case 'auto_loan':
        return 'Auto Loan';
      case 'mortgage':
        return 'Mortgage';
      case 'medical':
        return 'Medical';
      case 'personal_loan':
        return 'Personal Loan';
      default:
        return debtType
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  DebtEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? debtType,
    double? balance,
    double? interestRate,
    double? minimumPayment,
    int? dueDay,
    bool? isActive,
    String? notes,
    double? originalBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      debtType: debtType ?? this.debtType,
      balance: balance ?? this.balance,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      originalBalance: originalBalance ?? this.originalBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        debtType,
        balance,
        interestRate,
        minimumPayment,
        dueDay,
        isActive,
        notes,
        originalBalance,
        createdAt,
        updatedAt,
      ];
}
