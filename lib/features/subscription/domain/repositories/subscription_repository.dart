import '../../domain/entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<void> saveSubscription(Subscription subscription);
  Future<void> deleteSubscription(String subscriptionId);
  Stream<List<Subscription>> getSubscriptions(String userId);
}
