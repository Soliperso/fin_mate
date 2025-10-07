import 'package:equatable/equatable.dart';

/// Account type enum
enum AccountType {
  cash,
  checking,
  savings,
  creditCard,
  investment,
  other;

  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.checking:
        return 'Checking';
      case AccountType.savings:
        return 'Savings';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.investment:
        return 'Investment';
      case AccountType.other:
        return 'Other';
    }
  }

  static AccountType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return AccountType.cash;
      case 'checking':
        return AccountType.checking;
      case 'savings':
        return AccountType.savings;
      case 'credit_card':
        return AccountType.creditCard;
      case 'investment':
        return AccountType.investment;
      default:
        return AccountType.other;
    }
  }

  String toJson() {
    switch (this) {
      case AccountType.creditCard:
        return 'credit_card';
      default:
        return name;
    }
  }
}

/// Account entity for financial accounts
class AccountEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String currency;
  final bool isActive;
  final String? institution;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'USD',
    this.isActive = true,
    this.institution,
    this.lastSyncedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        balance,
        currency,
        isActive,
        institution,
        lastSyncedAt,
        createdAt,
        updatedAt,
      ];

  AccountEntity copyWith({
    String? id,
    String? userId,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    bool? isActive,
    String? institution,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      institution: institution ?? this.institution,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
