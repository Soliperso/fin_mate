import '../../domain/entities/net_worth_percentile_entity.dart';

class NetWorthPercentileModel extends NetWorthPercentileEntity {
  const NetWorthPercentileModel({
    required super.percentile,
    required super.netWorthValue,
    required super.userCount,
  });

  factory NetWorthPercentileModel.fromJson(Map<String, dynamic> json) {
    return NetWorthPercentileModel(
      percentile: json['percentile'] ?? '',
      netWorthValue: (json['net_worth_value'] ?? 0).toDouble(),
      userCount: json['user_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'percentile': percentile,
      'net_worth_value': netWorthValue,
      'user_count': userCount,
    };
  }
}
