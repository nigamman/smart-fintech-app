import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import 'auth_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

final authControllerProvider =
AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).login(
        email: email,
        password: password,
      );
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).loginWithGoogle();
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required double monthlyIncome,
    required double monthlySavingsGoal,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).signUp(
        name: name,
        email: email,
        password: password,
        monthlyIncome: monthlyIncome,
        monthlySavingsGoal: monthlySavingsGoal,
      );
    });
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    await ref.read(authRepositoryProvider).forgotPassword(
      email: email,
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(preferencesProvider.notifier).lockSession();

    state = const AsyncData(null);
  }
}