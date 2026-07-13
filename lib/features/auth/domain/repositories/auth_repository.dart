abstract class AuthRepository {

  Stream<AppUser?> authStateChanges();

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> login({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> forgotPassword(
      String email);
}