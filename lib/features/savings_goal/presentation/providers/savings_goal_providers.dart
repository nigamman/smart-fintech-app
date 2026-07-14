import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/datasources/savings_goal_remote_datasource.dart';
import '../../data/datasources/savings_goal_remote_datasource_impl.dart';
import '../../data/repositories/savings_goal_repository_impl.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';

final savingsGoalRemoteDataSourceProvider = Provider<SavingsGoalRemoteDataSource>((ref) {
  return SavingsGoalRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepositoryImpl(
    remoteDataSource: ref.watch(savingsGoalRemoteDataSourceProvider),
  );
});

final savingsGoalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(savingsGoalRepositoryProvider).getGoals(user.id);
});

final savingsGoalControllerProvider = AsyncNotifierProvider<SavingsGoalController, void>(
  SavingsGoalController.new,
);

class SavingsGoalController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveGoal(SavingsGoal goal) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(savingsGoalRepositoryProvider).saveGoal(goal);
      ref.invalidate(dashboardDataProvider);
    });
  }

  Future<void> deleteGoal(String goalId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(savingsGoalRepositoryProvider).deleteGoal(goalId);
      ref.invalidate(dashboardDataProvider);
    });
  }
}
