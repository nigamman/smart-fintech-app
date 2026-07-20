import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> authStateChanges();

  Future<void> updateProfile(UserModel user);

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required double monthlyIncome,
    required double monthlySavingsGoal,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> loginWithGoogle();

  Future<void> forgotPassword({
    required String email,
  });

  Future<void> logout();
}