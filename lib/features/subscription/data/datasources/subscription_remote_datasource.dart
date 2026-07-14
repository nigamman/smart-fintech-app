import '../models/subscription_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<void> saveSubscription(SubscriptionModel subscription);
  Future<void> deleteSubscription(String subscriptionId);
  Stream<List<SubscriptionModel>> getSubscriptions(String userId);
}
