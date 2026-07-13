import '../entities/app_user.dart';

abstract class AuthRepository {
  /// Returns the currently logged-in user.
  Future<AppUser?> getCurrentUser();

  /// Listen to authentication state changes.
  Stream<AppUser?> authStateChanges();

  /// Create a new account.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required double monthlyIncome,
    required double monthlySavingsGoal,
  });

  /// Login with email and password.
  Future<AppUser> login({
    required String email,
    required String password,
  });

  /// Send password reset email.
  Future<void> forgotPassword({
    required String email,
  });

  /// Logout current user.
  Future<void> logout();
}