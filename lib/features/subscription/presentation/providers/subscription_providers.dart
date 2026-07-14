import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/datasources/subscription_remote_datasource_impl.dart';
import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/enums/billing_cycle.dart';
import '../../domain/repositories/subscription_repository.dart';

final subscriptionRemoteDataSourceProvider = Provider<SubscriptionRemoteDataSource>((ref) {
  return SubscriptionRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl(
    remoteDataSource: ref.watch(subscriptionRemoteDataSourceProvider),
  );
});

final subscriptionsStreamProvider = StreamProvider<List<Subscription>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(subscriptionRepositoryProvider).getSubscriptions(user.id);
});

final subscriptionMonthlyCostProvider = Provider<double>((ref) {
  final subsAsync = ref.watch(subscriptionsStreamProvider);
  return subsAsync.maybeWhen(
    data: (subs) {
      double total = 0.0;
      for (final sub in subs) {
        switch (sub.billingCycle) {
          case BillingCycle.weekly:
            total += sub.amount * 4.33;
            break;
          case BillingCycle.monthly:
            total += sub.amount;
            break;
          case BillingCycle.yearly:
            total += sub.amount / 12;
            break;
        }
      }
      return total;
    },
    orElse: () => 0.0,
  );
});

final subscriptionControllerProvider = AsyncNotifierProvider<SubscriptionController, void>(
  SubscriptionController.new,
);

class SubscriptionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveSubscription(Subscription subscription) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(subscriptionRepositoryProvider).saveSubscription(subscription);
      ref.invalidate(dashboardDataProvider);
    });
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(subscriptionRepositoryProvider).deleteSubscription(subscriptionId);
      ref.invalidate(dashboardDataProvider);
    });
  }
}
