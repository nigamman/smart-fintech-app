import '../../domain/entities/subscription.dart';
import '../../domain/enums/billing_cycle.dart';

class SubscriptionModel extends Subscription {
  const SubscriptionModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.amount,
    required super.billingCycle,
    required super.nextBillingDate,
    required super.createdAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == (json['billingCycle'] as String),
        orElse: () => BillingCycle.monthly,
      ),
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle.name,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    BillingCycle? billingCycle,
    DateTime? nextBillingDate,
    DateTime? createdAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
