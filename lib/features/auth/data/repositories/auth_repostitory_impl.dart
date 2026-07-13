import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<AppUser?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return remoteDataSource.authStateChanges();
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required double monthlyIncome,
    required double monthlySavingsGoal,
  }) async {
    return await remoteDataSource.signUp(
      name: name,
      email: email,
      password: password,
      monthlyIncome: monthlyIncome,
      monthlySavingsGoal: monthlySavingsGoal,
    );
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    return await remoteDataSource.login(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) async {
    await remoteDataSource.forgotPassword(
      email: email,
    );
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }
}