import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../models/subscription_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;

  SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<void> saveSubscription(Subscription subscription) async {
    final model = SubscriptionModel(
      id: subscription.id,
      userId: subscription.userId,
      name: subscription.name,
      amount: subscription.amount,
      billingCycle: subscription.billingCycle,
      nextBillingDate: subscription.nextBillingDate,
      createdAt: subscription.createdAt,
    );
    await _remoteDataSource.saveSubscription(model);
  }

  @override
  Future<void> deleteSubscription(String subscriptionId) async {
    await _remoteDataSource.deleteSubscription(subscriptionId);
  }

  @override
  Stream<List<Subscription>> getSubscriptions(String userId) {
    return _remoteDataSource.getSubscriptions(userId);
  }
}
