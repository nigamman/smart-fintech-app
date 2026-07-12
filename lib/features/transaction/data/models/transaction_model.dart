import '../../domain/entities/transaction.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.type,
    required super.category,
    super.note,
    required super.transactionDate,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
            (e) => e.name == json['type'],
      ),
      category: TransactionCategory.values.firstWhere(
            (e) => e.name == json['category'],
      ),
      note: json['note'] as String?,
      transactionDate: DateTime.parse(json['transactionDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'note': note,
      'transactionDate': transactionDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    String? note,
    DateTime? transactionDate,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}