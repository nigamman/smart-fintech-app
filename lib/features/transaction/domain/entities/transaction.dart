import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';

class Transaction {

  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    this.note,
    required this.transactionDate,
    required this.createdAt,
  });

}