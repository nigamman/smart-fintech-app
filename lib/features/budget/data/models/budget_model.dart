import '../../../../core/enums/transaction_category.dart';
import '../../domain/entities/budget.dart';

class BudgetModel extends Budget {
  const BudgetModel({
    required super.id,
    required super.userId,
    required super.limitAmount,
    super.category,
    required super.month,
    required super.year,
    required super.createdAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      category: json['category'] != null
          ? TransactionCategory.values.firstWhere(
              (e) => e.name == json['category'],
            )
          : null,
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'limitAmount': limitAmount,
      'category': category?.name,
      'month': month,
      'year': year,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    double? limitAmount,
    TransactionCategory? category,
    int? month,
    int? year,
    DateTime? createdAt,
    bool clearCategory = false,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      limitAmount: limitAmount ?? this.limitAmount,
      category: clearCategory ? null : (category ?? this.category),
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
