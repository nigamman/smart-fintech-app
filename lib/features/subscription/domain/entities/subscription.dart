import '../enums/billing_cycle.dart';

class Subscription {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final BillingCycle billingCycle;
  final DateTime nextBillingDate;
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.createdAt,
  });
}
