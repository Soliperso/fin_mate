import 'package:equatable/equatable.dart';

/// Category spending breakdown
class CategoryBreakdownEntity extends Equatable {
  final String categoryId;
  final String categoryName;
  final String categoryType;
  final double totalAmount;
  final int transactionCount;
  final double percentageOfTotal;

  const CategoryBreakdownEntity({
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentageOfTotal,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryType,
        totalAmount,
        transactionCount,
        percentageOfTotal,
      ];
}
