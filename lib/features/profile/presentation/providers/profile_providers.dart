import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/firestore_collections.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final userProfileStreamProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value(null);
  }

  return ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.users)
      .doc(user.id)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        return UserModel.fromJson(snapshot.data()!);
      });
});

final profileControllerProvider = AsyncNotifierProvider<ProfileController, void>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateProfile({
    required AppUser user,
    required String name,
    required double monthlyIncome,
    required double monthlySavingsGoal,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedUser = AppUser(
        id: user.id,
        name: name,
        email: user.email,
        monthlyIncome: monthlyIncome,
        monthlySavingsGoal: monthlySavingsGoal,
        createdAt: user.createdAt,
      );
      await ref.read(authRepositoryProvider).updateProfile(updatedUser);
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(currentUserProvider);
    });
  }
}
