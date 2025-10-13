import 'package:equatable/equatable.dart';

/// Net worth percentile data
class NetWorthPercentileEntity extends Equatable {
  final String percentile;
  final double netWorthValue;
  final int userCount;

  const NetWorthPercentileEntity({
    required this.percentile,
    required this.netWorthValue,
    required this.userCount,
  });

  @override
  List<Object?> get props => [percentile, netWorthValue, userCount];
}
