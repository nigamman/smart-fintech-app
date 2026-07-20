import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

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
  Future<void> updateProfile(AppUser user) async {
    final model = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      monthlyIncome: user.monthlyIncome,
      monthlySavingsGoal: user.monthlySavingsGoal,
      createdAt: user.createdAt,
    );
    await remoteDataSource.updateProfile(model);
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
  Future<AppUser> loginWithGoogle() async {
    return await remoteDataSource.loginWithGoogle();
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