import '../../domain/entities/account_entity.dart';

class AccountModel {
  final String id;
  final String userId;
  final String name;
  final String type;
  final double balance;
  final String currency;
  final bool isActive;
  final String? institution;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
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

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      isActive: json['is_active'] ?? true,
      institution: json['institution'],
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'is_active': isActive,
    };

    // Only include user_id if it's not empty (for updates)
    // For inserts, Supabase will automatically set user_id from auth context
    if (userId.isNotEmpty) {
      json['user_id'] = userId;
    }

    // Only include optional fields if they have values and the columns exist in DB
    // Note: institution and last_synced_at columns don't exist in current schema
    // if (institution != null) json['institution'] = institution;
    // if (lastSyncedAt != null) json['last_synced_at'] = lastSyncedAt!.toIso8601String();

    return json;
  }

  AccountEntity toEntity() {
    return AccountEntity(
      id: id,
      userId: userId,
      name: name,
      type: AccountType.fromString(type),
      balance: balance,
      currency: currency,
      isActive: isActive,
      institution: institution,
      lastSyncedAt: lastSyncedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static AccountModel fromEntity(AccountEntity entity) {
    return AccountModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type.toJson(),
      balance: entity.balance,
      currency: entity.currency,
      isActive: entity.isActive,
      institution: entity.institution,
      lastSyncedAt: entity.lastSyncedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
