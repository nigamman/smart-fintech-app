import '../../../../core/enums/transaction_category.dart';

class Budget {
  final String id;
  final String userId;
  final double limitAmount;
  final TransactionCategory? category; // null represents overall monthly budget limit
  final int month;
  final int year;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.limitAmount,
    this.category,
    required this.month,
    required this.year,
    required this.createdAt,
  });
}
